// lib/screens/login.dart
import 'package:flutter/material.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _animController;
  late Animation<Offset> _fieldsOffsetAnim;
  late Animation<double> _fieldsFadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    final curve = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fieldsOffsetAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(curve);
    _fieldsFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

    // start animation shortly after push (delay for nicer effect)
    Timer(const Duration(milliseconds: 80), () {
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

  // Password rule 2: at least 8 chars, 1 number, 1 uppercase
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasDigit = value.contains(RegExp(r'\d'));
    if (!hasUpper) return 'Include at least one uppercase letter';
    if (!hasDigit) return 'Include at least one number';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter email';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // replace with real auth flow
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logging in...')),
      );
      // TODO: call auth API
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizes
    final w = MediaQuery.of(context).size.width;
    // scale widths to device width; keep buttons same as welcome on larger screens
    final fieldWidth = (w < 360) ? w * 0.85 : 300.0;
    final buttonWidth = (w < 360) ? w * 0.66 : 220.0;

    return Scaffold(
      // Background: base #FEFEF1 and a top gradient that covers 45% of screen.
      body: Stack(
        children: [
          Container(color: const Color(0xFFFEFEF1)),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFC8), Color(0xFFFEFEF1)],
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
                          color: const Color(0xFF099509),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Center(
                      child: Text(
                        'Login',
                        style: const TextStyle(
                          fontFamily: 'Gotham',
                          fontSize: 45,
                          color: Color(0xFF099509),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Animated fields container
                    SlideTransition(
                      position: _fieldsOffsetAnim,
                      child: FadeTransition(
                        opacity: _fieldsFadeAnim,
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
                                    color: Color(0xFF9A9292),
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(color: Color(0xFF77C000)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(color: Color(0xFF099509), width: 2),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Password field with toggle
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
                                    color: Color(0xFF9A9292),
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(color: Color(0xFF77C000)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(color: Color(0xFF099509), width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey[700],
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Login button
                            SizedBox(
                              width: buttonWidth,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF099509).withOpacity(0.75),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Text(
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

                    // Flexible spacer so social icons stay near bottom
                    const Spacer(),

                    // Social login label
                    const Text(
                      'Or login with',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF9A9292),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Social icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon(Icons.g_mobiledata),
                        _socialIcon(Icons.facebook),
                        _socialIcon(Icons.apple),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Icon(icon, color: Colors.black, size: 22),
      ),
    );
  }
}
