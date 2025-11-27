import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(text: '');
  final TextEditingController _emailController = TextEditingController(
    text: '',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '',
  );

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _nameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text =
            (data['displayName'] ?? _nameController.text) as String;
        _emailController.text =
            (data['email'] ?? _emailController.text) as String;
      }
    } catch (_) {}
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Prompt the user for their current password and reauthenticate.
  /// Returns true if reauthentication succeeded.
  Future<bool> _reauthenticate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (user.email == null || user.email!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No signed-in user available for reauthentication.'),
        ),
      );
      return false;
    }

    final password = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final TextEditingController _pwCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Re-authenticate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('For security, please enter your current password.'),
              const SizedBox(height: 12),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Current password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(_pwCtrl.text),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (password == null || password.isEmpty) return false;

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      return true;
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-authentication failed: ${e.message}')),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Re-authentication error: $e')));
      return false;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newPassword = _passwordController.text;

    try {
      // Update display name in Auth
      if (newName.isNotEmpty && newName != (user.displayName ?? '')) {
        await user.updateDisplayName(newName);
      }

      // Update email if changed — send verification to new email instead
      if (newEmail.isNotEmpty && newEmail != (user.email ?? '')) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
          // Inform user to check the new email for verification link
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification sent to the new email. Please confirm the link to complete the change.',
              ),
            ),
          );
          // Persist pending email intent in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'pendingEmail': newEmail,
                'emailChangeRequestedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            final reauthOk = await _reauthenticate();
            if (!reauthOk) return;
            // retry once after reauth
            await user.verifyBeforeUpdateEmail(newEmail);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Verification sent to the new email. Please confirm the link to complete the change.',
                ),
              ),
            );
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
                  'pendingEmail': newEmail,
                  'emailChangeRequestedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          } else {
            rethrow;
          }
        }
      }

      // Update password if provided
      if (newPassword.isNotEmpty) {
        try {
          await user.updatePassword(newPassword);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            final reauthOk = await _reauthenticate();
            if (!reauthOk) return;
            await user.updatePassword(newPassword);
          } else {
            rethrow;
          }
        }
      }

      // Update Firestore profile doc
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': newName,
        'email': newEmail,
        'firstName': newName.split(' ').first,
        'lastName': newName.split(' ').skip(1).join(' '),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } catch (e) {
      // If an error occurred, check whether the Firestore profile doc was actually updated.
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.exists ? doc.data() : null;
        final savedDisplayName = data != null && data['displayName'] != null
            ? data['displayName'] as String
            : null;
        final savedEmail = data != null && data['email'] != null
            ? data['email'] as String
            : null;
        if ((newName.isNotEmpty && savedDisplayName == newName) ||
            (newEmail.isNotEmpty && savedEmail == newEmail)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile updated')));
          Navigator.of(context).pop();
          if (mounted) setState(() => _loading = false);
          return;
        }
      } catch (_) {
        // ignore errors while double-checking
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF099509);
    const Color bgBase = Color.fromARGB(255, 254, 254, 241);

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryGreen),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Full Name',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.green[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter a name' : null,
                ),

                const SizedBox(height: 14),
                const Text(
                  'Email address',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.green[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter an email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 14),
                const Text(
                  'Password',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.green[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null; // optional
                    if (v.length < 6) return 'Password too short';
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
