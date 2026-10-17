import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:toktok/app.dart';
import 'package:toktok/domain/entities/app_user.dart';
import 'package:toktok/domain/entities/camera_filter.dart';
import 'package:toktok/domain/services/auth_gateway.dart';
import 'package:toktok/presentation/providers/face_filter_provider.dart';
import 'package:toktok/presentation/providers/upload_provider.dart';
import 'package:toktok/presentation/screens/filters/filters_screen.dart';
import 'package:toktok/presentation/screens/home/app_shell.dart';
import 'package:toktok/presentation/screens/upload/upload_video_screen.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('Filtros explica que en la computadora no hay cámara', (
    tester,
  ) async {
    final filters = FaceFilterProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<FaceFilterProvider>.value(
        value: filters,
        child: MaterialApp(
          home: FiltersScreen(onUploaded: (_) {}),
        ),
      ),
    );

    expect(find.text(filtersNeedPhoneMessage), findsOneWidget);
    expect(find.bySemanticsLabel('Filtro Kawaii'), findsOneWidget);
    expect(find.bySemanticsLabel('Filtro Lentes'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Filtro Lentes'));
    await tester.pump();

    expect(filters.selected, CameraFilter.glasses);
  });

  testWidgets('publicar con filtro no deja cambiar el video', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UploadProvider(repository: FakeVideoRepository()),
        child: MaterialApp(
          home: UploadVideoScreen(
            initialVideo: XFile('filtro.mp4'),
            videoLocked: true,
          ),
        ),
      ),
    );

    expect(find.text('Este video incluye el filtro.'), findsOneWidget);
    expect(find.text('Publicar con filtro'), findsOneWidget);
    expect(find.text('Galería'), findsNothing);
    expect(find.text('Cámara'), findsNothing);
  });

  testWidgets('la barra inferior abre la sección Filtros', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      TokTikApp(
        authGateway: _SignedInGateway(),
        repository: FakeVideoRepository(),
      ),
    );
    await tester.pump();
    await tester.pump();

    final home = tester.widget<MaterialApp>(find.byType(MaterialApp)).home;
    expect(home, isA<AppShell>());
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Filtros'), findsOneWidget);

    final nav = tester.getRect(find.byType(NavigationBar));
    final feed = tester.getRect(find.text('Feed'));
    expect(nav.bottom, closeTo(800 - 48, 0.1));
    expect(feed.bottom, lessThanOrEqualTo(800 - 48));

    expect(
      find.text('Todavía no hay videos. Subí el primero.'),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(find.text('Todavía no hay videos. Subí el primero.'))
          .bottom,
      lessThanOrEqualTo(nav.top),
    );

    await tester.tap(find.text('Filtros'));
    await tester.pump();

    expect(find.text(filtersNeedPhoneMessage), findsOneWidget);
    expect(find.bySemanticsLabel('Grabar video con filtro'), findsOneWidget);
    expect(
      tester.getRect(find.text(filtersNeedPhoneMessage)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top),
    );
  });
}

class _SignedInGateway implements AuthGateway {
  static const _user = AppUser(
    uid: 'ana',
    email: 'ana@test.com',
    displayName: 'Ana',
  );

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get onAuthStateChanged => Stream<AppUser?>.value(_user);

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _user;
  }

  @override
  Future<void> signIn(
      {required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}
