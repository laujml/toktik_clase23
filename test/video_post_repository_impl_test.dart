import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/domain/datasources/video_post_datasource.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/repositories/video_post_repository_impl.dart';

import 'support/fakes.dart';

void main() {
  test('agrega los videos locales cuando Firestore ya no tiene más páginas',
      () async {
    final remote = _PageDatasource([
      [sampleVideo(id: 'remoto-1')],
    ]);
    final repository = VideoPostRepositoryImpl(
      remoteDatasource: remote,
      localVideos: [sampleVideo(id: 'local-1', isLocal: true)],
    );

    final first = await repository.loadNextPage(currentUid: 'user-1');
    final second = await repository.loadNextPage(currentUid: 'user-1');

    expect(first.map((video) => video.id), ['remoto-1', 'local-1']);
    expect(second, isEmpty);
    expect(repository.hasMore, isFalse);
  });

  test('no mezcla los locales mientras todavía hay páginas remotas', () async {
    final remote = _PageDatasource([
      [sampleVideo(id: 'remoto-1')],
      [sampleVideo(id: 'remoto-2')],
    ]);
    final repository = VideoPostRepositoryImpl(
      remoteDatasource: remote,
      localVideos: [sampleVideo(id: 'local-1', isLocal: true)],
    );

    final first = await repository.loadNextPage(currentUid: 'user-1');
    expect(first.map((video) => video.id), ['remoto-1']);
    expect(repository.hasMore, isTrue);

    final second = await repository.loadNextPage(currentUid: 'user-1');
    expect(second.map((video) => video.id), ['remoto-2', 'local-1']);
  });
}

class _PageDatasource implements VideoPostDatasource {
  _PageDatasource(this._pages);

  final List<List<VideoPost>> _pages;
  int _index = 0;

  @override
  bool hasMore = true;

  @override
  void reset() {
    _index = 0;
    hasMore = true;
  }

  @override
  Future<List<VideoPost>> loadNextPage({
    required String? currentUid,
    int limit = 5,
  }) async {
    if (_index >= _pages.length) {
      hasMore = false;
      return const [];
    }
    final page = _pages[_index];
    _index++;
    hasMore = _index < _pages.length;
    return page;
  }

  @override
  Future<VideoPost> toggleLike({
    required VideoPost video,
    required String uid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VideoPost> uploadVideo({
    required String filePath,
    required String caption,
    required String uid,
    required String authorName,
    required void Function(double progress) onProgress,
  }) {
    throw UnimplementedError();
  }
}
