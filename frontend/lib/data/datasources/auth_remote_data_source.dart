import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class AuthRemoteDataSource {
  Stream<User?> get userStream;
  User? get currentUser;
  
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password);
  Future<void> updateDisplayName(String displayName);
  Future<UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<AuthCredential?> getGoogleAuthCredential();
  Future<void> signInWithCredential(AuthCredential credential);
  Future<bool> authenticateBiometrics();
  Future<void> signOut();
  Future<Map<String, dynamic>?> fetchUserData(String uid);
  Future<void> saveUserData(String uid, Map<String, dynamic> data, {bool merge = false});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  final LocalAuthentication localAuth = LocalAuthentication();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    await googleSignIn.initialize(
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );
  }

  @override
  Stream<User?> get userStream => auth.userChanges();

  @override
  User? get currentUser => auth.currentUser;

  @override
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await auth.currentUser?.updateDisplayName(displayName);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<AuthCredential?> getGoogleAuthCredential() async {
    final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
    if (googleUser == null) return null; // User canceled
    
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Get access token from authorization client
    final clientAuth = await googleUser.authorizationClient?.authorizationForScopes(['email']);
    
    return GoogleAuthProvider.credential(
      accessToken: clientAuth?.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  @override
  Future<void> signInWithCredential(AuthCredential credential) async {
    await auth.signInWithCredential(credential);
  }

  @override
  Future<bool> authenticateBiometrics() async {
    bool canCheckBiometrics = await localAuth.canCheckBiometrics;
    if (!canCheckBiometrics) return false;
    
    return await localAuth.authenticate(
      localizedReason: 'Please authenticate to access Apex-Nexus',
      biometricOnly: true,
    );
  }

  @override
  Future<void> signOut() async {
    await googleSignIn.signOut();
    await auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> saveUserData(String uid, Map<String, dynamic> data, {bool merge = false}) async {
    await firestore.collection('users').doc(uid).set(data, SetOptions(merge: merge));
  }
}
