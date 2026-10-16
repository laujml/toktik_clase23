import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/helpers/auth_validators.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/upload_provider.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _captionFocus = FocusNode();
  final _picker = ImagePicker();

  XFile? _video;
  String? _fileError;

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickVideo(source: source);
      if (!mounted || file == null) return;
      setState(() {
        _video = file;
        _fileError = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la galería o la cámara.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    final video = _video;
    if (video == null) {
      setState(() => _fileError = 'Elegí un video de la galería o grabá uno.');
    }
    if (form == null || !form.validate() || video == null) return;

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final created = await context.read<UploadProvider>().upload(
          filePath: video.path,
          caption: _captionController.text,
          uid: auth.uid,
          authorName: auth.authorName,
        );
    if (!mounted) return;

    if (created == null) {
      final message = context.read<UploadProvider>().errorMessage ??
          'No se pudo subir el video.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    Navigator.of(context).pop<VideoPost>(created);
  }

  @override
  Widget build(BuildContext context) {
    final upload = context.watch<UploadProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final percent = (upload.progress * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Subir video')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: width < 600 ? 24 : width * 0.12,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _video == null
                          ? 'Todavía no elegiste un video.'
                          : 'Video: ${_video!.name}',
                    ),
                    if (_fileError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _fileError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Semantics(
                          button: true,
                          label: 'Elegir video de la galería',
                          child: OutlinedButton.icon(
                            onPressed: upload.isUploading
                                ? null
                                : () => _pick(ImageSource.gallery),
                            icon: const Icon(Icons.video_library_outlined),
                            label: const Text('Galería'),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Grabar video con la cámara',
                          child: OutlinedButton.icon(
                            onPressed: upload.isUploading
                                ? null
                                : () => _pick(ImageSource.camera),
                            icon: const Icon(Icons.videocam_outlined),
                            label: const Text('Cámara'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _captionController,
                      focusNode: _captionFocus,
                      textInputAction: TextInputAction.done,
                      maxLength: 150,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        alignLabelWithHint: true,
                      ),
                      validator: AuthValidators.caption,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),
                    if (upload.isUploading) ...[
                      Semantics(
                        label: 'Progreso de subida',
                        value: '$percent por ciento',
                        child: LinearProgressIndicator(
                          value: upload.progress == 0 ? null : upload.progress,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Subiendo… $percent%'),
                      const SizedBox(height: 12),
                    ],
                    Semantics(
                      button: true,
                      label: 'Publicar video',
                      child: FilledButton(
                        onPressed: upload.isUploading ? null : _submit,
                        child: const Text('Publicar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
