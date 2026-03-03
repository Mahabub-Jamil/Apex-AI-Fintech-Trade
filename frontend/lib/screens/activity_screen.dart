import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class ActivityScreen extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        final user = authController.user.value;
        if (user == null) return const Center(child: Text("Not authenticated."));

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(user.uid)
              .collection('trades')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading history.\n${snapshot.error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            }
            
            final trades = snapshot.data?.docs ?? [];
            if (trades.isEmpty) {
              return const Center(
                child: Text(
                  'No trades executed yet.\nUse the Portfolio tab to mock trade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: trades.length,
              itemBuilder: (context, index) {
                final trade = trades[index].data() as Map<String, dynamic>;
                final bool isBuy = trade['side'] == 'BUY';
                final String symbol = trade['assetSymbol'] ?? 'UNK';
                final double amount = (trade['amount'] as num).toDouble();
                final double priceAtTrade = (trade['priceAtTrade'] as num).toDouble();
                final double totalValue = amount * priceAtTrade;
                
                DateTime? date;
                if (trade['timestamp'] != null) {
                  date = (trade['timestamp'] as Timestamp).toDate();
                } else {
                  date = DateTime.now();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isBuy ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2),
                              child: Icon(
                                isBuy ? Icons.arrow_downward : Icons.arrow_upward, 
                                color: isBuy ? AppTheme.success : AppTheme.error
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${isBuy ? 'Bought' : 'Sold'} $symbol', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(DateFormat('MMM d, y • h:mm a').format(date), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isBuy ? '-' : '+'}\$${totalValue.toStringAsFixed(2)}', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                            ),
                            Text(
                              '${amount.toStringAsFixed(4)} @ \$${priceAtTrade.toStringAsFixed(2)}', 
                              style: const TextStyle(color: Colors.white54, fontSize: 12)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}
