import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';
import 'package:video_player/video_player.dart';

class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.caption,
    required this.authorName,
    required this.isActive,
  });

  final String videoUrl;
  final String caption;
  final String authorName;
  final bool isActive;

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late final VideoPlayerController controller;
  bool _ready = false;
  bool _failed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl;
    controller = url.startsWith('assets/')
        ? VideoPlayerController.asset(url)
        : VideoPlayerController.networkUrl(Uri.parse(url));
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await controller.initialize();
      if (_disposed || !mounted) return;
      await controller.setLooping(true);
      if (_disposed || !mounted) return;
      await controller.setVolume(1);
      if (_disposed || !mounted) return;
      setState(() => _ready = true);
      if (widget.isActive) {
        await controller.play();
      }
      if (_disposed || !mounted) return;
      if (!widget.isActive && controller.value.isPlaying) {
        await controller.pause();
      }
    } catch (_) {
      if (_disposed || !mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant FullScreenPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready || _disposed || oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_ready) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      final message = widget.videoUrl.startsWith('assets/')
          ? 'Este es un video de ejemplo y el archivo no está en el emulador.'
          : 'No se pudo reproducir el video. Revisá tu conexión.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.authorName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.caption,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (!_ready) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final isPlaying = controller.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          const VideoBackground(stops: [0.8, 1.0]),
          if (!isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 72, color: Colors.white70),
            ),
          Positioned(
            left: 20,
            right: 88,
            bottom: 50 + MediaQuery.paddingOf(context).bottom,
            child: _VideoCaption(
              caption: widget.caption,
              authorName: widget.authorName,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCaption extends StatelessWidget {
  const _VideoCaption({
    required this.caption,
    required this.authorName,
  });

  final String caption;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width < 600 ? size.width * 0.62 : 360.0;
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
