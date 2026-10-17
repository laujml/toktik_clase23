import 'package:flutter/material.dart';
import 'package:toktok/config/feed_config.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/widgets/shared/video_buttons.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_player.dart';

class VideoScrollableView extends StatefulWidget {
  const VideoScrollableView({
    super.key,
    required this.videos,
    required this.onNearEnd,
    required this.isLoadingMore,
    this.playbackEnabled = true,
  });

  final List<VideoPost> videos;
  final VoidCallback onNearEnd;
  final bool isLoadingMore;
  final bool playbackEnabled;

  @override
  State<VideoScrollableView> createState() => _VideoScrollableViewState();
}

class _VideoScrollableViewState extends State<VideoScrollableView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoScrollableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadVideos = oldWidget.videos.isNotEmpty;
    final hasVideos = widget.videos.isNotEmpty;
    if (widget.videos.isNotEmpty && _currentIndex >= widget.videos.length) {
      _currentIndex = widget.videos.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(_currentIndex);
      });
    }
    if (!hadVideos || !hasVideos) return;
    if (widget.videos.first.id == oldWidget.videos.first.id) return;

    _currentIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(0);
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    if (FeedConfig.shouldPrefetch(
        index: index, itemCount: widget.videos.length)) {
      widget.onNearEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.videos.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                FullScreenPlayer(
                  key: ValueKey(video.id),
                  caption: video.caption,
                  videoUrl: video.videoUrl,
                  authorName: video.authorName,
                  isActive: widget.playbackEnabled && index == _currentIndex,
                ),
                Positioned(
                  bottom: 40 + bottomInset,
                  right: 12,
                  child: VideoButtons(video: video),
                ),
              ],
            );
          },
        ),
        if (widget.isLoadingMore)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16 + bottomInset,
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
