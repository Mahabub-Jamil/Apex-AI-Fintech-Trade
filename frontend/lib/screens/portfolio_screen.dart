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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asset Allocation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(color: AppTheme.primary, value: 40, title: 'BTC\n40%', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      PieChartSectionData(color: AppTheme.accent, value: 30, title: 'ETH\n30%', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      PieChartSectionData(color: AppTheme.success, value: 15, title: 'SOL\n15%', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      PieChartSectionData(color: Colors.blueGrey, value: 15, title: 'USDC\n15%', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
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
}
