import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/dashboard_widgets.dart';
import 'main_layout.dart';
import '../widgets/glass_container.dart';
import '../widgets/line_chart_widget.dart';

import 'profile_screen.dart';

class HubScreen extends StatelessWidget {
  HubScreen({Key? key}) : super(key: key);

  final AuthController authController = Get.find<AuthController>();
  final DashboardController dashboardController = Get.find<DashboardController>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APEX-NEXUS', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Obx(() {
        if (dashboardController.isLoading.value && dashboardController.marketData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return RefreshIndicator(
          onRefresh: dashboardController.fetchAIPortfolioStrategy,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    GlassContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() {
                            final String firstName = authController.firestoreUserData['firstName'] ?? authController.user.value?.displayName?.split(' ').first ?? 'Trader';
                            return Text(
                              'Hello, $firstName!',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22),
                              overflow: TextOverflow.ellipsis,
                            );
                          }),
                          const SizedBox(height: 4),
                          const Text('Welcome back to your dashboard', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                const SizedBox(height: 24),
                BalanceCard(),
                const SizedBox(height: 24),
                const Text('Market Ticker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 12),
                MarketTicker(),
                const SizedBox(height: 24),
                const InteractiveLineChart(),
                const SizedBox(height: 24),
                AiSentimentWidget(),
                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
        );
      }),
    );
  }
}
