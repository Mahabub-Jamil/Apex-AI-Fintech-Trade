import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/main_layout.dart';
import 'screens/asset_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBElnwSgEsFu-HDnw2Fd1Pl5UtbNzTQyKY',
          appId: '1:1025250563014:android:9acef8140f59f463f998c7',
          messagingSenderId: '1025250563014',
          projectId: 'apex-nexus-fintech',
          storageBucket: 'apex-nexus-fintech.firebasestorage.app',
        ),
      );
    } else {
       await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization failed (Check configurations): $e');
  }

  // Initialize Core Controllers
  Get.put(AuthController());

  runApp(const ApexNexusApp());
}

class ApexNexusApp extends StatelessWidget {
  const ApexNexusApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Apex-Nexus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/auth', page: () => AuthScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),
        GetPage(name: '/hub', page: () => MainLayoutScreen()),
        GetPage(name: '/asset_detail', page: () => const AssetDetailScreen()),
      ],
    );
  }
}

// Temporary Splash/Hero Screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AuthController onReady will handle navigation if user exists
    return Scaffold(
      body: Center(
        child: Hero(
          tag: 'app_logo',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hexagon_outlined, size: 80, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                'APEX-NEXUS',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
