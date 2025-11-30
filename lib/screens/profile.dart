import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'edit_profile.dart';
import 'homepage.dart';
import 'plot_manager.dart';
import 'rewards.dart';
import 'discover.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _firstName = '';
  String _lastName = '';
  String _avatar = 'man';
  int _totalPoints = 1890;
  int _streakDisplay = 150;
  StreamSubscription<DocumentSnapshot>? _profileSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _startProfileListener();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Try to read Firestore profile
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _firstName = (data['firstName'] ?? '') as String;
          _lastName = (data['lastName'] ?? '') as String;
          _displayName =
              (data['displayName'] ?? user.displayName ?? '') as String;
          _avatar = (data['avatar'] ?? 'man') as String;
          _totalPoints = (data['totalPoints'] ?? 1890) as int;
        });
      } else {
        setState(() {
          _displayName = user.displayName ?? '';
          _avatar = 'man';
        });
      }
    } catch (_) {
      setState(() {
        _displayName = user.displayName ?? '';
      });
    }
  }

  void _startProfileListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (doc) {
            if (doc.exists) {
              final data = doc.data()!;
              setState(() {
                _firstName = (data['firstName'] ?? '') as String;
                _lastName = (data['lastName'] ?? '') as String;
                _displayName =
                    (data['displayName'] ??
                            FirebaseAuth.instance.currentUser?.displayName ??
                            '')
                        as String;
                _avatar = (data['avatar'] ?? 'man') as String;
                _totalPoints = (data['totalPoints'] ?? 1890) as int;
              });
            }
          },
          onError: (_) {
            // keep last known values
          },
        );
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF099509);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _ProfileDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top header with background image
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.asset(
                      // Use the new landscape header image (drop this file into assets/images)
                      'assets/images/header_streak.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Top-left menu button (white for contrast on header)
                  Positioned(
                    left: 12,
                    top: 8,
                    child: Builder(
                      builder: (ctx) {
                        return IconButton(
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: const Icon(Icons.menu),
                          color: const Color.fromARGB(255, 254, 255, 181),
                        );
                      },
                    ),
                  ),

                  // Top-right logout (overlay on header)
                  Positioned(
                    right: 12,
                    top: 8,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) =>
                                const WelcomeScreen(title: 'masagAni'),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Log out',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),

                  // Avatar circle centered overlapping — image removed
                  // Position the avatar fully inside the header so it doesn't
                  // overlap the white content below. Use a top offset that
                  // keeps the circle visible within the 160px header.
                  Positioned(
                    top: 79,
                    child: GestureDetector(
                      onTap: _changeAvatar,
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(
                            _avatar == 'woman'
                                ? 'assets/images/alexandra_icon.png'
                                : 'assets/images/alejandro_icon.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Reduced spacing since the avatar no longer overlaps content
              const SizedBox(height: 12),

              // Name and Edit
              Column(
                children: [
                  Text(
                    _displayName.isNotEmpty ? _displayName : 'Your Name',
                    style: const TextStyle(
                      fontFamily: 'Gotham',
                      fontSize: 22,
                      color: Color(0xFF0B8A12),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      // Reload profile after edit
                      await _loadProfile();
                    },
                    child: const Text(
                      '✎ Edit Profile',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Row: pet avatar and name
                      Column(
                        children: [
                          // Pet image
                          CircleAvatar(
                            radius: 64,
                            backgroundColor: Colors.yellow[50],
                            child: ClipOval(
                              child: Image.asset(
                                // Cow avatar for Paddy (drop this file into assets/images)
                                'assets/images/paddy_avatar.png',
                                width: 112,
                                height: 112,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Paddy',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFFB98900),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Streak days and points row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _streakDisplay.toString(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    'assets/images/grain_streak.png',
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Streak Days',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Total Agri Points:',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _totalPoints.toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Simple timeline indicator — streak graphic with labels (150-154)
                      Column(
                        children: [
                          Column(
                            children: [
                              Image.asset(
                                'assets/images/streak_day_count.png',
                                width: double.infinity,
                                height: 75,
                                fit: BoxFit.fitWidth,
                              ),
                              const SizedBox(height: 3),
                              // Numbers aligned under the streak graphic
                              // Use small horizontal offsets to tweak label positions.
                              Builder(
                                builder: (context) {
                                  final offsets = <double>[
                                    -4.0,
                                    -2.0,
                                    0.0,
                                    2.0,
                                    4.0,
                                  ];
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(5, (index) {
                                      final dx = (index < offsets.length)
                                          ? offsets[index]
                                          : 0.0;
                                      return Transform.translate(
                                        offset: Offset(dx, 0),
                                        child: Text(
                                          '${150 + index}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Redeem button
                          SizedBox(
                            width: 160,
                            height: 44,
                            child: SizedBox(
                              width: 160,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RewardsScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[200],
                                  foregroundColor: Colors.brown[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text('Redeem Rewards'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    // show a bottom sheet to choose between Man/Woman
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Avatar',
                style: TextStyle(
                  fontFamily: 'Gotham',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage(
                    'assets/images/alejandro_icon.png',
                  ),
                ),
                title: const Text('Man'),
                onTap: () => Navigator.of(ctx).pop('man'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage(
                    'assets/images/alexandra_icon.png',
                  ),
                ),
                title: const Text('Woman'),
                onTap: () => Navigator.of(ctx).pop('woman'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (choice == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'avatar': choice,
      }, SetOptions(merge: true));
      setState(() {
        _avatar = choice;
      });
    } catch (e) {
      // ignore errors silently for now; could show SnackBar
    }
  }
}

class _ProfileDrawer extends StatefulWidget {
  const _ProfileDrawer({Key? key}) : super(key: key);

  @override
  State<_ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<_ProfileDrawer> {
  String _selected = 'Profile';

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
                _HoverListTile(
                  label: 'Home',
                  selected: _selected == 'Home',
                  onTap: () {
                    _select('Home');
                    // Close the drawer first, then navigate to HomePage
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const HomePage()));
                  },
                ),
                _HoverListTile(
                  label: 'Plots',
                  selected: _selected == 'Plots',
                  onTap: () {
                    _select('Plots');
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlotManagerPage(),
                      ),
                    );
                  },
                ),
                _HoverListTile(
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
                _HoverListTile(
                  label: 'Profile',
                  selected: _selected == 'Profile',
                  onTap: () {
                    _select('Profile');
                    Navigator.of(context).pop();
                  },
                ),
                const Spacer(),
                const Divider(),
                _HoverListTile(
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

class _HoverListTile extends StatefulWidget {
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool selected;
  final bool isLogout;

  const _HoverListTile({
    Key? key,
    required this.label,
    this.leading,
    this.onTap,
    this.selected = false,
    this.isLogout = false,
  }) : super(key: key);

  @override
  State<_HoverListTile> createState() => _HoverListTileState();
}

class _HoverListTileState extends State<_HoverListTile> {
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
          // When pressing, prefer the pressed visual immediately and
          // clear hover so we don't blend the hover overlay with press.
          _pressing = true;
          _hovering = false;
        }),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          // Make the transition instantaneous when pressing so the
          // pressed (yellow) state appears immediately. Otherwise use
          // a short animation for hover transitions.
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

// Public wrapper so other screens can reuse the same drawer UI.
class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _ProfileDrawer();
  }
}
