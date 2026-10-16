class FeedConfig {
  const FeedConfig._();

  static const int pageSize = 5;

  /// Prefetch when this many videos are still ahead of the current page.
  static const int prefetchWhenRemaining = 2;

  static bool shouldPrefetch({required int index, required int itemCount}) {
    if (itemCount <= 0 || index < 0) return false;
    final remainingAfterCurrent = itemCount - index - 1;
    return remainingAfterCurrent <= prefetchWhenRemaining;
  }
}
