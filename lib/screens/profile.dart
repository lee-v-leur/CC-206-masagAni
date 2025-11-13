import 'package:flutter/material.dart';

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
                  // Avatar circle centered overlapping — image removed
                  // Position the avatar fully inside the header so it doesn't
                  // overlap the white content below. Use a top offset that
                  // keeps the circle visible within the 160px header.
                  Positioned(
                    top: 116,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.green[50],
                        // Show Alejandro icon image (drop this file into assets/images)
                        backgroundImage: const AssetImage(
                          'assets/images/alejandro_icon.png',
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
                children: const [
                  Text(
                    'Alejandro Villanueva',
                    style: TextStyle(
                      fontFamily: 'Gotham',
                      fontSize: 22,
                      color: Color(0xFF0B8A12),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '✎ Edit Profile',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
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
                            radius: 48,
                            backgroundColor: Colors.white,
                            child: Image.asset(
                              // Cow avatar for Paddy (drop this file into assets/images)
                              'assets/images/paddy_avatar.png',
                              width: 76,
                              height: 76,
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
                            children: const [
                              Text(
                                '153',
                                style: TextStyle(
                                  fontSize: 36,
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(5, (index) {
                              final reached =
                                  index <
                                  4; // show 4 greens reached, last is empty
                              return Column(
                                children: [
                                  Icon(
                                    Icons.eco,
                                    color: reached
                                        ? primaryGreen
                                        : Colors.amber.shade200,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${150 + index}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              );
                            }),
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
