import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../controllers/dashboard_controller.dart';

class MarketDiscoveryScreen extends StatefulWidget {
  const MarketDiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<MarketDiscoveryScreen> createState() => _MarketDiscoveryScreenState();
}

class _MarketDiscoveryScreenState extends State<MarketDiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  List<Map<String, dynamic>> _getFilteredCoins(List<dynamic> marketData) {
    if (_searchController.text.isEmpty) {
      return marketData.cast<Map<String, dynamic>>();
    }
    return marketData
        .cast<Map<String, dynamic>>()
        .where((coin) => 
          (coin['name']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) || 
          (coin['symbol']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)
        )
        .toList();
  }

  // Helper safely parsing current_price that might come from JSON as int
  double _parseValue(dynamic value) {
     if (value == null) return 0.0;
     if (value is int) return value.toDouble();
     if (value is double) return value;
     return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Discovery'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'All Assets'),
            Tab(text: 'Top Gainers'),
            Tab(text: 'Top Losers'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search coins...',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final dashboardController = Get.find<DashboardController>();
              final marketData = dashboardController.marketData;
              
              if (dashboardController.isLoading.value && marketData.isEmpty) {
                 return const Center(child: CircularProgressIndicator());
              }
              
              if (marketData.isEmpty) {
                 return const Center(child: Text("No market data available.", style: TextStyle(color: Colors.white70)));
              }
              
              final filteredCoins = _getFilteredCoins(marketData);

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildCoinList(filteredCoins),
                  _buildCoinList(filteredCoins.where((c) => _parseValue(c['price_change_percentage_24h']) > 0).toList()),
                  _buildCoinList(filteredCoins.where((c) => _parseValue(c['price_change_percentage_24h']) < 0).toList()),
                ],
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildCoinList(List<Map<String, dynamic>> coins) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: coins.length,
      itemBuilder: (context, index) {
        final coin = coins[index];
        final priceChange = _parseValue(coin['price_change_percentage_24h']);
        final isPositive = priceChange >= 0;
        
        final symbol = (coin['symbol'] ?? '???').toString().toUpperCase();
        final name = coin['name'] ?? 'Unknown';
        final price = _parseValue(coin['current_price']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () => Get.toNamed('/asset_detail', arguments: coin),
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
                        Text(name, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPositive ? AppTheme.success : AppTheme.error,
                            size: 14,
                          ),
                          Text(
                            '${priceChange.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: isPositive ? AppTheme.success : AppTheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // AI Trend Badge (Mock for now since CoinGecko doesn't provide this directly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          isPositive ? 'Bullish' : 'Bearish',
                          style: const TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
