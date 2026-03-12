import 'package:firebase_auth/firebase_auth.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<User?> get userStream;
  User? get currentUser;
  
  Future<void> signUpWithEmail(String firstName, String lastName, String email, String password);
  Future<void> loginWithEmail(String email, String password);
  Future<void> loginWithGoogle();
  Future<bool> authenticateWithBiometrics();
  Future<void> updateProfileName(String firstName, String lastName);
  Future<void> logout();
  Future<UserEntity?> fetchUserData(String uid);
}
