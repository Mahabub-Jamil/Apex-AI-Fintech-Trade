import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class MarketDiscoveryScreen extends StatefulWidget {
  const MarketDiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<MarketDiscoveryScreen> createState() => _MarketDiscoveryScreenState();
}

class _MarketDiscoveryScreenState extends State<MarketDiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Mock list of 50+ coins
  final List<Map<String, dynamic>> _allCoins = [
    {'symbol': 'BTC', 'name': 'Bitcoin', 'price': 65432.10, 'change': 2.4, 'aiTrend': 'Bullish'},
    {'symbol': 'ETH', 'name': 'Ethereum', 'price': 3456.78, 'change': 1.8, 'aiTrend': 'Neutral'},
    {'symbol': 'SOL', 'name': 'Solana', 'price': 145.20, 'change': -5.2, 'aiTrend': 'Bearish'},
    {'symbol': 'BNB', 'name': 'Binance Coin', 'price': 600.00, 'change': 0.5, 'aiTrend': 'Neutral'},
    {'symbol': 'XRP', 'name': 'Ripple', 'price': 0.60, 'change': 1.1, 'aiTrend': 'Moderate Bullish'},
    // Add more mock data...
  ];

  List<Map<String, dynamic>> _filteredCoins = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filteredCoins = _allCoins;
  }

  void _filterCoins(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCoins = _allCoins);
      return;
    }
    setState(() {
      _filteredCoins = _allCoins.where((coin) => 
        coin['name'].toString().toLowerCase().contains(query.toLowerCase()) || 
        coin['symbol'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
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
              onChanged: _filterCoins,
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoinList(_filteredCoins),
                _buildCoinList(_filteredCoins.where((c) => c['change'] > 0).toList()),
                _buildCoinList(_filteredCoins.where((c) => c['change'] < 0).toList()),
              ],
            ),
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
        final isPositive = coin['change'] >= 0;

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
                    child: Text(coin['symbol'][0], style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(coin['symbol'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(coin['name'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${coin['price'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPositive ? AppTheme.success : AppTheme.error,
                            size: 14,
                          ),
                          Text(
                            '${coin['change'].abs()}%',
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
                  // AI Trend Badge
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
                          coin['aiTrend'],
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
