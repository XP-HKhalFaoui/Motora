import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/storage_provider.dart';

/// Displays an image held in a private Supabase bucket.
///
/// The database stores an object path, not a URL, so the URL has to be
/// signed before the image can load — hence the async wrapper around what
/// would otherwise be a plain [Image.network]. [fallback] covers all three
/// failure modes: no reference, signing failed, or the bytes wouldn't
/// decode.
class StorageImage extends ConsumerWidget {
  const StorageImage({
    super.key,
    required this.bucket,
    required this.reference,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String bucket;
  final String? reference;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = this.reference;
    if (reference == null || reference.isEmpty) return fallback;

    final url = ref.watch(signedUrlProvider(StorageRef(bucket, reference)));
    return url.when(
      loading: () => fallback,
      error: (_, __) => fallback,
      data: (resolved) {
        if (resolved == null) return fallback;
        return Image.network(
          resolved,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => fallback,
        );
      },
    );
  }
}
