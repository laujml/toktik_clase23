import 'package:toktok/domain/entities/app_user.dart';

abstract class AuthGateway {
  Stream<AppUser?> get onAuthStateChanged;

  AppUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
