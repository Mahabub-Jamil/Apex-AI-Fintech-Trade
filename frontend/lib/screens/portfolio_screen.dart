import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/trade_bottom_sheet.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Apex-Nexus Portfolio Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Total Balance: \$14,234.56', style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 40),
                pw.Text('Asset Allocation:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Bitcoin (BTC): 40%'),
                pw.Text('Ethereum (ETH): 30%'),
                pw.Text('Solana (SOL): 15%'),
                pw.Text('USDC: 15%'),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Apex_Nexus_Portfolio_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Export PDF Report',
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => _showAdjustBalanceDialog(context),
            tooltip: 'Adjust Account Balance',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Asset Holdings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Obx(() {
              final authController = Get.find<AuthController>();
              final dashboardController = Get.find<DashboardController>();
              final holdings = authController.firestoreUserData['holdings'] ?? {};
              
              if (holdings.isEmpty) {
                return GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: const Center(child: Text("You don't own any assets yet.", style: TextStyle(color: Colors.white54))),
                );
              }

              List<Widget> assetWidgets = [];
              
              // Calculate total assets value in USD (excluding cash balance)
              double totalPortfolioValue = 0.0;
              holdings.forEach((key, value) {
                String symbol = key.toString().toUpperCase();
                double amount = value is Map ? ((value['amount'] ?? 0.0) as num).toDouble() : (value as num).toDouble();
                if (amount > 0) {
                  var coinData = dashboardController.marketData.firstWhere(
                     (coin) => coin['symbol'].toString().toUpperCase() == symbol || coin['id'].toString().toUpperCase() == symbol,
                     orElse: () => null
                  );
                  if (coinData != null) {
                    double currentPrice = (coinData['current_price'] as num).toDouble();
                    totalPortfolioValue += (amount * currentPrice);
                  }
                }
              });
              
              holdings.forEach((key, value) {
                String symbol = key.toString().toUpperCase();
                double amount = value is Map ? ((value['amount'] ?? 0.0) as num).toDouble() : (value as num).toDouble();
                
                if (amount > 0) {
                  var coinData = dashboardController.marketData.firstWhere(
                     (coin) => coin['symbol'].toString().toUpperCase() == symbol || coin['id'].toString().toUpperCase() == symbol,
                     orElse: () => null
                  );
                  
                  double currentPrice = 0.0;
                  double assetValue = 0.0;
                  if (coinData != null) {
                    currentPrice = (coinData['current_price'] as num).toDouble();
                    assetValue = amount * currentPrice;
                  }

                  double percentage = totalPortfolioValue > 0 ? (assetValue / totalPortfolioValue) * 100 : 0.0;

                  assetWidgets.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                              child: Text(symbol.isNotEmpty ? symbol[0] : '?', style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${amount.toStringAsFixed(4)} $symbol', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${assetValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${percentage.toStringAsFixed(1)}% of Portfolio', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              });
              
              if (assetWidgets.isEmpty) {
                 return GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: const Center(child: Text("You don't own any crypto yet.", style: TextStyle(color: Colors.white54))),
                );
              }

              return Column(children: assetWidgets);
            }),
            const SizedBox(height: 24),
            const Text('Recent Trades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(Get.find<AuthController>().user.value?.uid)
                  .collection('trades')
                  .orderBy('timestamp', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final trades = snapshot.data?.docs ?? [];
                if (trades.isEmpty) {
                  return const Text('No recent trades.', style: TextStyle(color: Colors.white54));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                            Text(
                              '${isBuy ? '-' : '+'}\$${totalValue.toStringAsFixed(2)}', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                );
              }
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.bottomSheet(
            const TradeBottomSheet(),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.currency_exchange),
        label: const Text('Trade', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
  void _showAdjustBalanceDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final authController = Get.find<AuthController>();
    final double currentBalance = (authController.firestoreUserData['balanceUSD'] ?? 0.0).toDouble();
    
    amountController.text = currentBalance.toStringAsFixed(2);

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Adjust Account Balance', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set your actual cash balance to track real portfolio performance.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Balance (USD)',
                labelStyle: const TextStyle(color: AppTheme.primary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              final double? newBalance = double.tryParse(amountController.text);
              if (newBalance != null) {
                final uid = authController.user.value?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'balanceUSD': newBalance,
                  });
                  authController.firestoreUserData['balanceUSD'] = newBalance;
                  authController.firestoreUserData.refresh();
                  Get.back();
                  Get.snackbar('Success', 'Balance updated to \$${newBalance.toStringAsFixed(2)}');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
