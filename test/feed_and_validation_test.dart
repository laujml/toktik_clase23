import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/config/feed_config.dart';
import 'package:toktok/config/helpers/auth_validators.dart';
import 'package:toktok/infrastructure/auth/auth_error_messages.dart';
import 'package:toktok/infrastructure/models/local_video_model.dart';
import 'package:toktok/infrastructure/models/video_post_model.dart';

void main() {
  test('pide la página siguiente cuando faltan 2 videos', () {
    expect(FeedConfig.shouldPrefetch(index: 2, itemCount: 5), isTrue);
    expect(FeedConfig.shouldPrefetch(index: 1, itemCount: 5), isFalse);
    expect(FeedConfig.shouldPrefetch(index: 7, itemCount: 10), isTrue);
    expect(FeedConfig.shouldPrefetch(index: 6, itemCount: 10), isFalse);
  });

  test('valida correo, contraseña y descripción', () {
    expect(AuthValidators.email(''), 'Ingresá tu correo.');
    expect(AuthValidators.email('no-es-correo'), 'Ingresá un correo válido.');
    expect(AuthValidators.email('ana@test.com'), isNull);
    expect(AuthValidators.password('123'), contains('6 caracteres'));
    expect(AuthValidators.password('123456'), isNull);
    expect(AuthValidators.confirmPassword('123456', '1234567'),
        contains('no coinciden'));
    expect(AuthValidators.caption('   '), 'Agregá una descripción.');
  });

  test('traduce errores de red y de credenciales', () {
    expect(messageForAuthCode('network-request-failed'), contains('conexión'));
    expect(messageForAuthCode('invalid-credential'), contains('incorrectos'));
    expect(messageForAuthCode('operation-not-allowed'),
        contains('Authentication'));
    expect(messageForFirebaseCode('unavailable'), contains('conexión'));
    expect(messageForFirebaseCode('permission-denied'), contains('permiso'));
  });

  test('mapea el video local y el documento de Firestore', () {
    final local = LocalVideoModel.fromJson(const {
      'name': 'Escaleras',
      'videoUrl': 'assets/videos/1.mp4',
      'likes': 4,
      'views': 9,
    }).toVideoPostEntity(id: 'local-1');

    expect(local.isLocal, isTrue);
    expect(local.caption, 'Escaleras');
    expect(local.id, 'local-1');

    final createdAt = DateTime.utc(2024, 5, 1, 12);
    final remote = VideoPostModel.fromMap(
        'abc',
        {
          'id': 'abc',
          'uid': 'user-2',
          'authorName': 'Bruno',
          'caption': 'Hola',
          'videoUrl': 'https://cdn.example/video.mp4',
          'likes': 1,
          'views': 2,
          'createdAt': Timestamp.fromDate(createdAt),
        },
        isLiked: true);

    expect(remote.uid, 'user-2');
    expect(remote.authorName, 'Bruno');
    expect(remote.createdAt.toUtc(), createdAt.toUtc());
    expect(remote.isLiked, isTrue);
    expect(remote.isLocal, isFalse);
  });
}
