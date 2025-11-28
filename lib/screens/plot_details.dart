import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/symptom_diagnosis.dart';

class PlotDetailsPage extends StatefulWidget {
  final String title;
  final String variety;
  final String age;
  final bool healthy;
  final String? plotId; // optional Firestore doc id for this plot

  const PlotDetailsPage({
    super.key,
    required this.title,
    required this.variety,
    required this.age,
    required this.healthy,
    this.plotId,
  });

  @override
  State<PlotDetailsPage> createState() => _PlotDetailsPageState();
}

class _PlotDetailsPageState extends State<PlotDetailsPage> {
  static const Color primaryGreen = Color(0xFF099509);
  static const Color paleYellow = Color(0xFFF6EAA7);
  static const Color taskRed = Color(0xFFDC6969);

  late String plotTitle;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(hour: 10, minute: 0);
  DateTime currentWeekStart = DateTime.now();
  List<Map<String, dynamic>> tasks = [];
  List<String> selectedSymptoms = [];
  List<String> tempSelectedSymptoms = [];
  bool _madeChanges = false;
  DiagnosisResult? _currentDiagnosis;
  String? _localPlotId;

  // Available symptoms to choose from
  final List<String> availableSymptoms = [
    // Brown Spot Disease
    'Brown Spots',
    'Gray Centers (Kulay-Abong Gitna)',
    'Drying Leaves (Natutuyong Dahon)',
    'Poor Grains (Pangit na Butil)',
    'Leaf Death (Pagkamatay ng Dahon)',

    // Rice Yellowing Syndrome (RYS)
    'Yellow Leaves (Naninilaw na Dahon)',
    'Stunted Growth (Pandak o Kulang sa paglaki)',
    'Excess Tillers (Sobrang Sanga)',
    'Twisted Leaves (Baluktot na Dahon)',
    'Empty Grains (Walang Laman na Butil)',

    // Sheath Blight
    'Wet Spots (Basa-basang Parte)',
    'Gray Patches (Kulay-abong Tagpi/Tapal)',
    'Fast Spread (Mabilis Kumalat)',
    'Dry Leaves (Natutuyong Dahon)',
    'Sclerotia/Black Spot-like (Itim na Butil-butil)',
  ];

  @override
  void initState() {
    super.initState();
    plotTitle = widget.title;
    _localPlotId = widget.plotId;
    if (_localPlotId != null) {
      _loadExistingSymptoms();
    }
    // start with empty tasks; we'll load from Firestore
    tasks = [];
    // load tasks from Firestore (will no-op if unauthenticated or no plot yet)
    _loadTasksFromFirestore();
    // Initialize with sample symptoms
    selectedSymptoms = ['Stunted Growth'];
    // initial diagnosis
    _currentDiagnosis = SymptomDiagnosis.diagnose(selectedSymptoms);
    // Set current week start to the beginning of the week
    currentWeekStart = _getWeekStart(DateTime.now());
  }

  // Load tasks from Firestore for this plot (users/{uid}/plots/{plotId}/tasks)
  Future<void> _loadTasksFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final plotId = await _ensureLocalPlotDocExists();
    if (plotId == null) return;

    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plots')
          .doc(plotId)
          .collection('tasks')
          .orderBy('date')
          .get();

      final loaded = q.docs.map((d) {
        final data = d.data();
        final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        return {
          'id': d.id,
          'date': date,
          'label': data['label'] ?? '',
          'notes': data['notes'] ?? '',
          'repeat': data['repeat'] ?? 'Never',
        };
      }).toList();

      if (mounted) {
        setState(() {
          tasks = loaded;
        });
      }
    } catch (e) {
      // silently ignore load errors for now
    }
  }

  // Save a task map to Firestore. If `id` is provided update, otherwise add new.
  // The task map must contain a 'date' as DateTime.
  Future<String> _saveTaskToFirestore(
    Map<String, dynamic> task, {
    String? id,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('User not signed in');

    final plotId = await _ensureLocalPlotDocExists();
    if (plotId == null) throw StateError('Plot id missing');

    final base = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plots')
        .doc(plotId)
        .collection('tasks');

    final dateTime = task['date'] as DateTime;
    final map = {
      'label': task['label'] ?? '',
      'notes': task['notes'] ?? '',
      'date': Timestamp.fromDate(dateTime),
      'repeat': task['repeat'] ?? 'Never',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      final docRef = await base.add(map);
      return docRef.id;
    } else {
      await base.doc(id).set(map, SetOptions(merge: true));
      return id;
    }
  }

  Future<void> _loadExistingSymptoms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.plotId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plots')
          .doc(widget.plotId)
          .get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      final symptomsField = data['symptoms'];
      if (symptomsField is List) {
        setState(() {
          selectedSymptoms = symptomsField.map((e) => e.toString()).toList();
          _currentDiagnosis = SymptomDiagnosis.diagnose(selectedSymptoms);
        });
        return;
      }

      // fallback: try lastDiagnosis.selectedSymptoms
      final last = data['lastDiagnosis'];
      if (last is Map && last['selectedSymptoms'] is List) {
        setState(() {
          selectedSymptoms = (last['selectedSymptoms'] as List)
              .map((e) => e.toString())
              .toList();
          _currentDiagnosis = SymptomDiagnosis.diagnose(selectedSymptoms);
        });
      }
    } catch (_) {
      // ignore load errors silently
    }
  }

  DateTime _getWeekStart(DateTime date) {
    // Get the start of the week (Sunday)
    return date.subtract(Duration(days: date.weekday % 7));
  }

  Future<void> _savePlotTitleToFirestore(String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _localPlotId == null) {
      throw StateError('User or plotId missing');
    }

    final base = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final update = {'title': title, 'ownerUid': user.uid};

    await base
        .collection('plots')
        .doc(_localPlotId)
        .set(update, SetOptions(merge: true));
  }

  Future<String?> _ensureLocalPlotDocExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    if (_localPlotId != null) return _localPlotId;

    final base = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      // try find existing by title
      final q = await base
          .collection('plots')
          .where('title', isEqualTo: plotTitle)
          .where('ownerUid', isEqualTo: user.uid)
          .get();
      if (q.docs.isNotEmpty) {
        _localPlotId = q.docs.first.id;
        return _localPlotId;
      }

      final docRef = await base.collection('plots').add({
        'title': plotTitle,
        'type': widget.variety,
        'createdAt': FieldValue.serverTimestamp(),
        'ownerUid': user.uid,
        'status': widget.healthy ? 'Healthy' : 'Suspected',
      });
      _localPlotId = docRef.id;
      return _localPlotId;
    } catch (_) {
      return null;
    }
  }

  void _navigateWeek(bool forward) {
    setState(() {
      currentWeekStart = currentWeekStart.add(Duration(days: forward ? 7 : -7));
    });
  }

  bool _hasTaskOnDate(DateTime date) {
    return tasks.any((task) {
      final taskDate = task['date'] as DateTime;
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    });
  }

  void _showMonthCalendar() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentWeekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Color(0xFFFFFFF3),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryGreen),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        currentWeekStart = _getWeekStart(pickedDate);
      });
    }
  }

  void _showEditTaskSheet(
    BuildContext ctx, {
    Map<String, dynamic>? task,
    int? taskIndex,
  }) {
    final titleController = TextEditingController(text: task?['label'] ?? '');
    final notesController = TextEditingController(text: task?['notes'] ?? '');
    DateTime taskDate = task?['date'] ?? selectedDate;
    TimeOfDay taskTime;
    if (task != null && task['date'] is DateTime) {
      final dt = task['date'] as DateTime;
      taskTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } else {
      taskTime = selectedTime;
    }
    String taskRepeat = task?['repeat'] ?? 'Never';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEFEF1),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          task == null ? 'New Task' : 'Edit Task',
                          style: const TextStyle(
                            fontFamily: 'Gotham',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF099509),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Title
                        const Text(
                          'Title',
                          style: TextStyle(
                            color: Color(0xFF099509),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            hintText: 'Title',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF77C000)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: Color(0xFF099509),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Description',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF77C000)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Date row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date',
                                    style: TextStyle(
                                      color: Color(0xFF099509),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final now = DateTime.now();
                                      final pickedDate = await showDatePicker(
                                        context: ctx,
                                        initialDate: taskDate,
                                        firstDate: DateTime(now.year - 2),
                                        lastDate: DateTime(now.year + 2),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: primaryGreen,
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                                surface: Color(0xFFFFFFF3),
                                              ),
                                              textButtonTheme:
                                                  TextButtonThemeData(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          primaryGreen,
                                                    ),
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (pickedDate != null) {
                                        setModalState(
                                          () => taskDate = pickedDate,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF77C000),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][taskDate.weekday - 1]}, '
                                            '${_monthName(taskDate.month)} ${taskDate.day}',
                                            style: const TextStyle(
                                              color: Color(0xFFE6B94C),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.edit_calendar,
                                            color: Color(0xFF099509),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Time
                        const Text(
                          'Time',
                          style: TextStyle(
                            color: Color(0xFF099509),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: ctx,
                              initialTime: taskTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: primaryGreen,
                                      onPrimary: Colors.white,
                                      onSurface: primaryGreen,
                                      surface: Color(0xFFFDFDD0),
                                    ),
                                    timePickerTheme: TimePickerThemeData(
                                      dialHandColor: primaryGreen,
                                      backgroundColor: const Color(0xFFFDFDD0),
                                      hourMinuteColor: Colors.transparent,
                                      hourMinuteTextColor:
                                          MaterialStateColor.resolveWith(
                                            (states) => const Color(0xFFE9BE35),
                                          ),
                                      dayPeriodColor:
                                          MaterialStateColor.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              MaterialState.selected,
                                            )) {
                                              return const Color(
                                                0xFF77C000,
                                              ).withOpacity(0.54);
                                            }
                                            return const Color(0xFFE8F5D0);
                                          }),
                                      dayPeriodTextColor:
                                          MaterialStateColor.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              MaterialState.selected,
                                            )) {
                                              return Colors.white;
                                            }
                                            return const Color(0xFF77C000);
                                          }),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setModalState(() => taskTime = pickedTime);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF77C000),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  taskTime.format(context),
                                  style: const TextStyle(
                                    color: Color(0xFFE6B94C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF099509),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Repeat
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Repeat',
                              style: TextStyle(
                                color: Color(0xFF099509),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            DropdownButton<String>(
                              value: taskRepeat,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Never',
                                  child: Text('Never'),
                                ),
                                DropdownMenuItem(
                                  value: 'Daily',
                                  child: Text('Daily'),
                                ),
                                DropdownMenuItem(
                                  value: 'Weekly',
                                  child: Text('Weekly'),
                                ),
                              ],
                              onChanged: (v) {
                                setModalState(() {
                                  taskRepeat = v!;
                                });
                              },
                              underline: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Add/Save Task button
                        Center(
                          child: SizedBox(
                            width: 180,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (titleController.text.isNotEmpty) {
                                  final combined = DateTime(
                                    taskDate.year,
                                    taskDate.month,
                                    taskDate.day,
                                    taskTime.hour,
                                    taskTime.minute,
                                  );
                                  final local = {
                                    'date': combined,
                                    'label': titleController.text,
                                    'notes': notesController.text.isEmpty
                                        ? 'No notes'
                                        : notesController.text,
                                    'repeat': taskRepeat,
                                  };

                                  try {
                                    if (task == null) {
                                      final newId = await _saveTaskToFirestore(
                                        local,
                                      );
                                      if (mounted) {
                                        setState(() {
                                          tasks.add({...local, 'id': newId});
                                          _madeChanges = true;
                                        });
                                      }
                                    } else {
                                      final existingId = task['id'] as String?;
                                      await _saveTaskToFirestore(
                                        local,
                                        id: existingId,
                                      );
                                      if (mounted) {
                                        setState(() {
                                          tasks[taskIndex!] = {
                                            ...local,
                                            'id': existingId,
                                          };
                                          _madeChanges = true;
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed saving task: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                                Navigator.of(ctx).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD3EC86),
                                foregroundColor: primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                task == null ? 'Add Task' : 'Save Task',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Calculate days until next check up (find nearest future task)
    int daysUntilCheckup = 0;
    if (tasks.isNotEmpty) {
      final futureTasks = tasks.where((t) {
        final taskDate = t['date'] as DateTime;
        return taskDate.isAfter(now);
      }).toList();
      if (futureTasks.isNotEmpty) {
        futureTasks.sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
        );
        final nextTask = futureTasks.first['date'] as DateTime;
        daysUntilCheckup = nextTask.difference(now).inDays;
      }
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(
          context,
        ).pop({'changed': _madeChanges, 'plotId': _localPlotId});
        return false; // we already popped
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFEFEF1),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryGreen),
            onPressed: () => Navigator.of(
              context,
            ).pop({'changed': _madeChanges, 'plotId': _localPlotId}),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editable title
                Row(
                  children: [
                    Text(
                      plotTitle,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        final controller = TextEditingController(
                          text: plotTitle,
                        );
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Edit Plot Name'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Plot name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (controller.text.isNotEmpty) {
                                    final newTitle = controller.text.trim();
                                    setState(() => plotTitle = newTitle);
                                    // persist the new title if this plot has an id
                                    if (widget.plotId != null) {
                                      try {
                                        await _savePlotTitleToFirestore(
                                          newTitle,
                                        );
                                        setState(() {
                                          _madeChanges = true;
                                        });
                                        if (mounted) Navigator.pop(ctx);
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed saving plot title: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      Navigator.pop(ctx);
                                    }
                                  } else {
                                    Navigator.pop(ctx);
                                  }
                                },
                                child: const Text(
                                  'Save',
                                  style: TextStyle(color: primaryGreen),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.edit,
                        color: primaryGreen,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Calendar card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFA6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => _navigateWeek(false),
                            child: const Text(
                              '< Prev week',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _showMonthCalendar,
                            child: Text(
                              _getMonthName(currentWeekStart.month),
                              style: const TextStyle(
                                color: primaryGreen,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _navigateWeek(true),
                            child: const Text(
                              'Next week >',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final date = currentWeekStart.add(Duration(days: i));
                          final isToday =
                              date.year == now.year &&
                              date.month == now.month &&
                              date.day == now.day;
                          final hasTask = _hasTaskOnDate(date);

                          return Container(
                            width: 40,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? primaryGreen
                                  : (hasTask
                                        ? const Color.fromARGB(255, 253, 7, 7)
                                        : const Color(0xFFFFFFA6)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isToday
                                    ? primaryGreen
                                    : (hasTask ? taskRed : primaryGreen),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: (isToday || hasTask)
                                        ? Colors.white
                                        : primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    'S',
                                    'M',
                                    'T',
                                    'W',
                                    'T',
                                    'F',
                                    'S',
                                  ][date.weekday % 7],
                                  style: TextStyle(
                                    color: (isToday || hasTask)
                                        ? Colors.white
                                        : primaryGreen,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          daysUntilCheckup > 0
                              ? '${daysUntilCheckup.toString().padLeft(2, '0')} days left until next check up'
                              : 'No upcoming check ups',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Tasks
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 232, 247, 189),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tasks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF018D01),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditTaskSheet(context),
                            icon: const Icon(Icons.add, color: primaryGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: tasks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final t = entry.value;
                          final taskDate = t['date'] as DateTime;

                          return InkWell(
                            onTap: () => _showEditTaskSheet(
                              context,
                              task: t,
                              taskIndex: index,
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF77C000).withOpacity(0.54),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF77C000).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _monthName(taskDate.month),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF018D01),
                                          ),
                                        ),
                                        Text(
                                          '${taskDate.day}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF018D01),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['label'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF018D01),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t['notes'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF018D01),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit,
                                    color: Color(0xFF018D01),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Symptoms
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      232,
                      247,
                      189,
                    ).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Symptoms',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF018D01),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black54,
                                ),
                                onPressed: () async {
                                  // show a stateful dialog so taps immediately update
                                  await showDialog<void>(
                                    context: context,
                                    builder: (dialogContext) {
                                      return StatefulBuilder(
                                        builder: (contextSB, setStateSB) {
                                          return Dialog(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  232,
                                                  247,
                                                  189,
                                                ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Header (matches Tasks container color)
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 12,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      232,
                                                      247,
                                                      189,
                                                    ),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Symptoms',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF018D01),
                                                    ),
                                                  ),
                                                ),
                                                // Clipped content area so selected green tiles don't overflow
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxHeight: 380,
                                                        minWidth: 250,
                                                      ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                    child: Container(
                                                      color:
                                                          const Color.fromARGB(
                                                            255,
                                                            232,
                                                            247,
                                                            189,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 6,
                                                            horizontal: 4,
                                                          ),
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: availableSymptoms.map((
                                                            symptom,
                                                          ) {
                                                            final isSelected =
                                                                selectedSymptoms
                                                                    .contains(
                                                                      symptom,
                                                                    );
                                                            return Container(
                                                              margin:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 6,
                                                                    horizontal:
                                                                        8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    isSelected
                                                                    ? const Color(
                                                                        0xFFD3EC86,
                                                                      )
                                                                    : Colors
                                                                          .transparent,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: ListTile(
                                                                contentPadding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                title: Text(
                                                                  symptom,
                                                                  style: TextStyle(
                                                                    color:
                                                                        isSelected
                                                                        ? primaryGreen
                                                                        : Colors
                                                                              .black87,
                                                                    fontWeight:
                                                                        isSelected
                                                                        ? FontWeight
                                                                              .w600
                                                                        : FontWeight
                                                                              .normal,
                                                                  ),
                                                                ),
                                                                trailing:
                                                                    isSelected
                                                                    ? const Icon(
                                                                        Icons
                                                                            .check_circle,
                                                                        color:
                                                                            primaryGreen,
                                                                      )
                                                                    : null,
                                                                onTap: () async {
                                                                  setStateSB(() {
                                                                    if (isSelected) {
                                                                      selectedSymptoms
                                                                          .remove(
                                                                            symptom,
                                                                          );
                                                                    } else {
                                                                      selectedSymptoms
                                                                          .add(
                                                                            symptom,
                                                                          );
                                                                    }
                                                                  });
                                                                  if (mounted) {
                                                                    setState(() {
                                                                      _currentDiagnosis =
                                                                          SymptomDiagnosis.diagnose(
                                                                            selectedSymptoms,
                                                                          );
                                                                    });
                                                                  }

                                                                  final diagnosis =
                                                                      SymptomDiagnosis.diagnose(
                                                                        selectedSymptoms,
                                                                      );
                                                                  try {
                                                                    if (_localPlotId ==
                                                                        null) {
                                                                      await _ensureLocalPlotDocExists();
                                                                    }
                                                                    await SymptomDiagnosis.saveDiagnosisToFirestore(
                                                                      diagnosis,
                                                                      plotId:
                                                                          _localPlotId,
                                                                      originalSelectedSymptoms:
                                                                          selectedSymptoms,
                                                                    );
                                                                    if (mounted) {
                                                                      setState(() {
                                                                        _madeChanges =
                                                                            true;
                                                                      });
                                                                    }
                                                                  } catch (e) {
                                                                    if (e
                                                                            is FirebaseException &&
                                                                        e.code ==
                                                                            'permission-denied') {
                                                                      ScaffoldMessenger.of(
                                                                        dialogContext,
                                                                      ).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text(
                                                                            'Permission denied saving to Firestore. Check authentication and Firestore rules.',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      ScaffoldMessenger.of(
                                                                        dialogContext,
                                                                      ).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(
                                                                            'Failed to save symptom: $e',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Done action
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 12,
                                                        right: 12,
                                                        bottom: 12,
                                                        top: 6,
                                                      ),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            dialogContext,
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFD3EC86,
                                                            ),
                                                        foregroundColor:
                                                            primaryGreen,
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        child: Text(
                                                          'Done',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Color(
                                                              0xFF099509,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          Builder(
                            builder: (context) {
                              final diag =
                                  _currentDiagnosis ??
                                  SymptomDiagnosis.diagnose(selectedSymptoms);
                              if (diag.isHealthy) {
                                return Text(
                                  'Healthy',
                                  style: const TextStyle(
                                    color: Color(0xFF018D01),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }

                              // sort suspected diseases by score (desc) and take top 3
                              final scores = diag.scores;
                              final suspects = List<String>.from(
                                diag.suspectedDiseases,
                              );
                              suspects.sort(
                                (a, b) =>
                                    (scores[b] ?? 0).compareTo(scores[a] ?? 0),
                              );
                              final top = suspects.take(3).toList();
                              // Format the top suspects into up to two visual lines
                              String label;
                              if (top.isEmpty) {
                                label = '';
                              } else if (top.length == 1) {
                                label = top.first;
                              } else {
                                // split into two roughly-equal parts and join with a newline
                                final split = (top.length / 2).ceil();
                                final first = top.sublist(0, split).join(', ');
                                final second = top.sublist(split).join(', ');
                                label = second.isNotEmpty ? '$first\n$second' : first;
                              }

                              return Text(
                                label.isEmpty ? 'Suspected' : label,
                                style: const TextStyle(
                                  color: Color(0xFFD21100),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Log any visible symptoms',
                        style: TextStyle(
                          color: Color(0xFF5D5D5D),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Display selected symptoms
                      if (selectedSymptoms.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedSymptoms.map((symptom) {
                            return Chip(
                              label: Text(symptom),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                              onDeleted: () async {
                                setState(() {
                                  selectedSymptoms.remove(symptom);
                                });
                                // update local diagnosis immediately
                                setState(() {
                                  _currentDiagnosis = SymptomDiagnosis.diagnose(
                                    selectedSymptoms,
                                  );
                                });
                                // update diagnosis after removal
                                final diagnosis = SymptomDiagnosis.diagnose(
                                  selectedSymptoms,
                                );
                                try {
                                  if (_localPlotId == null) {
                                    await _ensureLocalPlotDocExists();
                                  }
                                  await SymptomDiagnosis.saveDiagnosisToFirestore(
                                    diagnosis,
                                    plotId: _localPlotId,
                                    originalSelectedSymptoms: selectedSymptoms,
                                  );
                                  setState(() {
                                    _madeChanges = true;
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to save symptom removal: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              backgroundColor: const Color(0xFF099509),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
