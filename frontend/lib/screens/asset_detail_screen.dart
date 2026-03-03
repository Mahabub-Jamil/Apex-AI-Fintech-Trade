import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:candlesticks/candlesticks.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({Key? key}) : super(key: key);

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  late Map<String, dynamic> coin;
  List<Candle> candles = [];

  @override
  void initState() {
    super.initState();
    coin = Get.arguments as Map<String, dynamic>? ?? {
      'symbol': 'UNK',
      'name': 'Unknown',
      'price': 0.0,
      'change': 0.0,
      'aiTrend': 'Neutral',
    };
    _generateMockCandles();
  }

  void _generateMockCandles() {
    // Generate some mock candlestick data based on the current price
    double currentPrice = coin['price'];
    DateTime now = DateTime.now();
    for (int i = 0; i < 50; i++) {
        double open = currentPrice + (i * 0.5) * (i % 2 == 0 ? 1 : -1);
        double close = open + (1.2) * (i % 3 == 0 ? 1 : -1);
        double high = open > close ? open + 2 : close + 2;
        double low = open < close ? open - 2 : close - 2;
        
        candles.add(Candle(
          date: now.subtract(Duration(days: i)),
          high: high,
          low: low,
          open: open,
          close: close,
          volume: 1000.0 + (i * 10),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPositive = coin['change'] >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${coin['name']} (${coin['symbol']})'),
        actions: [
          IconButton(icon: const Icon(Icons.star_border), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Header
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('\$${coin['price'].toStringAsFixed(2)}', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              color: isPositive ? AppTheme.success : AppTheme.error,
                            ),
                            Text(
                              '${coin['change'].abs()}% Past 24h',
                              style: TextStyle(
                                color: isPositive ? AppTheme.success : AppTheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppTheme.accent),
                          const SizedBox(height: 4),
                          Text(coin['aiTrend'], style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Candlestick Chart
              const Text('Price Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: GlassContainer(
                  padding: const EdgeInsets.all(8),
                  child: Candlesticks(
                    candles: candles,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // AI News Feed & Sentiment
              const Text('AI Sentiment & Intelligence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text('Gemini 3 Flash Analysis', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Market conditions appear steady. Recent movements show consolidation within a tight range. On-chain metrics suggest slight accumulation by institutional holders, counter-balanced by retail selling. Expected volatility over the next 48 hours is moderate.",
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    _buildNewsItem("Fed holds rates steady, markets react minimally"),
                    _buildNewsItem("Major protocol upgrade successfully completed"),
                    _buildNewsItem("New whale accumulation detected in recent tx"),
                  ],
                ),
              ),
              const SizedBox(height: 80), // padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.snackbar("Trade", "Trading module coming in next phase");
        },
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.compare_arrows),
        label: const Text('Trade Now', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNewsItem(String headline) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.article_outlined, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(headline, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
