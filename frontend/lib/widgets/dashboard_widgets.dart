import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../controllers/dashboard_controller.dart';

class MarketTicker extends StatelessWidget {
  final DashboardController controller = Get.find<DashboardController>();

  MarketTicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Obx(() {
        if (controller.marketData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.marketData.length,
          itemBuilder: (context, index) {
            final coin = controller.marketData[index];
            final double change = (coin['price_change_percentage_24h'] ?? 0).toDouble();
            final isPositive = change >= 0;

            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      coin['symbol'].toString().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${coin['current_price']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? AppTheme.accent : AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (controller.coinPnL[coin['symbol']] != null && controller.coinPnL[coin['symbol']]! != 0.0) ... [
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                           color: controller.coinPnL[coin['symbol']]! >= 0 ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2),
                           borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'P&L: ${controller.coinPnL[coin['symbol']]! >= 0 ? '+' : ''}${controller.coinPnL[coin['symbol']]!.toStringAsFixed(2)}%',
                          style: TextStyle(
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                             color: controller.coinPnL[coin['symbol']]! >= 0 ? AppTheme.success : AppTheme.error,
                          ),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class AiSentimentWidget extends StatelessWidget {
  final DashboardController controller = Get.find<DashboardController>();

  AiSentimentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Strategy Advice', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.aiPortfolioStrategy.value.isEmpty) {
               return const Center(child: CircularProgressIndicator());
            }
            return Text(
              controller.aiPortfolioStrategy.value,
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }),
        ],
      ),
    );
  }
}
