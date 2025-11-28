import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_plot.dart';
import 'plot_details.dart';
import 'homepage.dart';
import 'profile.dart';
import 'discover.dart';
import 'welcome_screen.dart';

class PlotManagerPage extends StatefulWidget {
  final String? initialPlot;

  const PlotManagerPage({super.key, this.initialPlot});

  @override
  State<PlotManagerPage> createState() => _PlotManagerPageState();
}

class _PlotManagerPageState extends State<PlotManagerPage> {
  // Keep created/found doc ids for the example static plots so edits persist
  final Map<String, String> _staticPlotIds = {};
  final Map<String, String> _staticPlotStatus = {};
  @override
  void initState() {
    super.initState();
    // If an initial plot is provided, open its details after build
    if (widget.initialPlot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInitialPlot(widget.initialPlot!);
      });
    }
  }

  Future<void> _openInitialPlot(String title) async {
    // Map known titles to example detail data
    final map = {
      'Plot A': {
        'variety': 'Jasmine Rice',
        'age': '20 weeks old',
        'healthy': true,
      },
    };

    final info = map[title];
    if (info == null) return;

    final user = FirebaseAuth.instance.currentUser;
    String? plotId;

    if (user != null) {
      final base = FirebaseFirestore.instance.collection('users').doc(user.uid);
      // try to find existing plot(s) with this title for the user
      try {
        final q = await base
            .collection('plots')
            .where('title', isEqualTo: title)
            .get();
        if (q.docs.isNotEmpty) {
          // keep first, remove duplicates
          plotId = q.docs.first.id;
          if (q.docs.length > 1) {
            for (var i = 1; i < q.docs.length; i++) {
              try {
                await base.collection('plots').doc(q.docs[i].id).delete();
              } catch (_) {}
            }
          }
        } else {
          // create a persistent doc for this example plot so edits will save
          final docRef = await base.collection('plots').add({
            'title': title,
            'type': info['variety'],
            'createdAt': FieldValue.serverTimestamp(),
            'ownerUid': user.uid,
            'status': (info['healthy'] as bool) ? 'Healthy' : 'Suspected',
          });
          plotId = docRef.id;
        }
      } catch (_) {
        // ignore Firestore errors — we'll open non-persistent view
      }
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlotDetailsPage(
          title: title,
          variety: info['variety'] as String,
          age: info['age'] as String,
          healthy: info['healthy'] as bool,
          plotId: plotId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF099509);
    const Color paleYellow = Color(0xFFF6EAA7);

    Widget _plotCard({
      required String title,
      required String variety,
      required String age,
      required bool healthy,
      String? plotId,
      String? status,
    }) {
      return InkWell(
        onTap: () async {
          final user = FirebaseAuth.instance.currentUser;
          String? id = plotId ?? _staticPlotIds[title];
          String? statusToShow = _staticPlotStatus[title];

          if ((id == null || id.isEmpty) && user != null) {
            final base = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid);
            // search for existing plot by title owned by this user to avoid duplicates
            final q = await base
                .collection('plots')
                .where('title', isEqualTo: title)
                .where('ownerUid', isEqualTo: user.uid)
                .get();

            if (q.docs.isNotEmpty) {
              // keep the first match and delete other duplicates
              id = q.docs.first.id;
              final firstData = q.docs.first.data();
              if (firstData['status'] != null) {
                statusToShow = firstData['status'] as String;
              }
              if (q.docs.length > 1) {
                for (var i = 1; i < q.docs.length; i++) {
                  try {
                    await base.collection('plots').doc(q.docs[i].id).delete();
                  } catch (_) {
                    // ignore
                  }
                }
              }
            } else {
              // create a new doc so edits persist for this example
              final docRef = await base.collection('plots').add({
                'title': title,
                'type': variety,
                'createdAt': FieldValue.serverTimestamp(),
                'ownerUid': user.uid,
                'status': (healthy ? 'Healthy' : 'Suspected'),
              });
              id = docRef.id;
              statusToShow = healthy ? 'Healthy' : 'Suspected';
            }

            // cache for faster UI updates
            _staticPlotIds[title] = id;
            if (statusToShow != null) _staticPlotStatus[title] = statusToShow;
          }

          final result = await Navigator.of(context).push<dynamic>(
            MaterialPageRoute(
              builder: (_) => PlotDetailsPage(
                title: title,
                variety: variety,
                age: age,
                healthy: healthy,
                plotId: id,
              ),
            ),
          );

          String? returnedId;
          bool changedFlag = false;
          if (result is Map) {
            returnedId = result['plotId'] as String?;
            changedFlag = result['changed'] as bool? ?? false;
          } else if (result is bool) {
            changedFlag = result;
          }

          if (returnedId != null) {
            _staticPlotIds[title] = returnedId;
            id = returnedId;
          }

          if (changedFlag && mounted) {
            // refresh cached status from Firestore for this static plot (if any)
            if (id != null && user != null) {
              try {
                final doc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('plots')
                    .doc(id)
                    .get();
                if (doc.exists) {
                  final data = doc.data();
                  if (data != null && data['status'] != null) {
                    final rawStatus = data['status'] as String;
                    final parts = rawStatus
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    if (parts.length <= 1) {
                      _staticPlotStatus[title] = rawStatus;
                    } else {
                      final split = (parts.length / 2).ceil();
                      final first = parts.sublist(0, split).join(', ');
                      final second = parts.sublist(split).join(', ');
                      _staticPlotStatus[title] = second.isNotEmpty
                          ? '$first\n$second'
                          : first;
                    }
                  }
                }
              } catch (_) {}
            }
            // Firestore stream should update automatically; force rebuild to reflect optimistic change
            setState(() {});
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: paleYellow, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/plot_pic.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.green[50],
                        child: const Icon(
                          Icons.agriculture,
                          color: primaryGreen,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color:
                                      (status ??
                                              (healthy
                                                  ? 'Healthy'
                                                  : 'Suspected')) ==
                                          'Healthy'
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (() {
                                  final raw =
                                      status ??
                                      (healthy ? 'Healthy' : 'Suspected');
                                  final parts = raw
                                      .split(',')
                                      .map((s) => s.trim())
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length <= 1) return raw;
                                  final split = (parts.length / 2).ceil();
                                  final first = parts
                                      .sublist(0, split)
                                      .join(', ');
                                  final second = parts
                                      .sublist(split)
                                      .join(', ');
                                  return second.isNotEmpty
                                      ? '$first\n$second'
                                      : first;
                                })(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        variety,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const PlotMenuDrawer(),
      backgroundColor: const Color(0xFFFEFEF1),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // menu icon
                  Builder(
                    builder: (ctx) {
                      return IconButton(
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                        icon: const Icon(Icons.menu, color: Colors.green),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Plots',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF099509),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        // Divider between static examples and user plots
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Live list of user-created plots from Firestore
                        Builder(
                          builder: (ctx) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  'Sign in to see your plots',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            }

                            final stream = FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('plots')
                                .orderBy('createdAt', descending: true)
                                .snapshots();

                            return StreamBuilder<QuerySnapshot>(
                              stream: stream,
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (snap.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'Error loading plots: ${snap.error}',
                                    ),
                                  );
                                }

                                final docs = snap.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'No plots yet. Tap + to add a new plot.',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  );
                                }

                                // Build widgets but skip duplicate example docs titled
                                // 'Plot A' or 'Plot B' that don't have a valid age
                                final List<Widget> plotWidgets = [];
                                for (final d in docs) {
                                  final data = d.data() as Map<String, dynamic>;
                                  final title =
                                      (data['title'] ?? 'Untitled') as String;
                                  final variety =
                                      (data['type'] ?? 'Unknown') as String;

                                  String ageText = '';
                                  try {
                                    // prefer `date` timestamp if present
                                    final ts = data['date'] as Timestamp?;
                                    if (ts != null) {
                                      final planted = ts.toDate();
                                      final diff = DateTime.now()
                                          .difference(planted)
                                          .inDays;
                                      final weeks = (diff / 7).floor();
                                      if (weeks >= 1) {
                                        ageText = '$weeks weeks old';
                                      } else {
                                        ageText =
                                            'Planted on ${planted.month}/${planted.day}/${planted.year}';
                                      }
                                    }
                                  } catch (_) {
                                    ageText = '';
                                  }

                                  // If this is one of the example titles and there is no
                                  // computed age, treat it as a duplicate and skip it.
                                  if ((title == 'Plot A' ||
                                          title == 'Plot B') &&
                                      ageText.isEmpty) {
                                    continue;
                                  }

                                  // Use stored `status` field if present. Default to Healthy.
                                  final status =
                                      (data['status'] as String?) ?? 'Healthy';
                                  final healthy = status == 'Healthy';

                                  plotWidgets.add(
                                    _plotCard(
                                      title: title,
                                      variety: variety,
                                      age: ageText.isNotEmpty
                                          ? ageText
                                          : 'Unknown age',
                                      healthy: healthy,
                                      plotId: d.id,
                                      status: status,
                                    ),
                                  );
                                }

                                return Column(children: plotWidgets);
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // FAB style add
            Positioned(
              right: 20,
              bottom: 30,
              child: FloatingActionButton(
                backgroundColor: primaryGreen,
                onPressed: () async {
                  // show overlay at ~80% of screen height
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.8,
                      child: const AddPlotOverlay(),
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                  );

                  if (result != null) {
                    // optional: handle returned plot data
                    // debug print for now
                    // ignore: avoid_print
                    print('New plot added: $result');
                  }
                },
                child: const Icon(Icons.add, size: 28, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlotMenuDrawer extends StatefulWidget {
  const PlotMenuDrawer({Key? key}) : super(key: key);

  @override
  State<PlotMenuDrawer> createState() => _PlotMenuDrawerState();
}

class _PlotMenuDrawerState extends State<PlotMenuDrawer> {
  String _selected = 'Plots';

  void _select(String label) {
    setState(() {
      _selected = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFFFFFD6),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 18),
                    child: Image.asset(
                      'assets/images/masagani_logoname.png',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _PlotDrawerHoverTile(
                  label: 'Home',
                  selected: _selected == 'Home',
                  onTap: () {
                    _select('Home');
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const HomePage()));
                  },
                ),
                _PlotDrawerHoverTile(
                  label: 'Plots',
                  selected: _selected == 'Plots',
                  onTap: () {
                    _select('Plots');
                    Navigator.of(context).pop();
                  },
                ),
                _PlotDrawerHoverTile(
                  label: 'Discover',
                  selected: _selected == 'Discover',
                  onTap: () {
                    _select('Discover');
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DiscoverScreen()),
                    );
                  },
                ),
                _PlotDrawerHoverTile(
                  label: 'Profile',
                  selected: _selected == 'Profile',
                  onTap: () {
                    _select('Profile');
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                const Spacer(),
                const Divider(),
                _PlotDrawerHoverTile(
                  label: 'Log out',
                  leading: const Icon(Icons.logout, color: Color(0xFF0B8A12)),
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(title: 'masagAni'),
                      ),
                      (route) => false,
                    );
                  },
                  isLogout: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlotDrawerHoverTile extends StatefulWidget {
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool selected;
  final bool isLogout;

  const _PlotDrawerHoverTile({
    Key? key,
    required this.label,
    this.leading,
    this.onTap,
    this.selected = false,
    this.isLogout = false,
  }) : super(key: key);

  @override
  State<_PlotDrawerHoverTile> createState() => _PlotDrawerHoverTileState();
}

class _PlotDrawerHoverTileState extends State<_PlotDrawerHoverTile> {
  bool _hovering = false;
  bool _pressing = false;

  void _onEnter(PointerEvent _) => setState(() => _hovering = true);
  void _onExit(PointerEvent _) => setState(() => _hovering = false);

  @override
  Widget build(BuildContext context) {
    const hoverBg = Color(0xFFF9ED96);
    final bool highlight = widget.selected || _hovering || _pressing;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() {
          _pressing = true;
          _hovering = false;
        }),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _pressing
              ? Duration.zero
              : const Duration(milliseconds: 20),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: highlight ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: _pressing
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  style: TextStyle(
                    fontFamily: 'Gotham',
                    fontSize: highlight ? 20 : 18,
                    fontWeight: widget.selected
                        ? FontWeight.w300
                        : FontWeight.w500,
                    color: const Color(0xFF0B8A12),
                  ),
                  child: Text(widget.label),
                ),
              ),
              if (widget.isLogout)
                const SizedBox.shrink()
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
