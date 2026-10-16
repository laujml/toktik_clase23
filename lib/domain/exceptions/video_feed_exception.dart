class VideoFeedException implements Exception {
  const VideoFeedException(this.message);

  final String message;

  @override
  String toString() => message;
}
