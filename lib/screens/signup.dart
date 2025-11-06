import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late AnimationController _controller;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xff9A9292)),
      prefixIcon: Icon(icon, color: const Color(0xff77C000)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xff77C000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xff77C000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xff099509), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fieldWidth = MediaQuery.of(context).size.width * 0.85;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.55, 1.0],
            colors: [Color(0xffFEFEF1), Color(0xffFFFFC8)],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xff099509)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontFamily: "Gotham",
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff099509),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [

                          // First Name
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              decoration: buildInputDecoration("First Name", Icons.person),
                              validator: (v) => v == null || v.isEmpty ? "Enter first name" : null,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Last Name
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              decoration: buildInputDecoration("Last Name", Icons.person_outline),
                              validator: (v) => v == null || v.isEmpty ? "Enter last name" : null,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: buildInputDecoration("Email", Icons.email),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Enter email";
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                  return "Enter valid email";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePass,
                              decoration: buildInputDecoration("Password", Icons.lock).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xff77C000),
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePass = !_obscurePass);
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Enter password";
                                if (v.length < 6) return "Min 6 characters";
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: buildInputDecoration("Confirm Password", Icons.lock).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xff77C000),
                                  ),
                                  onPressed: () {
                                    setState(() => _obscureConfirm = !_obscureConfirm);
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Confirm password";
                                if (v != _passwordController.text) return "Passwords do not match";
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Signup Button
                          SizedBox(
                            width: fieldWidth,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Signup Successful!")),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff099509),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: const Text(
                                "SIGN UP",
                                style: TextStyle(
                                  fontFamily: "Gotham",
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Social Icons
                          const Text("Or sign up with", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              FaIcon(FontAwesomeIcons.google, color: Color(0xff099509), size: 24),
                              SizedBox(width: 20),
                              FaIcon(FontAwesomeIcons.facebook, color: Color(0xff099509), size: 24),
                              SizedBox(width: 20),
                              FaIcon(FontAwesomeIcons.apple, color: Color(0xff099509), size: 24),
                            ],
                          )

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
