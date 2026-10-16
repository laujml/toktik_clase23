import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/app.dart';
import 'package:toktok/domain/entities/app_user.dart';
import 'package:toktok/domain/services/auth_gateway.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('el login valida el formulario y mueve el foco con el teclado', (
    tester,
  ) async {
    await tester.pumpWidget(
      TokTikApp(
        authGateway: _FakeAuthGateway(),
        repository: FakeVideoRepository(),
      ),
    );
    await tester.pump();

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.bySemanticsLabel('Iniciar sesión'), findsOneWidget);

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(2));
    expect(fields.first.focusNode, isNotNull);
    expect(fields.first.textInputAction, TextInputAction.next);
    expect(fields.last.textInputAction, TextInputAction.done);

    await tester.enterText(find.byType(TextFormField).first, 'correo-mal');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Ingresá un correo válido.'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener al menos 6 caracteres.'),
      findsOneWidget,
    );
  });
}

class _FakeAuthGateway implements AuthGateway {
  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> get onAuthStateChanged => Stream<AppUser?>.value(null);

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signIn(
      {required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}
