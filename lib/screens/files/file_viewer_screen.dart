import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_text.dart';
import '../../core/errors.dart';
import '../../core/storage_paths.dart';
import '../../core/theme.dart';
import '../../providers/storage_provider.dart';

/// Full-screen view of an uploaded invoice or administrative scan.
///
/// Everything the app uploads was previously write-only: files went into
/// storage and no screen could ever open them again. Images are shown
/// inline and pinch-zoomable; anything else (in practice PDFs) is handed
/// to the system viewer, since Motora bundles no PDF renderer.
class FileViewerScreen extends ConsumerWidget {
  const FileViewerScreen({
    super.key,
    required this.bucket,
    required this.reference,
    required this.title,
  });

  final String bucket;
  final String reference;
  final String title;

  static Future<void> open(
    BuildContext context, {
    required String bucket,
    required String reference,
    required String title,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(
          bucket: bucket,
          reference: reference,
          title: title,
        ),
      ),
    );
  }

  @visibleForTesting
  bool get isImage {
    final path = storagePathFor(bucket, reference) ?? reference;
    final ext = path.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp', 'heic', 'gif'}.contains(ext);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final url = ref.watch(signedUrlProvider(StorageRef(bucket, reference)));

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        title: Text(title, style: AppText.screenTitle(p.textPrimary, size: 17)),
        actions: [
          if (url.valueOrNull != null)
            IconButton(
              tooltip: 'Ouvrir dans une autre application',
              icon: Icon(Icons.open_in_new, color: p.textSecondary),
              onPressed: () => _openExternally(context, url.value!),
            ),
        ],
      ),
      body: url.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          icon: Icons.error_outline,
          text: friendlyError(e),
          color: p.danger,
        ),
        data: (resolved) {
          if (resolved == null) {
            return _Message(
              icon: Icons.insert_drive_file_outlined,
              text: 'Fichier introuvable.',
              color: p.textMuted,
            );
          }
          if (!isImage) {
            return _ExternalOnly(
              onOpen: () => _openExternally(context, resolved),
            );
          }
          return InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.network(
                resolved,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => _Message(
                  icon: Icons.broken_image_outlined,
                  text: "L'image n'a pas pu être chargée.",
                  color: p.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openExternally(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Aucune application ne peut ouvrir ce fichier.")),
      );
    }
  }
}

class _ExternalOnly extends StatelessWidget {
  const _ExternalOnly({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 56, color: p.textMuted),
            const SizedBox(height: 14),
            Text(
              'Ce document est un PDF.',
              style: TextStyle(color: p.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Ouvrir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
