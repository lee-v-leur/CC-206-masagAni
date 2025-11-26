import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'profile.dart';
import 'claim_history.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFEFEF1);
    const Color primaryGreen = Color(0xFF099509);

    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with back button and history icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: primaryGreen,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ClaimHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.history,
                      color: primaryGreen,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            
            // Rewards title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Rewards',
                    style: TextStyle(
                      color: Color(0xFF099509),
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _InfoIconWithTooltip(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rewards list: reactive to user's redeemed rewards/claims
            Expanded(
              child: Builder(
                builder: (context) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  // If not signed in, show static list (redeem will prompt sign-in)
                  if (uid == null) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _RewardCard(
                          iconAsset: 'assets/images/fertilizer_icon.png',
                          title: 'Fertilizer Voucher',
                          description:
                              'Receive 2 sacks (50 kg each) of complete fertilizer.',
                          points: 750,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RewardCard(
                          iconAsset: 'assets/images/seedling_icon.png',
                          title: 'Seedling Voucher',
                          description:
                              'Receive 10 bundles of ready-to-plant rice seedlings.',
                          descriptionSubtext: '(Available varieties may vary)',
                          points: 550,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RewardCard(
                          iconAsset: 'assets/images/pesticide_icon.png',
                          title: 'Pesticide Voucher',
                          description: 'Receive two 500ml Pesticide bottles.',
                          descriptionSubtext:
                              '(Available varieties may vary depending on the type of rice disease)',
                          points: 650,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RewardCard(
                          iconAsset: 'assets/images/healthkit_icon.png',
                          title: 'Health Kit Voucher',
                          description:
                              'Basic farmer health kit including first-aid supplies and PPE.',
                          descriptionSubtext:
                              '(Includes bandages, antiseptic, gloves, and mask)',
                          points: 400,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RewardCard(
                          iconAsset: 'assets/images/tools_icon.png',
                          title: 'Farm Tools Voucher',
                          description:
                              'Voucher redeemable for assorted small farm hand tools.',
                          descriptionSubtext:
                              '(Shovels, hoes, rakes — exact items may vary)',
                          points: 1200,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RewardCard(
                          iconAsset: 'assets/images/fuel_icon.png',
                          title: 'Fuel Voucher',
                          description:
                              'Fuel voucher valid for a set amount of pump fuel for farm use.',
                          descriptionSubtext:
                              '(Redeem at participating fuel depots)',
                          points: 300,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RewardCard(
                          iconAsset: 'assets/images/fungicide_icon.png',
                          title: 'Fungicide Voucher',
                          description:
                              'Receive one 1L bottle of approved fungicide for crop protection.',
                          descriptionSubtext:
                              '(Active ingredient depends on availability)',
                          points: 700,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RewardCard(
                          iconAsset: 'assets/images/soiltest_icon.png',
                          title: 'Soil Testing Voucher',
                          description:
                              'Professional soil test and nutrient analysis for one plot.',
                          descriptionSubtext:
                              '(Includes recommendations based on results)',
                          points: 500,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RewardCard(
                          iconAsset: 'assets/images/equipment_rental_icon.png',
                          title: 'Farm Equipment Rental Voucher',
                          description:
                              'Voucher credit towards short-term rental of farm equipment.',
                          descriptionSubtext:
                              '(Tractor/harvester rental subject to availability)',
                          points: 2000,
                          onRedeem: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  // Listen to both rewards and claims; hide vouchers that are already claimed
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('rewards')
                        .snapshots(),
                    builder: (context, rewardsSnap) {
                      if (rewardsSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final usedTitles = <String>{};
                      if (rewardsSnap.hasData) {
                        for (var d in rewardsSnap.data!.docs) {
                          final data = d.data() as Map<String, dynamic>;
                          if ((data['used'] ?? false) == true) {
                            usedTitles.add(data['title']?.toString() ?? '');
                          }
                        }
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('claims')
                            .snapshots(),
                        builder: (context, claimsSnap) {
                          if (claimsSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (claimsSnap.hasData) {
                            for (var d in claimsSnap.data!.docs) {
                              final data = d.data() as Map<String, dynamic>;
                              if (data['title'] != null)
                                usedTitles.add(data['title'].toString());
                            }
                          }

                          // Build list of vouchers but exclude those in usedTitles
                          final allVouchers = [
                            {
                              'icon': 'assets/images/fertilizer_icon.png',
                              'title': 'Fertilizer Voucher',
                              'description':
                                  'Receive 2 sacks (50 kg each) of complete fertilizer.',
                              'descriptionSubtext': null,
                              'points': 750,
                            },
                            {
                              'icon': 'assets/images/seedling_icon.png',
                              'title': 'Seedling Voucher',
                              'description':
                                  'Receive 10 bundles of ready-to-plant rice seedlings.',
                              'descriptionSubtext':
                                  '(Available varieties may vary)',
                              'points': 550,
                            },
                            {
                              'icon': 'assets/images/pesticide_icon.png',
                              'title': 'Pesticide Voucher',
                              'description':
                                  'Receive two 500ml Pesticide bottles.',
                              'descriptionSubtext':
                                  '(Available varieties may vary depending on the type of rice disease)',
                              'points': 650,
                            },
                            {
                              'icon': 'assets/images/healthkit_icon.png',
                              'title': 'Health Kit Voucher',
                              'description':
                                  'Basic farmer health kit including first-aid supplies and PPE.',
                              'descriptionSubtext':
                                  '(Includes bandages, antiseptic, gloves, and mask)',
                              'points': 400,
                            },
                            {
                              'icon': 'assets/images/tools_icon.png',
                              'title': 'Farm Tools Voucher',
                              'description':
                                  'Voucher redeemable for assorted small farm hand tools.',
                              'descriptionSubtext':
                                  '(Shovels, hoes, rakes — exact items may vary)',
                              'points': 1200,
                            },
                            {
                              'icon': 'assets/images/fuel_icon.png',
                              'title': 'Fuel Voucher',
                              'description':
                                  'Fuel voucher valid for a set amount of pump fuel for farm use.',
                              'descriptionSubtext':
                                  '(Redeem at participating fuel depots)',
                              'points': 300,
                            },
                            {
                              'icon': 'assets/images/fungicide_icon.png',
                              'title': 'Fungicide Voucher',
                              'description':
                                  'Receive one 1L bottle of approved fungicide for crop protection.',
                              'descriptionSubtext':
                                  '(Active ingredient depends on availability)',
                              'points': 700,
                            },
                            {
                              'icon': 'assets/images/soiltest_icon.png',
                              'title': 'Soil Testing Voucher',
                              'description':
                                  'Professional soil test and nutrient analysis for one plot.',
                              'descriptionSubtext':
                                  '(Includes recommendations based on results)',
                              'points': 500,
                            },
                            {
                              'icon': 'assets/images/equipment_rental_icon.png',
                              'title': 'Farm Equipment Rental Voucher',
                              'description':
                                  'Voucher credit towards short-term rental of farm equipment.',
                              'descriptionSubtext':
                                  '(Tractor/harvester rental subject to availability)',
                              'points': 2000,
                            },
                          ];

                          final available = allVouchers
                              .where((v) => !usedTitles.contains(v['title']))
                              .toList();

                          if (available.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Available Rewards',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'You have no available rewards to redeem at the moment.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: available.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final v = available[index];
                              return _RewardCard(
                                iconAsset: v['icon'] as String,
                                title: v['title'] as String,
                                description: v['description'] as String,
                                descriptionSubtext:
                                    v['descriptionSubtext'] as String?,
                                points: v['points'] as int,
                                onRedeem: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileScreen(),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
            
            const SizedBox(height: 24),
            
            // Rewards list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Fertilizer Voucher Card
                  _RewardCard(
                    iconAsset: 'assets/images/fertilizer_icon.png',
                    title: 'Fertilizer Voucher',
                    description: 'Receive 2 sacks (50 kg each) of complete fertilizer.',
                    points: 750,
                    onRedeem: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Seedling Voucher Card
                  _RewardCard(
                    iconAsset: 'assets/images/seedling_icon.png',
                    title: 'Seedling Voucher',
                    description: 'Receive 10 bundles of ready-to-plant rice seedlings.',
                    descriptionSubtext: '(Available varieties may vary)',
                    points: 550,
                    onRedeem: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String description;
  final String? descriptionSubtext;
  final int points;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.iconAsset,
    required this.title,
    required this.description,
    this.descriptionSubtext,
    required this.points,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardBorder = Color(0xFFE8D78C);

    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEF1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 2),
        border: Border.all(
          color: cardBorder,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.card_giftcard,
              color: Colors.orange[700],
              size: 32,
            ),
          ),

          const SizedBox(width: 12),

          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and points
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005300),
                        ),
                      ),
                    ),
                    Text(
                      'Agri Points: $points',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF099509),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                
                const SizedBox(height: 6),
                
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),

                
                if (descriptionSubtext != null) ...[
                  Text(
                    descriptionSubtext!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                
                const SizedBox(height: 12),
                
                // Redeem button
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Prevent duplicate active reward codes: check for existing unused reward with same title
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to redeem'),
                          ),
                        );
                        return;
                      }

                      String? existingCode;
                      try {
                        final qs = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('rewards')
                            .where('title', isEqualTo: title)
                            .where('used', isEqualTo: false)
                            .limit(1)
                            .get();
                        if (qs.docs.isNotEmpty) {
                          // return a full document path so server can find it later
                          existingCode =
                              'users/${user.uid}/rewards/${qs.docs.first.id}';
                        }
                      } catch (_) {
                        // ignore query errors; fallback to creating a new code in dialog
                      }

                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withOpacity(0.5),
                        builder: (context) => _RedeemDialog(
                          title: title,
                          points: points,
                          existingCode: existingCode,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(
                        color: Color(0xFF005300),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Redeem',
                      style: TextStyle(
                        color: Color(0xFF005300),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

class _InfoIconWithTooltip extends StatefulWidget {
  @override
  State<_InfoIconWithTooltip> createState() => _InfoIconWithTooltipState();
}

class _InfoIconWithTooltipState extends State<_InfoIconWithTooltip> {
  bool _showTooltip = false;
  final GlobalKey _iconKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    const Color textGreen = Color(0xFF099509);

    
    return GestureDetector(
      key: _iconKey,
      onTap: () {
        if (_showTooltip) {
          setState(() {
            _showTooltip = false;
          });
        } else {
          setState(() {
            _showTooltip = true;
          });

          // Show overlay
          final RenderBox renderBox =
              _iconKey.currentContext!.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);

          
          // Show overlay
          final RenderBox renderBox = _iconKey.currentContext!.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);
          
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            barrierDismissible: true,
            builder: (context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _showTooltip = false;
                  });
                },
                child: Stack(
                  child: Stack(
                  children: [
                    Positioned(
                      top: position.dy + 28,
                      left: position.dx - 82.5,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 185,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F0),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'How It Works:',
                                style: TextStyle(
                                  color: textGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '1. Tap Redeem to get your QR code.',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '2. Visit the nearest Department of Agriculture office.',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '3. Show your QR code to the staff to claim your rewards.',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ).then((_) {
            setState(() {
              _showTooltip = false;
            });
          });
        }
      },
      child: Icon(
        Icons.info_outline,
        color: Color(0xFF557955).withOpacity(0.66),
        size: 20,
      ),
    );
  }
}

class _RedeemDialog extends StatelessWidget {
  final String title;
  final int points;
  final String? existingCode;

  const _RedeemDialog({
    required this.title,
    required this.points,
    this.existingCode,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF005300);
    const Color lightGreen = Color(0xFF099509);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FutureBuilder<String>(
        future: existingCode != null
            ? Future.value(existingCode)
            : _createRewardCode(title, points),
        builder: (context, snap) {
          Widget body;
          if (snap.connectionState == ConnectionState.waiting) {
            body = SizedBox(
              width: 260,
              height: 320,
              child: const Center(child: CircularProgressIndicator()),
            );
          } else if (snap.hasError) {
            final err = snap.error.toString();
            final isPermission =
                err.toLowerCase().contains('permission-denied') ||
                err.toLowerCase().contains('not-authorized');
            final message = isPermission
                ? 'Permission denied when writing to Firestore.\n\nPossible fixes:\n• Make sure you are signed in.\n• Update Firestore rules to allow authenticated users to create documents under `users/{uid}/rewards` where `request.auth.uid == uid`.\n• For local testing, use the Firestore emulator or temporarily relax rules (not for production).'
                : 'Failed to generate code: $err';

            body = SizedBox(
              width: 300,
              height: 320,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          } else if (!snap.hasData) {
            body = SizedBox(
              width: 260,
              height: 320,
              child: const Center(child: Text('Could not generate code.')),
            );
          } else {
            final code = snap.data!;
            body = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 320,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Container(
                width: 286,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2FFB4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF2DE62D).withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Redeem',
                        style: TextStyle(
                          color: darkGreen,
                          fontSize: 26.67,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        title,
                        style: const TextStyle(
                          color: lightGreen,
                          fontSize: 13.33,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      Text(
                        '$points Agri Points',
                        style: const TextStyle(
                          color: lightGreen,
                          fontSize: 10.67,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // QR Code
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 180,
                            height: 180,
                            child: QrImageView(data: code, size: 180),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Show this QR to staff to claim.',
                        style: const TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // DONE button: marks reward used and creates a claim record
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // perform transaction to mark reward as used and create claim
                            try {
                              // show a progress dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              await _redeemReward(context, code, title, points);

                              // close progress dialog and redeem dialog
                              Navigator.of(context).pop(); // close progress
                              Navigator.of(
                                context,
                              ).pop(); // close redeem dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Voucher redeemed and added to history.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              // close progress dialog if open
                              try {
                                Navigator.of(context).pop();
                              } catch (_) {}
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Redeem failed'),
                                  content: Text(e.toString()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return body;
        },
      ),
    );
  }

  Future<String> _createRewardCode(String title, int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      throw Exception('Not signed in. Please sign in to redeem rewards.');

    final base = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      // create a doc and use its id as the code (random doc id)
      final docRef = base.collection('rewards').doc();
      final code = docRef.id;
      final now = DateTime.now();
      await docRef.set({
        'ownerUid': user.uid,
        'code': code,
        'title': title,
        'points': points,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 7))),
        'used': false,
      });
      // return the full document path as the QR payload
      return 'users/${user.uid}/rewards/$code';
    } catch (e) {
      // surface the underlying error so the UI can show it
      throw Exception('Failed to create reward code: $e');
    }
  }

  Future<void> _redeemReward(
    BuildContext context,
    String docPath,
    String title,
    int points,
  ) async {
    final firestore = FirebaseFirestore.instance;

    // Validate path: expected users/{uid}/rewards/{id}
    final segments = docPath.split('/');
    if (segments.length != 4 ||
        segments[0] != 'users' ||
        segments[2] != 'rewards') {
      throw Exception('Invalid reward document path: $docPath');
    }

    final rewardRef = firestore.doc(docPath);

    try {
      await firestore.runTransaction((tx) async {
        final snap = await tx.get(rewardRef);
        if (!snap.exists) throw Exception('Reward not found');
        final data = snap.data() as Map<String, dynamic>;
        if ((data['used'] ?? false) == true)
          throw Exception('This voucher was already used.');

        // ensure user has enough points, decrement totalPoints atomically
        final userId = segments[1];
        final userRef = firestore.collection('users').doc(userId);
        final userSnap = await tx.get(userRef);
        final currentPoints =
            (userSnap.exists &&
                (userSnap.data() as Map<String, dynamic>)['totalPoints'] !=
                    null)
            ? (userSnap.data() as Map<String, dynamic>)['totalPoints'] as int
            : 0;
        final redeemPoints = (data['points'] ?? points) as int;
        if (currentPoints < redeemPoints) {
          throw Exception('Insufficient Agri Points to redeem this voucher.');
        }

        // decrement user's totalPoints
        tx.update(userRef, {
          'totalPoints': FieldValue.increment(-redeemPoints),
        });

        // mark reward used and set redeemedAt (server timestamp)
        tx.update(rewardRef, {
          'used': true,
          'redeemedAt': FieldValue.serverTimestamp(),
        });

        // create claim under users/{uid}/claims/{autoId}
        final claimRef = firestore
            .collection('users')
            .doc(userId)
            .collection('claims')
            .doc();
        tx.set(claimRef, {
          'title': data['title'] ?? title,
          'description': data['description'] ?? '',
          'points': redeemPoints,
          'rewardRef': docPath,
          'redeemedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // Bubble up error for UI handling
      throw Exception('Redeem transaction failed: $e');
    }
  }
    const Color scanMeColor = Color(0xFF6B976B);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 286,
        height: 357,
        decoration: BoxDecoration(
          color: const Color(0xFFE2FFB4),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF2DE62D).withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'Redeem',
              style: TextStyle(
                color: darkGreen,
                fontSize: 26.67,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Reward name
            Text(
              title,
              style: const TextStyle(
                color: lightGreen,
                fontSize: 13.33,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            
            // Points
            Text(
              '$points Agri Points',
              style: const TextStyle(
                color: lightGreen,
                fontSize: 10.67,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // QR Code placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_2,
                    size: 150,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan Me',
                    style: TextStyle(
                      color: scanMeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
