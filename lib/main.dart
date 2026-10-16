import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toktok/app.dart';
import 'package:toktok/firebase_options.dart';
import 'package:toktok/infrastructure/auth/firebase_auth_gateway.dart';
import 'package:toktok/infrastructure/datasources/firestore_video_datasource.dart';
import 'package:toktok/infrastructure/mappers/local_videos.dart';
import 'package:toktok/infrastructure/repositories/video_post_repository_impl.dart';
import 'package:toktok/infrastructure/storage/storage_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    runApp(FirebaseSetupApp(message: '$error'));
    return;
  }

  final repository = VideoPostRepositoryImpl(
    remoteDatasource: FirestoreVideoDatasource(
      storage: buildVideoFileStorage(),
    ),
    localVideos: mapLocalVideoPosts(),
  );

  runApp(
    TokTikApp(
      authGateway: FirebaseAuthGateway(),
      repository: repository,
    ),
  );
}

class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Falta configurar Firebase',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'En la carpeta tiktok_clase23 ejecutá flutterfire configure. Los pasos están en el README. No subas firebase_options.dart ni google-services.json.',
                ),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
