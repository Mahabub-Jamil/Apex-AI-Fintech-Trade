import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository authRepository;

  AuthController({required this.authRepository});

  static AuthController instance = Get.find();
  
  late Rx<User?> _user;
  Rx<User?> get user => _user;
  RxMap<String, dynamic> firestoreUserData = <String, dynamic>{}.obs;

  var isLoading = false.obs;
  var hasBioSetup = false.obs;

  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?>(authRepository.currentUser);
    // Listen for auth changes
    _user.bindStream(authRepository.userStream);
    ever(_user, _handleAuthChanged);
    _checkBiometricPreference();
  }

  void _handleAuthChanged(User? user) async {
    if (user == null) {
      firestoreUserData.clear();
      Get.offAllNamed('/auth');
    } else {
      await _fetchFirestoreData(user.uid);
      Get.offAllNamed('/hub');
    }
  }

  Future<void> _fetchFirestoreData(String uid) async {
    try {
      final userEntity = await authRepository.fetchUserData(uid);
      if (userEntity != null) {
        firestoreUserData.value = userEntity.toMap();
      }
    } catch (e) {
      print("Error fetching firestore data: $e");
    }
  }

  Future<void> _checkBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    hasBioSetup.value = prefs.getBool('bio_setup') ?? false;
  }

  Future<void> signUpWithEmail(String firstName, String lastName, String email, String password) async {
    try {
      isLoading.value = true;
      await authRepository.signUpWithEmail(firstName, lastName, email, password);
      
      // Reload user so Obx triggers properly
      if (authRepository.currentUser != null) {
        await _fetchFirestoreData(authRepository.currentUser!.uid);
        _user.value = authRepository.currentUser;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfileName(String firstName, String lastName) async {
    try {
      isLoading.value = true;
      await authRepository.updateProfileName(firstName, lastName);
      
      if (authRepository.currentUser != null) {
        await _fetchFirestoreData(authRepository.currentUser!.uid);
        _user.value = authRepository.currentUser; // Trigger UI updates
      }
      Get.snackbar("Success", "Profile updated successfully");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      await authRepository.loginWithEmail(email, password);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      await authRepository.loginWithGoogle();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> authenticateWithBiometrics() async {
    try {
      bool didAuthenticate = await authRepository.authenticateWithBiometrics();
      if (didAuthenticate) {
        Get.offAllNamed('/hub');
      } else {
        Get.snackbar("Notice", "Biometrics not authenticated or unavailable.");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
  }
}
