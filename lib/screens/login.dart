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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
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

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFFFEFEF1),
        title: const Text('Reset password'),
        titleTextStyle: TextStyle(
          color: const Color(0xFF018D01),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the email for your account. We will send a password reset link.',
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 0, 0),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: const Color(0xFFEFF7EE),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: const Color(0xFF018D01)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              final err = _validateEmail(email);
              if (err != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err)));
                return;
              }
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset email sent. Check your inbox.',
                      ),
                    ),
                  );
                }
                Navigator.of(ctx).pop(true);
              } on FirebaseAuthException catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.message}')),
                  );
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unexpected error: $e')),
                  );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF018D01),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    emailCtrl.dispose();
    return;
  }

  Future<void> _submit() async {
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
        // show terms overlay before proceeding to loading/home
        await _showTermsOverlay(firstName);
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

  Future<void> _showTermsOverlay(String firstName) async {
    bool acceptTerms = false;
    bool acceptData = false;
    bool acknowledgeAlgo = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF77C000)),
            ),
            padding: const EdgeInsets.all(14),
            child: StatefulBuilder(
              builder: (contextSB, setStateSB) {
                return ConstrainedBox(
                  // Narrower width to resemble small redeem/reward container
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: const TextStyle(
                            fontFamily: 'Gotham',
                            color: Color(0xFF099509),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Please review and accept the following before continuing. The app stores symptom logs, timestamps, and account data to provide reminders and diagnostic suggestions. Suggestions are advisory; verify with local government officers when needed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ',
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),

                        ConstrainedBox(
                          // Lower max height so dialog appears compact
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '1. ACCEPTANCE AND SCOPE',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
By downloading, registering for, or using the MasagAni mobile application, you agree to be bound by these Terms and Conditions. The Application is provided by the MasagAni developers to assist rice farmers, cooperatives, and agricultural agencies in monitoring and managing Brown Spot Disease, Sheath Blight, and Rice Yellowing Syndrome. These terms govern your access and use of the application, including all content, functionality, reading materials, reminders, symptom journaling, the symptom-checklist diagnosis algorithm, reward programs, and related services. If you do not agree with these Terms, you must not use the Application. MasagAni reserves the right to modify these Terms at any time. Modifications become effective upon posting within the Application. Your continued use following such changes constitutes acceptance of the revised Terms.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '2. USER REGISTRATION AND ELIGIBILITY',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
To access certain Application features, you must register and maintain an account. You represent and warrant that all information provided during registration is accurate, current, and complete, and that you are at least eighteen years of age or the age of legal majority in your jurisdiction. You further warrant that you are authorized to use the contact details provided and possess the legal capacity to enter into this binding agreement. If registering on behalf of an organization, cooperative, or government entity, you represent that you have the requisite authority to bind such entity to these terms.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '3. ACCOUNT SECURITY AND USER RESPONSIBILITIES',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
You are solely responsible for maintaining the confidentiality of your account credentials, including username, password, personal identification number, and biometric authentication data. You agree to notify MasagAni immediately upon discovering any unauthorized use or security breach related to your account. You accept full responsibility for all activity occurring under your account, whether authorized by you or not. MasagAni shall not be held liable for any loss, damage, or unauthorized activity resulting from your failure to maintain account security or from unauthorized access due to your negligence.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '4. PROHIBITED CONDUCT',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
You agree to ensure that your use of the application complies with all applicable laws and agricultural regulations. You shall not:

• Submit false, misleading, inaccurate, or fraudulent information;
• Impersonate any person, entity, or official;
• Post offensive, defamatory, harassing, or unlawful content;
• Use the application for unauthorized commercial purposes without prior written consent from MasagAni;
• Engage in activity that disrupts or interferes with the Application's proper functioning;
• Attempt unauthorized access to the Application, other users' accounts, or connected systems;
• Use automated scripts, bots, or crawlers to access or extract data without permission;
• Circumvent security measures or attempt to extract diagnostic models or algorithms.

MasagAni reserves the right to suspend or terminate your account immediately if you violate these terms or engage in conduct deemed harmful or inappropriate.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '5. SYMPTOM JOURNAL AND ALGORITHMIC DIAGNOSIS',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
The Application offers a symptom journal and a symptom-checklist diagnosis algorithm that analyzes checklist entries and suggests likely diseases and observation timelines based on diagnostic rules and training data. The Algorithm operates using pre-defined diagnostic rules, decision trees, symptom correlation matrices, and historical training data derived from agricultural research and expert agronomic knowledge.

THESE SUGGESTIONS ARE ADVISORY ONLY AND DO NOT SUBSTITUTE FOR PROFESSIONAL AGRONOMIC CONSULTATION OR LABORATORY INSPECTION.

The Algorithm is a decision-support tool designed to augment, not replace, the judgment and expertise of qualified agricultural professionals, including field technicians, plant pathologists, extension officers, and licensed agronomists.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '6. ACCURACY LIMITATIONS AND USER VERIFICATION',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
MasagAni does not guarantee the accuracy, completeness, reliability, or timeliness of algorithm-generated suggestions. The Algorithm's performance may be affected by incomplete or ambiguous user input, limitations in training data, rare or emerging disease strains, environmental factors, nutrient deficiencies, pest damage, technical errors, or software bugs.
You must confirm all significant crop-health decisions with qualified field technicians, extension officers, or authorized agricultural services. You acknowledge that reliance on the Application's suggestions without independent professional verification is at your own risk.
MasagAni expressly disclaims any liability for losses, crop failures, reduced yields, financial damages, or other harm resulting from reliance on the Application's diagnostic outputs without independent verification.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '7. DATA COLLECTION, USE, AND STORAGE',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
By using the application, you consent to the collection, storage, and processing of data you submit, including journal entries, images, symptom selections, account information, device identifiers, IP addresses, and usage metrics. Data is stored using secure cloud services such as Google Firebase and Firestore and may be used to:

• Provide, maintain, and improve Application features and functionality;
• Generate diagnostic outputs, reminders, and personalized recommendations;
• Conduct research and enhance the Algorithm's accuracy and performance;
• Produce aggregated analytics for research purposes and agricultural planning;
• Support partnerships with local cooperatives and government agencies;
• Monitor compliance with these Terms and detect fraudulent activity.

MasagAni implements reasonable security measures to protect your data but cannot guarantee absolute security. You acknowledge that no method of electronic transmission or storage is completely secure.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '8. DATA SHARING AND PRIVACY',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
Personal data will not be sold to third parties. Aggregated or de-identified data that does not personally identify individual users may be shared with government agencies, research institutions, academic partners, and agricultural cooperatives for research, policy development, and program improvement. MasagAni may disclose personal data if required by law, court order, governmental request, or to protect the rights, property, or safety of MasagAni, its users, or the public. You retain ownership of content you upload but grant MasagAni a non-exclusive, royalty-free, worldwide, perpetual, irrevocable license to use, reproduce, modify, display, and create derivative works from such content for purposes related to the Application's operation and improvement. You warrant that you have all necessary rights and permissions to upload such content and that it does not infringe upon third-party rights. For detailed information on data retention, access rights, correction procedures, and deletion requests, consult the Application's Privacy Policy, which is incorporated herein by reference.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '9. REWARDS, REDEMPTION, AND FAIR USE',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
The Application may offer rewards, credits, vouchers, daily check-in systems, streak bonuses, and achievement programs to encourage user engagement. Rewards are subject to terms posted within the Application and availability through local partners such as cooperatives, local government units, and Department of Agriculture offices. Rewards earned through the Application are non-transferable unless explicitly stated, have no cash value, and may be subject to verification or redemption conditions including partner approval, identity verification, and minimum redemption thresholds. Rewards may have expiration dates, usage restrictions, and geographic limitations as specified within the Application. MasagAni reserves the right to suspend, revoke, or withhold rewards if fraudulent activity, manipulation, abuse of the rewards system, creation of multiple accounts, use of automated scripts, or violation of these Terms is detected. Such decisions are made at MasagAni's sole discretion and are final. Redemption partners may impose additional terms, conditions, or documentation requirements. Local redemption rules, partner availability, and inventory are subject to change. MasagAni is not liable for partner-level decisions, supply shortages, inventory limitations, delays in fulfillment, or disputes between users and redemption partners.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '10. INTELLECTUAL PROPERTY AND LICENSING',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
All Application content, including text, images, graphics, photographs, educational resources, user interface design, diagnostic algorithms, software code, database structures, trademarks, service marks, and logos, is the exclusive property of MasagAni or its licensors and is protected by copyright, trademark, patent, and other intellectual property laws of the Philippines and international treaties. You are granted a limited, non-exclusive, non-transferable, revocable license to use the Application for personal, non-commercial agricultural purposes only. This license does not grant you any ownership rights, title, or interest in the Application or its content. All rights not expressly granted herein are reserved by MasagAni. You may not reproduce, distribute, publicly display, modify, reverse-engineer, decompile, disassemble, create derivative works from, or otherwise exploit the Application or its content except as expressly permitted by these Terms. You shall not remove or alter any copyright notices, trademarks, or proprietary designations. Violations may result in immediate account termination and legal action. MasagAni reserves the right to pursue all available legal remedies, including injunctive relief, monetary damages, and recovery of attorneys' fees, under the Intellectual Property Code of the Philippines and applicable international laws.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '11. DISCLAIMERS AND WARRANTIES',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """
To the maximum extent permitted by law, MasagAni disclaims all warranties, including but not limited to:

• Implied warranties of merchantability, fitness for a particular purpose, title, and non-infringement;
• Warranties regarding accuracy, reliability, completeness, timeliness, security, or quality of the Application or its diagnostic outputs;
• Warranties that the Application will be uninterrupted, error-free, virus-free, or free from harmful components;
• Warranties that defects or errors will be corrected or that the application will meet your specific requirements.

MasagAni does not warrant the availability, accuracy, or reliability of diagnostic suggestions, educational content, or any information provided through the application.
                                    """,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '12. LIMITATION OF LIABILITY, INDEMNIFICATION, AND GOVERNING LAW',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      """

TO THE MAXIMUM EXTENT PERMITTED BY LAW, MASAGANI AND ITS OFFICERS, EMPLOYEES, AGENTS, AND AFFILIATES SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS, CROPS, REVENUE, DATA, BUSINESS OPPORTUNITIES, GOODWILL, OR ANTICIPATED SAVINGS, ARISING FROM YOUR USE OF OR INABILITY TO USE THE APPLICATION, DIAGNOSTIC OUTPUTS, REMINDERS, OR REWARDS, WHETHER BASED ON CONTRACT, TORT, NEGLIGENCE, STRICT LIABILITY, BREACH OF WARRANTY, OR ANY OTHER LEGAL THEORY, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

• In jurisdictions where liability cannot be excluded, MasagAni's total aggregate liability for all claims arising from these Terms or your use of the Application shall be limited to the lesser of actual direct damages proven with reasonable certainty or the equivalent of one hundred United States Dollars or its local currency equivalent.

• You agree to indemnify, defend, and hold harmless MasagAni, its officers, directors, employees, agents, and affiliates from any claims, demands, actions, damages, losses, liabilities, costs, and expenses, including reasonable attorneys' fees, arising from your use or misuse of the application, violation of these terms, submission of false or unlawful content, or infringement of third-party rights.

• These Terms are governed by the laws of the Republic of the Philippines without regard to conflict of law principles. Any disputes arising from these Terms or the application shall be instituted exclusively in courts of competent jurisdiction in the Philippines. You consent to the personal jurisdiction of such courts and waive any objection to venue.

• Prior to initiating legal proceedings, parties agree to attempt informal resolution by contacting MasagAni and providing a detailed description of the dispute. If resolution is not achieved within thirty days, either party may pursue formal remedies.

• If any provision of these Terms is found invalid, illegal, or unenforceable, that provision shall be modified to the minimum extent necessary or severed, and the remaining provisions shall remain in full force and effect. No waiver by MasagAni of any breach shall be deemed a waiver of any subsequent breach.
""",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        CheckboxListTile(
                          value: acceptTerms,
                          onChanged: (v) =>
                              setStateSB(() => acceptTerms = v ?? false),
                          title: const Text(
                            'I accept the Terms & Conditions',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              height: 1.0,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF018D01),
                        ),
                        CheckboxListTile(
                          value: acceptData,
                          onChanged: (v) =>
                              setStateSB(() => acceptData = v ?? false),
                          title: const Text(
                            'I consent to data storage and processing as described',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              height: 1.0,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF018D01),
                        ),
                        CheckboxListTile(
                          value: acknowledgeAlgo,
                          onChanged: (v) =>
                              setStateSB(() => acknowledgeAlgo = v ?? false),
                          title: const Text(
                            'I understand diagnostic suggestions are algorithmic and advisory',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              height: 1.0,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF018D01),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                try {
                                  await FirebaseAuth.instance.signOut();
                                } catch (_) {}
                                if (mounted) Navigator.of(ctx).pop();
                              },
                              child: const Text(
                                'Decline',
                                style: TextStyle(color: Color(0xFF099509)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  (acceptTerms && acceptData && acknowledgeAlgo)
                                  ? () {
                                      Navigator.of(ctx).pop();
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => LoadingScreen(
                                            firstName: firstName,
                                            durationMillis: 3000,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF018D01),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Social-login removed; no helper needed.

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

                            const SizedBox(height: 12),

                            // Forgot password (right-aligned subtle link)
                            SizedBox(
                              width: fieldWidth,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _forgotPassword,
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: hintGray,
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

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
