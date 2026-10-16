import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';

import 'support/fakes.dart';

void main() {
  test('no dispara dos cargas si loadNextPage se llama otra vez enseguida',
      () async {
    final repository = FakeVideoRepository(
      pages: [
        [sampleVideo()],
      ],
    )..delay = const Duration(milliseconds: 30);
    final provider = DiscoverProvider(repository: repository);

    final first = provider.loadNextPage('user-1');
    final second = provider.loadNextPage('user-1');
    await Future.wait([first, second]);

    expect(repository.calls, 1);
    expect(provider.videos, hasLength(1));
    expect(provider.isLoading, isFalse);
    expect(provider.initialLoading, isFalse);
  });

  test('actualiza el corazón y no deja likear un video local', () async {
    final repository = FakeVideoRepository(
      pages: [
        [sampleVideo(likes: 2)],
      ],
    );
    final provider = DiscoverProvider(repository: repository);
    await provider.loadNextPage('user-1');

    final error =
        await provider.toggleLike(sampleVideo(isLocal: true), 'user-1');
    expect(error, 'Este video de ejemplo no se puede likear.');
    expect(repository.toggled, isNull);

    final result = await provider.toggleLike(provider.videos.single, 'user-1');
    expect(result, isNull);
    expect(provider.videos.single.isLiked, isTrue);
    expect(provider.videos.single.likes, 3);
  });
}
