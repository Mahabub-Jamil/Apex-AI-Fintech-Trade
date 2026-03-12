import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/datasources/market_remote_data_source.dart';
import 'data/repositories/market_repository_impl.dart';
import 'screens/auth_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/main_layout.dart';
import 'screens/asset_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  try {
    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
          appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        ),
      );
    } else {
       await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization failed (Check configurations): $e');
  }

  // Initialize Data Source & Repository
  final authRemoteDataSource = AuthRemoteDataSourceImpl();
  await authRemoteDataSource.init();
  final authRepository = AuthRepositoryImpl(remoteDataSource: authRemoteDataSource);

  final marketRemoteDataSource = MarketRemoteDataSourceImpl();
  final marketRepository = MarketRepositoryImpl(remoteDataSource: marketRemoteDataSource);

  // Initialize Core Controllers
  Get.put(AuthController(authRepository: authRepository));
  Get.put(DashboardController(marketRepository: marketRepository));

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
