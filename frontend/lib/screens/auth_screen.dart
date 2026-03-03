import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/glass_container.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatelessWidget {
  AuthScreen({Key? key}) : super(key: key);

  final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background abstract gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Hero(
                  tag: 'app_logo',
                  child: GlassContainer(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hexagon_outlined, size: 60, color: AppTheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'APEX-NEXUS',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'Email Address',
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Obx(() => authController.isLoading.value 
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  authController.loginWithEmail(
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                  );
                                },
                                child: const Text('Login'),
                              ),
                            )
                        ),
                        const SizedBox(height: 16),
                        const Text('OR', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => authController.loginWithGoogle(),
                          icon: const Icon(Icons.login),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                           if (authController.hasBioSetup.value) {
                             return IconButton(
                               icon: const Icon(Icons.fingerprint, size: 36, color: AppTheme.accent),
                               onPressed: () => authController.authenticateWithBiometrics(),
                             );
                           }
                           return const SizedBox.shrink();
                        }),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Get.toNamed('/signup'),
                          child: const Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
