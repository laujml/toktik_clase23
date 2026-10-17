import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/screens/upload/upload_video_screen.dart';
import 'package:toktok/presentation/widgets/shared/video_scrollable_view.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.playbackEnabled = true});

  final bool playbackEnabled;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  void _load() {
    final uid = context.read<AuthProvider>().uid;
    context.read<DiscoverProvider>().loadNextPage(uid);
  }

  Future<void> _retry() async {
    final uid = context.read<AuthProvider>().uid;
    await context.read<DiscoverProvider>().retry(uid);
  }

  Future<void> _logout() async {
    final error = await context.read<AuthProvider>().signOut();
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _openUpload() async {
    final created = await Navigator.of(context).push<VideoPost>(
      MaterialPageRoute(builder: (_) => const UploadVideoScreen()),
    );
    if (!mounted || created == null) return;
    context.read<DiscoverProvider>().insertUploaded(created);
  }

  @override
  Widget build(BuildContext context) {
    final discover = context.watch<DiscoverProvider>();
    final authorName = context.watch<AuthProvider>().authorName;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (discover.initialLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (discover.videos.isEmpty)
            _EmptyFeed(
              message: discover.errorMessage ??
                  'Todavía no hay videos. Subí el primero.',
              onRetry: _retry,
            )
          else
            VideoScrollableView(
              videos: discover.videos,
              isLoadingMore: discover.isLoading,
              playbackEnabled: widget.playbackEnabled,
              onNearEnd: _load,
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Subir video',
                      child: IconButton(
                        onPressed: _openUpload,
                        icon: const Icon(Icons.add_box_outlined),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Cerrar sesión',
                      child: IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (discover.errorMessage != null && discover.videos.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 56,
              child: Material(
                color: const Color(0xFF5C1A1A),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(discover.errorMessage!),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          button: true,
                          label: 'Reintentar carga de videos',
                          child: TextButton(
                            onPressed: _retry,
                            child: const Text('Reintentar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width < 600 ? 24 : 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Reintentar carga de videos',
                child: FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
