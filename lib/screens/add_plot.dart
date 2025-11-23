import 'package:flutter/material.dart';

class AddPlotOverlay extends StatefulWidget {
  const AddPlotOverlay({super.key});

  @override
  State<AddPlotOverlay> createState() => _AddPlotOverlayState();
}

class _AddPlotOverlayState extends State<AddPlotOverlay> {
  final TextEditingController _titleCtrl = TextEditingController();
  DateTime _selected = DateTime.now();
  String _selectedType = 'Jasmine Rice';

  final List<String> _types = [
    'Jasmine Rice',
    'Red Rice',
    'Black Rice',
    'Brown Rice',
    'Dinorado',
    'Milagrosa',
    'Malagkit',
    'Sinandomeng',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF099509);
    const Color paleYellow = Color(0xFFFDFDD0);
    const Color labelGold = Color(0xFFE6A800);
    // Use the sheet route animation (if available) to create a slide+fade easing from bottom
    final Animation<double>? routeAnimation = ModalRoute.of(context)?.animation;

    Widget content = Container(
      decoration: const BoxDecoration(
        color: paleYellow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'New Plot',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 18),

              // Title label & field
              const Text(
                'Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: labelGold,
                ),
              ),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryGreen),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryGreen),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Date row with calendar button
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(_selected),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: labelGold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2,
                            color: primaryGreen.withOpacity(0.75),
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  // circular calendar button
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Type label
              const Text(
                'Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 8),

              // Types grid (two columns of radio items)
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: _types
                        .map(
                          (t) => SizedBox(
                            width: (MediaQuery.of(context).size.width - 64) / 2,
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              value: t,
                              groupValue: _selectedType,
                              onChanged: (v) => setState(
                                () => _selectedType = v ?? _selectedType,
                              ),
                              title: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              dense: true,
                              activeColor: primaryGreen.withOpacity(0.8),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              // Add Plot button (smaller width, custom hover/pressed color)
              Center(
                child: SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: wire saving logic
                      Navigator.of(context).pop({
                        'title': _titleCtrl.text,
                        'date': _selected,
                        'type': _selectedType,
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color?>((states) {
                            const base = Color(0xFFF9ED96); // requested color
                            const hover = Color(0xFFE6D870); // slightly darker
                            if (states.contains(MaterialState.pressed) ||
                                states.contains(MaterialState.hovered))
                              return hover;
                            return base;
                          }),
                      elevation: MaterialStateProperty.all(0),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 10),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    child: Text(
                      'Add Plot',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (routeAnimation != null) {
      // slide from bottom + fade-in using the route's animation and a curve
      final curved = CurvedAnimation(
        parent: routeAnimation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: routeAnimation, child: content),
      );
    }

    return content;
  }

  String _formatDate(DateTime d) {
    // e.g., Friday, Sep 5
    final weekday = _weekdayName(d.weekday);
    final month = _monthName(d.month);
    return '$weekday, $month ${d.day}';
  }

  String _weekdayName(int w) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(w - 1) % 7];
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(m - 1) % 12];
  }
}
