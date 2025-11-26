// lib/screens/login.dart
//
// Copy-paste ready Login screen.
// Requirements implemented:
// - Background #FEFEF1 with top gradient #FFFFC8 that covers 45% height
// - Title in Gotham (45) colored #099509
// - Fields styled: white fill, stroke #77C000, hint color #9A9292, Inter 13
// - Buttons same size as welcome (220x50), color #099509 @ 75% opacity, white text
// - Password show/hide toggle
// - Email + password validation (rule 2: 8+ chars, 1 uppercase, 1 number)
// - Responsive widths + text scaling
// - Entrance animation (fields & button slide/fade in)
// - Social icons (Google, Facebook, Apple, GitHub, Twitter) using font_awesome_flutter (vector)
// - Hover effect (web) and tap scale animation for social icons
// - Back button: Navigator.pop()
// Make sure you have font_awesome_flutter in pubspec and fonts registered as you described.

import 'dart:async';
// foundation import removed (no web hover behavior)
import 'package:flutter/material.dart';
// removed social icon dependency (social-login UI removed)
import 'loading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  // Animations
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    final curve = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curve);
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

    // Start animation shortly after build for nicer effect
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Email validation
  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Please enter email';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  // Password rule 2: at least 8 characters, at least 1 uppercase, 1 digit
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter password';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v))
      return 'Include at least one uppercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Include at least one number';
    return null;
  }

  Future<void> _submit() async {
    // Validate inputs first
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Signed in successfully
      // Debugging info
      // ignore: avoid_print
      print(
        'Signed in: uid=${userCred.user?.uid}, email=${userCred.user?.email}',
      );
      if (!mounted) return;

      // derive a first name to show in loading screen (displayName or email prefix)
      final firstName =
          userCred.user?.displayName ??
          (userCred.user?.email?.split('@').first ?? '');

      // Navigate to LoadingScreen for 3 seconds, then LoadingScreen will route to HomePage
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                LoadingScreen(firstName: firstName, durationMillis: 3000),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final code = e.code;
      final message = e.message ?? 'Authentication error';
      if (mounted) {
        if (code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No account found for that email. Please sign up.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login error [$code]: $message')),
          );
        }
      }
    } catch (e) {

      // Fetch user's first name from Firestore
      String firstName = 'User';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user?.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          firstName = data?['firstName'] ?? data?['name']?.split(' ')[0] ?? 'User';
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error fetching user name: $e');
      }

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(
        builder: (_) => LoadingScreen(firstName: firstName),
      ));
    } on FirebaseAuthException catch (e) {
      final code = e.code;
      final message = e.message ?? 'Authentication error';
      // ignore: avoid_print
      print('FirebaseAuthException: code=$code message=$message');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login error [$code]: $message')));
    } catch (e) {
      // ignore: avoid_print
      print('Unexpected login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Utility to compute responsive widths
  double _computeFieldWidth(double deviceWidth) {
    if (deviceWidth < 360) return deviceWidth * 0.85;
    if (deviceWidth < 420) return deviceWidth * 0.78;
    return 300;
  }

  // Social-login removed; no helper needed.
  // Button width helper removed (not used while auth is bypassed).

  // Social icon builder with hover & tap scale animation
  Widget _buildSocialIcon({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    double radius = 22,
  }) {
    return _HoverTapScale(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: FaIcon(icon, color: iconColor, size: radius - 6),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colors & theme values
    const Color primaryGreen = Color(0xFF099509);
    const Color strokeGreen = Color(0xFF77C000);
    const Color hintGray = Color(0xFF9A9292);
    const Color bgBase = Color(0xFFFEFEF1);
    const Color gradientTop = Color(0xFFFFC8);

    // Responsive sizes
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double fieldWidth = _computeFieldWidth(deviceWidth);
    // final double buttonWidth = _computeButtonWidth(deviceWidth);

    // Text scale factor for accessibility / small screens
    final double textScale = MediaQuery.of(
      context,
    ).textScaleFactor.clamp(1.0, 1.2);

    return Scaffold(
      // No appbar; back button will be placed in safe area
      body: Stack(
        children: [
          // Base color
          Container(color: bgBase),

          // Top gradient that covers 45% of the screen height
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientTop, bgBase],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Back button row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: primaryGreen,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Title - centered
                    Center(
                      child: Text(
                        'Login',
                        textScaleFactor: textScale,
                        style: const TextStyle(
                          fontFamily: 'Gotham',
                          fontSize: 45,
                          color: primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Animated fields & button group
                    SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            // Email field
                            SizedBox(
                              width: fieldWidth,
                              height: 50,
                              child: TextFormField(
                                controller: _emailCtrl,
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  hintStyle: const TextStyle(
                                    color: hintGray,
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(
                                      color: strokeGreen,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(
                                      color: primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Password field with eye toggle (no icon inside)
                            SizedBox(
                              width: fieldWidth,
                              height: 50,
                              child: TextFormField(
                                controller: _passCtrl,
                                validator: _validatePassword,
                                obscureText: _obscure,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(
                                    color: hintGray,
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(
                                      color: strokeGreen,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(
                                      color: primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey[700],
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Login button
                            SizedBox(
                              width: fieldWidth,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontFamily: 'Gotham',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        'Login',
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
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that provides hover (for web) and tap scale animation.
/// It scales down slightly on tap, and grows a bit on hover (web).
// Hover/tap animation removed with social-login UI.
class _HoverTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  // internal constants for animation (hover/tap) are defined in state
  const _HoverTapScale({required this.child, this.onTap});

  @override
  State<_HoverTapScale> createState() => _HoverTapScaleState();
}

class _HoverTapScaleState extends State<_HoverTapScale>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  bool _hovering = false;
  static const double _hoverScale = 1.06;
  static const double _tapScale = 0.92;
  static const Duration _duration = Duration(milliseconds: 120);

  void _onEnter(bool hover) {
    if (!mounted) return;
    setState(() {
      _hovering = hover;
      _scale = hover ? _hoverScale : 1.0;
    });
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _scale = _tapScale);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = _hovering ? _hoverScale : 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = _hovering ? _hoverScale : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _scale,
        duration: _duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    // Only use MouseRegion hover effects when running on web or desktop
    if (kIsWeb ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux) {
      return MouseRegion(
        onEnter: (_) => _onEnter(true),
        onExit: (_) => _onEnter(false),
        cursor: SystemMouseCursors.click,
        child: child,
      );
    }

    return child;
  }
}
