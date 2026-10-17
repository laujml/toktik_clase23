import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/helpers/human_formats.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';

class VideoButtons extends StatelessWidget {
  const VideoButtons({super.key, required this.video});

  final VideoPost video;

  @override
  Widget build(BuildContext context) {
    final likeLabel = video.isLiked ? 'Quitar me gusta' : 'Me gusta';
    final uid = context.watch<AuthProvider>().uid;
    final canDelete = !video.isLocal && video.uid.isNotEmpty && video.uid == uid;

    return Column(
      children: [
        Semantics(
          button: true,
          label: likeLabel,
          child: IconButton(
            onPressed: () => _toggleLike(context),
            icon: Icon(
              video.isLiked ? Icons.favorite : Icons.favorite_border,
              color: video.isLiked ? Colors.red : Colors.white,
              size: 30,
            ),
          ),
        ),
        Text(HumanFormats.humanReadableNumber(video.likes.toDouble())),
        const SizedBox(height: 20),
        Semantics(
          label:
              'Reproducciones ${HumanFormats.humanReadableNumber(video.views.toDouble())}',
          child: const Icon(Icons.remove_red_eye_outlined,
              color: Colors.white, size: 30),
        ),
        Text(HumanFormats.humanReadableNumber(video.views.toDouble())),
        const SizedBox(height: 20),
        const ExcludeSemantics(
          child: SpinPerfect(
            infinite: true,
            duration: Duration(seconds: 5),
            child:
                Icon(Icons.play_circle_outline, color: Colors.white, size: 30),
          ),
        ),
        if (canDelete) ...[
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: 'Borrar video',
            child: IconButton(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Borrar video'),
          content: const Text(
            'Se borra este video para todos. No se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final uid = context.read<AuthProvider>().uid;
    final message =
        await context.read<DiscoverProvider>().deleteVideo(video, uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Video borrado.')),
    );
  }

  Future<void> _toggleLike(BuildContext context) async {
    final uid = context.read<AuthProvider>().uid;
    final message =
        await context.read<DiscoverProvider>().toggleLike(video, uid);
    if (!context.mounted || message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
