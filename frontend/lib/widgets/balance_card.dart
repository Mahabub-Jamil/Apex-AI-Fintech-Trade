import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/glass_container.dart';
import '../theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';

class BalanceCard extends StatelessWidget {
  final DashboardController controller = Get.find<DashboardController>();

  BalanceCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Icon(Icons.account_balance_wallet, color: AppTheme.accent),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            '\$${controller.balanceUSD.value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppTheme.primary,
            ),
          )),
          const SizedBox(height: 4),
          Obx(() => Text(
            '৳ ${controller.balanceBDT.value.toStringAsFixed(2)} BDT',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white54,
            ),
          )),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Invested', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Obx(() => Text('\$${controller.totalInvestedUSD.value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Profit', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Obx(() {
                    final profit = controller.totalProfitUSD.value;
                    final isPositive = profit >= 0;
                    return Text(
                      '${isPositive ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isPositive ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
