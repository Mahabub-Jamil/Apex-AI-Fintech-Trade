import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import 'hub_screen.dart';
import 'market_discovery_screen.dart';
import 'portfolio_screen.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';

class MainLayoutController extends GetxController {
  var currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}

class MainLayoutScreen extends StatelessWidget {
  MainLayoutScreen({Key? key}) : super(key: key);

  final MainLayoutController controller = Get.put(MainLayoutController());

  final List<Widget> _pages = [
    HubScreen(),
    const MarketDiscoveryScreen(),
    const PortfolioScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: _pages,
      )),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: controller.currentIndex.value,
        onTap: controller.changePage,
        backgroundColor: const Color(0xFF1E1E2C), // Match dark background
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.compass),
            label: 'Discovery',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_pie),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profile',
          ),
        ],
      )),
    );
  }
}
