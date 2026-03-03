import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  
  late Rx<User?> _user;
  Rx<User?> get user => _user;
  RxMap<String, dynamic> firestoreUserData = <String, dynamic>{}.obs;
  FirebaseAuth auth = FirebaseAuth.instance;
  // Please update serverClientId with the "Web client (auto created by Google Service)" ID found in Firebase -> Authentication -> Sign-in Method -> Google -> Web SDK configuration.
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  final LocalAuthentication localAuth = LocalAuthentication();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var hasBioSetup = false.obs;

  @override
  void onReady() {
    super.onReady();
    googleSignIn.initialize(
      serverClientId: '1025250563014-srlkenmjmi19ie09gd27gcvrrbr4918f.apps.googleusercontent.com',
    );
    _user = Rx<User?>(auth.currentUser);
    // Listen for auth changes
    _user.bindStream(auth.userChanges());
    ever(_user, _handleAuthChanged);
    _checkBiometricPreference();
  }

  void _handleAuthChanged(User? user) {
    if (user == null) {
      firestoreUserData.clear();
      Get.offAllNamed('/auth');
    } else {
      _fetchFirestoreData(user.uid);
      Get.offAllNamed('/hub');
    }
  }

  Future<void> _fetchFirestoreData(String uid) async {
    try {
      DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        firestoreUserData.value = doc.data() as Map<String, dynamic>;
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
      UserCredential cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Update Auth Profile
      await cred.user?.updateDisplayName('$firstName $lastName');
      
      final Map<String, dynamic> userData = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'balanceUSD': 10000.0,
        'holdings': {},
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Save to Firestore
      await firestore.collection('users').doc(cred.user?.uid).set(userData);
      firestoreUserData.value = userData;

      // Reload user so Obx triggers properly
      await auth.currentUser?.reload();
      _user.value = auth.currentUser;
      
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfileName(String firstName, String lastName) async {
    try {
      isLoading.value = true;
      String newName = '$firstName $lastName';
      await auth.currentUser?.updateDisplayName(newName);
      
      final Map<String, dynamic> updates = {
        'firstName': firstName,
        'lastName': lastName,
      };
      await firestore.collection('users').doc(auth.currentUser?.uid).set(updates, SetOptions(merge: true));
      
      firestoreUserData.addAll(updates);
      
      await auth.currentUser?.reload();
      _user.value = auth.currentUser; // Trigger UI updates
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
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      // For google_sign_in v7.0.0+
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) return; // User canceled
      
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // Get access token from authorization client
      final clientAuth = await googleUser.authorizationClient.authorizationForScopes(['email']);
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth?.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await auth.signInWithCredential(credential);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> authenticateWithBiometrics() async {
    try {
      bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
         Get.snackbar("Notice", "Biometrics not available on this device.");
         return;
      }
      
      // local_auth v3.0.0+ syntax
      bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to access Apex-Nexus',
        biometricOnly: true,
      );
      
      if (didAuthenticate) {
        // Biometric auth replaces password entry if a user session is active or keys are stored secure
        Get.offAllNamed('/hub');
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> logout() async {
    await googleSignIn.signOut();
    await auth.signOut();
  }
}
