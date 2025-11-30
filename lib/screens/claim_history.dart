import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClaimHistoryScreen extends StatelessWidget {
  const ClaimHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFEFEF1);
    const Color primaryGreen = Color(0xFF099509);

    final uid = FirebaseAuth.instance.currentUser?.uid;

    
    // TODO: Replace with actual redeemed vouchers from database
    final List<Map<String, dynamic>> redeemedVouchers = [];
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with back button
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
                ],
              ),
            ),

            
            // Claim History title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'History',
                style: TextStyle(
                  color: Color(0xFF099509),
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content: show user's claim history (created by trusted server/function)
            Expanded(
              child: uid == null
            
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: redeemedVouchers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Not signed in',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                            Text(
                              'No Redeemed Vouchers Yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to view your redeemed vouchers.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                            Text(
                              'You haven\'t redeemed any vouchers yet. Start earning Agri Points and redeem your first reward!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('claims')
                          .orderBy('redeemedAt', descending: true)
                          .snapshots(includeMetadataChanges: true),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snap.hasData || snap.data!.docs.isEmpty) {
                          // Fallback: show rewards where used == true
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('rewards')
                                .where('used', isEqualTo: true)
                                .orderBy('createdAt', descending: true)
                                .snapshots(includeMetadataChanges: true),
                            builder: (context, s2) {
                              if (s2.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!s2.hasData || s2.data!.docs.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 80,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No Redeemed Vouchers Yet',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'You haven\'t redeemed any vouchers yet. Start earning Agri Points and redeem your first reward!',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final docs = s2.data!.docs;
                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: docs.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final d =
                                      docs[index].data()
                                          as Map<String, dynamic>;
                                  final redeemedAt =
                                      (d['redeemedAt'] as Timestamp?)?.toDate();
                                  return _RedeemedVoucherCard(
                                    title: d['title'] ?? 'Reward',
                                    description: d['title'] ?? '',
                                    descriptionSubtext:
                                        d['descriptionSubtext'] as String?,
                                    points: (d['points'] ?? 0) as int,
                                    redeemedDate: redeemedAt != null
                                        ? redeemedAt.toLocal().toString()
                                        : '',
                                  );
                                },
                              );
                            },
                          );
                        }

                        final docs = snap.data!.docs;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: docs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final d =
                                docs[index].data() as Map<String, dynamic>;
                            final redeemedAt = (d['redeemedAt'] as Timestamp?)
                                ?.toDate();
                            return _RedeemedVoucherCard(
                              title: d['title'] ?? 'Reward',
                              description: d['title'] ?? '',
                              descriptionSubtext: d['description'] as String?,
                              points: (d['points'] ?? 0) as int,
                              redeemedDate: redeemedAt != null
                                  ? redeemedAt.toLocal().toString()
                                  : '',
                            );
                          },
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: redeemedVouchers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final voucher = redeemedVouchers[index];
                        return _RedeemedVoucherCard(
                          title: voucher['title'] as String,
                          description: voucher['description'] as String,
                          descriptionSubtext: voucher['descriptionSubtext'] as String?,
                          points: voucher['points'] as int,
                          redeemedDate: voucher['redeemedDate'] as String,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedeemedVoucherCard extends StatelessWidget {
  final String title;
  final String description;
  final String? descriptionSubtext;
  final int points;
  final String redeemedDate;

  const _RedeemedVoucherCard({
    required this.title,
    required this.description,
    this.descriptionSubtext,
    required this.points,
    required this.redeemedDate,
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

                const SizedBox(height: 8),

               
                
                // Redeemed date
                Text(
                  'Redeemed on $redeemedDate',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),

                
                const SizedBox(height: 12),
                
                // Redeemed button (disabled)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Redeemed',
                      style: TextStyle(
                        color: Colors.white,
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
