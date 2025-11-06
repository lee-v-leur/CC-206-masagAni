// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'login.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.title});
  final String title;

  Route _createLoginRoute() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 550),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from bottom to top with fade
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final offsetAnim = Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .animate(curved);
        final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

        return SlideTransition(
          position: offsetAnim,
          child: FadeTransition(opacity: fadeAnim, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove AppBar if you want a fullscreen welcome; keeping minimal here
      body: Stack(
        children: [
          // Fullscreen background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/welcomepage.png',
              fit: BoxFit.cover,
            ),
          ),

          // Buttons section
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOGIN BUTTON
                SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(_createLoginRoute());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color(0xFF099509).withOpacity(0.75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // SIGN UP BUTTON (same style; navigate to signup when ready)
                SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to signup when implemented
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color(0xFF099509).withOpacity(0.75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
