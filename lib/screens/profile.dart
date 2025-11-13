import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF099509);
    const Color bgBase = Color(0xFFFEFEF1);

    return Scaffold(
      backgroundColor: bgBase,
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
                  // Menu button (left) and Logout (right) placed over header
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        tooltip: 'Menu',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Menu tapped')),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: TextButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Log out',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          final doLogout = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm logout'),
                              content: const Text(
                                'Are you sure you want to log out?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Log out'),
                                ),
                              ],
                            ),
                          );
                          if (doLogout == true) {
                            // For development: navigate back to WelcomeScreen and
                            // remove all previous routes so user cannot go back.
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const WelcomeScreen(title: 'masagAni'),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  // (avatar moved out of the header Stack so it sits
                  // inside the white content area below the header)
                ],
              ),

              // Small gap between header and avatar placed in the white area
              const SizedBox(height: 12),

              // Avatar placed inside the white padding above the name so
              // it does not overlap the header image.
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.green[50],
                    // Show the image only once and make it fill the inner
                    // circle more (zoomed in). Use BoxFit.cover so it looks
                    // fuller; adjust alignment to avoid cutting shoulders.
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(2.0), // was 4.0
                        child: Image.asset(
                          'assets/images/alejandro_icon.png',
                          fit: BoxFit.contain,
                          width: 64, // increase from 56
                          height: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Name and Edit
              Column(
                children: [
                  const Text(
                    'Alejandro Villanueva',
                    style: TextStyle(
                      fontFamily: 'Gotham',
                      fontSize: 22,
                      color: Color(0xFF0B8A12),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Make Edit Profile clickable to open the edit page
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.center,
                    ),
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
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/paddy_avatar.png',
                                fit: BoxFit.cover, // Add this
                                width: 128, // Should be radius * 2 (64*2 = 128)
                                height: 128,
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Small left padding before the number
                                  const SizedBox(width: 8),
                                  const SizedBox(width: 2),
                                  Text(
                                    '153',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  // Grain icon placed after the number (to the right of the '3')
                                  const SizedBox(width: 6),
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
                            children: const [
                              Text(
                                'Total Agri Points:',
                                style: TextStyle(color: Colors.black54),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '1250',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Simple timeline indicator
                      Column(
                        children: [
                          // Dots and leaves row
                          // Replace the individual leaf icons with a single
                          // grain streak image that spans the five positions,
                          // then show the corresponding numbers 150..154 aligned
                          // beneath it using spaceBetween.
                          Column(
                            children: [
                              // Full-width grain streak graphic
                              Image.asset(
                                'assets/images/streak_day_count_v2.png',
                                width: double.infinity,
                                height: 24,
                                fit: BoxFit.fill,
                              ),
                              const SizedBox(height: 6),
                              // Numbers aligned under the streak graphic
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(5, (index) {
                                  return Text(
                                    '${150 + index}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Redeem button
                          SizedBox(
                            width: 160,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {},
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
}
