import 'package:firebase_auth/firebase_auth.dart';
import 'package:toktok/domain/entities/app_user.dart';
import 'package:toktok/domain/exceptions/auth_failure.dart';
import 'package:toktok/domain/services/auth_gateway.dart';
import 'package:toktok/infrastructure/auth/auth_error_messages.dart';

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(messageForAuthCode(error.code));
    } catch (_) {
      throw const AuthFailure(
        'No se pudo iniciar sesión. Revisá tu conexión e intentá de nuevo.',
      );
    }
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final created = credential.user;
      if (created == null) {
        throw const AuthFailure('No se pudo crear la cuenta.');
      }
      await created.updateDisplayName(name.trim());
      await created.reload();
      final refreshed = _auth.currentUser;
      final user = _mapUser(refreshed);
      if (user == null) {
        throw const AuthFailure('No se pudo crear la cuenta.');
      }
      return user;
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(messageForAuthCode(error.code));
    } catch (_) {
      throw const AuthFailure(
        'No se pudo crear la cuenta. Revisá tu conexión e intentá de nuevo.',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }
}
