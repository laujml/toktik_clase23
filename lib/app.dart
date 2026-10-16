import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/theme/app_theme.dart';
import 'package:toktok/domain/repositories/video_post_repository.dart';
import 'package:toktok/domain/services/auth_gateway.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/providers/upload_provider.dart';
import 'package:toktok/presentation/screens/auth/login_screen.dart';
import 'package:toktok/presentation/screens/discover/discover_screen.dart';

class TokTikApp extends StatelessWidget {
  const TokTikApp({
    super.key,
    required this.authGateway,
    required this.repository,
  });

  final AuthGateway authGateway;
  final VideoPostRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(gateway: authGateway),
      child: Builder(
        builder: (context) {
          final uid = context.watch<AuthProvider>().user?.uid ?? '';
          if (uid.isEmpty) return const _SessionGate();

          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                key: ValueKey('discover-$uid'),
                create: (_) => DiscoverProvider(repository: repository),
              ),
              ChangeNotifierProvider(
                key: ValueKey('upload-$uid'),
                create: (_) => UploadProvider(repository: repository),
              ),
            ],
            child: const _SessionGate(),
          );
        },
      ),
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      key: ValueKey(auth.user?.uid ?? 'signed-out'),
      title: 'TokTik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      home: auth.isCheckingSession
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : auth.isAuthenticated
              ? const DiscoverScreen()
              : const LoginScreen(),
    );
  }
}
