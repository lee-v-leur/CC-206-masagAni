import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curve);
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    // start after a short delay for nicer entrance
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Please enter email';
    // Accept common emails; keep regex reasonably permissive but anchored
    final emailRegex = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,64}");
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter password';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v))
      return 'Include at least one uppercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Include at least one number';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    try {
      // Create user (this also signs the user in)
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid != null) {
        // Create or update a minimal user doc in Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': cred.user?.displayName ?? '',
        }, SetOptions(merge: true));

        // Send verification email if not verified
        if (!(cred.user?.emailVerified ?? false)) {
          try {
            await cred.user?.sendEmailVerification();
          } catch (_) {
            // ignore: non-fatal
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created — check your email.')),
      );

      // Navigate to home
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      final code = e.code;
      final msg = e.message ?? 'Signup failed';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup error [$code]: $msg')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCred.user;
      bool profileSaved = false;
      if (user != null) {
        final first = _firstNameController.text.trim();
        final last = _lastNameController.text.trim();
        final displayName = '$first $last'.trim();

        // Create user document in Firestore with profile fields
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'email': user.email,
                'firstName': first,
                'lastName': last,
                'displayName': displayName,
                'createdAt': FieldValue.serverTimestamp(),
              });
          profileSaved = true;
        } catch (e) {
          // If write reported an error, double-check whether the document exists
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            if (doc.exists) profileSaved = true;
          } catch (_) {
            // ignore
          }
        }

        // Update Firebase Auth profile displayName
        try {
          await user.updateDisplayName(displayName);
          await user.reload();
        } catch (_) {}

        // Attempt email verification (non-blocking)
        try {
          await user.sendEmailVerification();
        } catch (_) {}

        if (!mounted) return;
        if (profileSaved) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Signup successful!')));

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Signup created but profile save failed (please check permissions).',
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? 'Authentication error';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        // If an unexpected error happened, try to detect whether the user doc exists and surface success when appropriate
        try {
          final maybeUser = FirebaseAuth.instance.currentUser;
          if (maybeUser != null) {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(maybeUser.uid)
                .get();
            if (doc.exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signup successful')),
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
              return;
            }
          }
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Signup successful')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration buildInputDecoration(String hint, [IconData? icon]) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: Color(0xff9A9292),
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xff77C000))
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
    final double deviceWidth = MediaQuery.of(context).size.width;
    double fieldWidth;
    if (deviceWidth < 360)
      fieldWidth = deviceWidth * 0.85;
    else if (deviceWidth < 420)
      fieldWidth = deviceWidth * 0.78;
    else
      fieldWidth = 320;

    const Color primaryGreen = Color(0xFF099509);

    return Scaffold(
      body: Container(
        color: const Color(0xFFFEFEF1),
        child: Stack(
          children: [
            // top gradient area like login
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFC8), Color(0xFFFEFEF1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
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

                        Center(
                          child: Text(
                            'Sign Up',
                            style: const TextStyle(
                              fontFamily: 'Gotham',
                              fontSize: 45,
                              color: primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(height: 8),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: _firstNameController,
                                          decoration: buildInputDecoration(
                                            'First Name',
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? 'Enter first name'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: _lastNameController,
                                          decoration: buildInputDecoration(
                                            'Last Name',
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? 'Enter last name'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: buildInputDecoration(
                                            'Email',
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty)
                                              return 'Enter email';
                                            if (!RegExp(
                                              r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            ).hasMatch(v))
                                              return 'Enter valid email';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePass,
                                          decoration:
                                              buildInputDecoration(
                                                'Password',
                                              ).copyWith(
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePass
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    color: const Color(
                                                      0xff77C000,
                                                    ),
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _obscurePass =
                                                        !_obscurePass,
                                                  ),
                                                ),
                                              ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty)
                                              return 'Enter password';
                                            if (v.length < 6)
                                              return 'Min 6 characters';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: _obscureConfirm,
                                          decoration:
                                              buildInputDecoration(
                                                'Confirm Password',
                                              ).copyWith(
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscureConfirm
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    color: const Color(
                                                      0xff77C000,
                                                    ),
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _obscureConfirm =
                                                        !_obscureConfirm,
                                                  ),
                                                ),
                                              ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty)
                                              return 'Confirm password';
                                            if (v != _passwordController.text)
                                              return 'Passwords do not match';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      SizedBox(
                                        width: fieldWidth,
                                        child: ElevatedButton(
                                          onPressed: _loading
                                              ? null
                                              : () async {
                                                  if (!_formKey.currentState!
                                                      .validate())
                                                    return;
                                                  await _submit();
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryGreen,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'SIGN UP',
                                                  style: TextStyle(
                                                    fontFamily: 'Gotham',
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),

                                      const SizedBox(height: 36),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF099509);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: primaryGreen,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Create account'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
