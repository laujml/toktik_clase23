import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:toktok/domain/entities/app_user.dart';
import 'package:toktok/domain/services/auth_gateway.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/widgets/shared/video_buttons.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('el dueño confirma antes de borrar su video', (tester) async {
    final repository = FakeVideoRepository(
      pages: [
        [sampleVideo(id: 'mio', uid: 'ana')],
      ],
    );
    final provider = DiscoverProvider(repository: repository);
    final auth = AuthProvider(gateway: _Gateway('ana'));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<DiscoverProvider>.value(value: provider),
        ],
        child: const MaterialApp(
          home: Scaffold(body: _OwnedButtons()),
        ),
      ),
    );
    await provider.loadNextPage('ana');
    await tester.pump();

    expect(auth.uid, 'ana');
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    expect(find.text('Se borra este video para todos. No se puede deshacer.'),
        findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pump();
    expect(repository.deleted, isNull);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.deleted?.id, 'mio');
    expect(provider.videos, isEmpty);
    expect(find.text('Video borrado.'), findsOneWidget);
  });

  testWidgets('otra cuenta no ve el botón de borrar', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(gateway: _Gateway('bruno')),
          ),
          ChangeNotifierProvider(
            create: (_) => DiscoverProvider(
              repository: FakeVideoRepository(),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: VideoButtons(video: sampleVideo(id: 'de-ana', uid: 'ana')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Borrar video'), findsNothing);
  });
}

class _OwnedButtons extends StatelessWidget {
  const _OwnedButtons();

  @override
  Widget build(BuildContext context) {
    final videos = context.watch<DiscoverProvider>().videos;
    if (videos.isEmpty) return const SizedBox.shrink();
    return VideoButtons(video: videos.single);
  }
}

class _Gateway implements AuthGateway {
  _Gateway(this.uid);

  final String uid;

  AppUser get _user => AppUser(
        uid: uid,
        email: '$uid@test.com',
        displayName: uid,
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
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}
