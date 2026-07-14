import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'theme.dart';

/// Lets the user pick an image (camera / gallery) or a PDF file.
///
/// Presents a small bottom sheet and returns the chosen [File], or `null`
/// if the user dismissed it. Used for invoices and administrative scans.
Future<File?> pickAttachment(BuildContext context) async {
  final source = await showModalBottomSheet<_Source>(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _SourcePicker(),
  );
  if (source == null) return null;

  switch (source) {
    case _Source.camera:
    case _Source.gallery:
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: source == _Source.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2000,
      );
      return shot == null ? null : File(shot.path);
    case _Source.pdf:
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final path = result?.files.single.path;
      return path == null ? null : File(path);
  }
}

enum _Source { camera, gallery, pdf }

class _SourcePicker extends StatelessWidget {
  const _SourcePicker();

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: accent),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(context, _Source.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: accent),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(context, _Source.gallery),
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined, color: accent),
            title: const Text('Sélectionner un PDF'),
            onTap: () => Navigator.pop(context, _Source.pdf),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Builds a unique-enough object name from a prefix and a file path,
/// preserving the original extension.
String buildUploadName(String prefix, File file) {
  final ext = file.path.contains('.') ? file.path.split('.').last : 'dat';
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return '$prefix-$stamp.$ext';
}
