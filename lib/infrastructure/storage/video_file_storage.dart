abstract class VideoFileStorage {
  Future<String> upload({
    required String filePath,
    required String uid,
    required void Function(double progress) onProgress,
  });

  Future<void> deleteStoredFile({required String videoUrl});
}
