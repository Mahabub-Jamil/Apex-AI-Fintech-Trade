import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:candlesticks/candlesticks.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../domain/repositories/market_repository.dart';

class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({Key? key}) : super(key: key);

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  late Map<String, dynamic> coin;
  List<Candle> candles = [];
  bool isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
      'price_change_percentage_24h': 0.0,
      'aiTrend': 'Neutral',
    };
    _fetchHistoricalData();
  }

  Future<void> _fetchHistoricalData() async {
    try {
      final repository = Get.find<MarketRepository>();
      final historyData = await repository.getAssetHistory(
        coinId: coin['id'] ?? '',
        days: '7',
      );

      if (mounted) {
        setState(() {
          candles = historyData.map((d) {
            // CoinGecko OHLC format: [time, open, high, low, close]
            return Candle(
              date: DateTime.fromMillisecondsSinceEpoch(d[0]),
              open: (d[1] as num).toDouble(),
              high: (d[2] as num).toDouble(),
              low: (d[3] as num).toDouble(),
              close: (d[4] as num).toDouble(),
              volume: 1000.0, // CG OHLC doesn't always provide volume per candle, using placeholder
            );
          }).toList().reversed.toList(); // Reverse to match candlestick widget order
          isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
      if (mounted) {
        setState(() => isLoadingHistory = false);
      }
    }
  }

  double _parseValue(dynamic value) {
     if (value == null) return 0.0;
     if (value is int) return value.toDouble();
     if (value is double) return value;
     return double.tryParse(value.toString()) ?? 0.0;
  }



  @override
  Widget build(BuildContext context) {
    double currentPrice = _parseValue(coin['current_price']);
    double change = _parseValue(coin['price_change_percentage_24h']);
    final bool isPositive = change >= 0;

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
                        Text('\$${currentPrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              color: isPositive ? AppTheme.success : AppTheme.error,
                            ),
                            Text(
                              '${change.abs().toStringAsFixed(2)}% Past 24h',
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
                          Text(coin['aiTrend'] ?? 'Neutral', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  child: isLoadingHistory 
                    ? const Center(child: CircularProgressIndicator())
                    : candles.isEmpty 
                      ? const Center(child: Text('Historical data unavailable', style: TextStyle(color: Colors.white54)))
                      : Candlesticks(
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
