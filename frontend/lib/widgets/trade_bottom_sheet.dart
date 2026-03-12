import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/trade_controller.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class TradeBottomSheet extends StatefulWidget {
  const TradeBottomSheet({Key? key}) : super(key: key);

  @override
  _TradeBottomSheetState createState() => _TradeBottomSheetState();
}

class _TradeBottomSheetState extends State<TradeBottomSheet> {
  final DashboardController _dashboardController = Get.find<DashboardController>();
  final TradeController _tradeController = Get.put(TradeController());
  
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCoinSymbol;

  @override
  void initState() {
    super.initState();
    if (_dashboardController.marketData.isNotEmpty) {
      _selectedCoinSymbol = _dashboardController.marketData.first['symbol'].toString();
    }
  }

  void _executeTrade(bool isBuy) async {
    if (_selectedCoinSymbol == null) return;
    
    final selectedCoinMap = _dashboardController.marketData.firstWhere((coin) => coin['symbol'].toString() == _selectedCoinSymbol, orElse: () => null);
    if (selectedCoinMap == null) return;
    
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0.0) {
      Get.snackbar("Invalid Amount", "Please enter a valid amount greater than 0.");
      return;
    }

    final coinId = selectedCoinMap['id'] is String ? selectedCoinMap['id'] : selectedCoinMap['name'].toString().toLowerCase();
    final symbol = selectedCoinMap['symbol'].toString();
    final currentPrice = (selectedCoinMap['current_price'] as num).toDouble();

    final success = await _tradeController.executeTrade(coinId, symbol, amount, currentPrice, isBuy);
    if (success) {
      Get.back(); // close sheet
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Execute Trade', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          
          if (_dashboardController.marketData.isNotEmpty) ... [
            Obx(() {
               if (_selectedCoinSymbol != null && !_dashboardController.marketData.any((c) => c['symbol'].toString() == _selectedCoinSymbol)) {
                 _selectedCoinSymbol = null;
               }
               if (_selectedCoinSymbol == null && _dashboardController.marketData.isNotEmpty) {
                 _selectedCoinSymbol = _dashboardController.marketData.first['symbol'].toString();
               }

               return DropdownButtonFormField<String>(
                 decoration: InputDecoration(
                   labelText: 'Select Asset',
                   labelStyle: const TextStyle(color: Colors.white54),
                   filled: true,
                   fillColor: Colors.white.withValues(alpha: 0.1),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                 ),
                 dropdownColor: const Color(0xFF1E1E2C),
                 value: _selectedCoinSymbol,
                 items: _dashboardController.marketData.map((coin) {
                   return DropdownMenuItem<String>(
                     value: coin['symbol'].toString(),
                     child: Text('${coin['name']} (${coin['symbol'].toString().toUpperCase()}) - \$${coin['current_price']}', 
                       style: const TextStyle(color: Colors.white)),
                   );
                 }).toList().cast(),
                 onChanged: (val) {
                   setState(() => _selectedCoinSymbol = val);
                 },
               );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Obx(() => ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  onPressed: _tradeController.isLoading.value ? null : () => _executeTrade(true),
                  icon: const Icon(Icons.arrow_downward, color: Colors.white),
                  label: _tradeController.isLoading.value 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buy Asset', style: TextStyle(color: Colors.white)),
                )),
                Obx(() => ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  onPressed: _tradeController.isLoading.value ? null : () => _executeTrade(false),
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  label: _tradeController.isLoading.value 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sell Asset', style: TextStyle(color: Colors.white)),
                )),
              ],
            ),
          ] else ... [
             const Text("Market data unavailable.", style: TextStyle(color: Colors.white54)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
