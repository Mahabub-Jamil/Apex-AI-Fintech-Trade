import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<User?> get userStream => remoteDataSource.userStream;

  @override
  User? get currentUser => remoteDataSource.currentUser;

  @override
  Future<void> signUpWithEmail(String firstName, String lastName, String email, String password) async {
    final userCredential = await remoteDataSource.signUpWithEmailAndPassword(email, password);
    
    await remoteDataSource.updateDisplayName('$firstName $lastName');
    
    final Map<String, dynamic> userData = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'balanceUSD': 10000.0,
      'holdings': {},
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    if (userCredential.user != null) {
      await remoteDataSource.saveUserData(userCredential.user!.uid, userData);
      await remoteDataSource.currentUser?.reload();
    }
  }

  @override
  Future<void> loginWithEmail(String email, String password) async {
    await remoteDataSource.signInWithEmailAndPassword(email, password);
  }

  @override
  Future<void> loginWithGoogle() async {
    final credential = await remoteDataSource.getGoogleAuthCredential();
    if (credential != null) {
      await remoteDataSource.signInWithCredential(credential);
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    return await remoteDataSource.authenticateBiometrics();
  }

  @override
  Future<void> updateProfileName(String firstName, String lastName) async {
    String newName = '$firstName $lastName';
    await remoteDataSource.updateDisplayName(newName);
    
    final Map<String, dynamic> updates = {
      'firstName': firstName,
      'lastName': lastName,
    };
    
    if (currentUser != null) {
      await remoteDataSource.saveUserData(currentUser!.uid, updates, merge: true);
      await remoteDataSource.currentUser?.reload();
    }
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.signOut();
  }

  @override
  Future<UserEntity?> fetchUserData(String uid) async {
    final data = await remoteDataSource.fetchUserData(uid);
    if (data != null) {
      return UserEntity.fromMap(data, uid);
    }
    return null;
  }
}
