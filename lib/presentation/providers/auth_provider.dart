import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/app_user.dart';
import 'package:toktok/domain/exceptions/auth_failure.dart';
import 'package:toktok/domain/services/auth_gateway.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthGateway gateway}) : _gateway = gateway {
    _subscription = _gateway.onAuthStateChanged.listen((next) {
      user = next;
      isCheckingSession = false;
      notifyListeners();
    });
  }

  final AuthGateway _gateway;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? user;
  bool isCheckingSession = true;
  bool isSubmitting = false;

  bool get isAuthenticated => user != null;

  String get uid => user?.uid ?? '';

  String get authorName => user?.authorName ?? 'Usuario';

  Future<String?> signIn({
    required String email,
    required String password,
  }) {
    if (isSubmitting) {
      return Future<String?>.value('Ya hay un ingreso en curso.');
    }
    return _run(() => _gateway.signIn(email: email, password: password));
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) {
    if (isSubmitting) {
      return Future<String?>.value('Ya hay un registro en curso.');
    }
    return _run(() async {
      user = await _gateway.register(
        name: name,
        email: email,
        password: password,
      );
    });
  }

  Future<String?> signOut() async {
    try {
      await _gateway.signOut();
      return null;
    } on AuthFailure catch (error) {
      return error.message;
    } catch (_) {
      return 'No se pudo cerrar la sesión. Revisá tu conexión e intentá de nuevo.';
    }
  }

  Future<String?> _run(Future<void> Function() action) async {
    isSubmitting = true;
    notifyListeners();
    try {
      await action();
      user = _gateway.currentUser ?? user;
      return null;
    } on AuthFailure catch (error) {
      return error.message;
    } catch (_) {
      return 'No se pudo completar la operación. Revisá tu conexión e intentá de nuevo.';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
