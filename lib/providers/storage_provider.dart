import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

/// A file stored in Supabase Storage, as persisted in the database.
///
/// [reference] is an object path for anything written since the switch away
/// from year-long signed URLs, and a full (possibly expired) signed URL for
/// older rows; [SupabaseService.resolveUrl] handles both.
class StorageRef {
  const StorageRef(this.bucket, this.reference);

  final String bucket;
  final String reference;

  @override
  bool operator ==(Object other) =>
      other is StorageRef &&
      other.bucket == bucket &&
      other.reference == reference;

  @override
  int get hashCode => Object.hash(bucket, reference);
}

/// A short-lived signed URL for [StorageRef], minted on demand.
///
/// Riverpod caches it for the session, so a list doesn't re-sign the same
/// object on every rebuild.
final signedUrlProvider =
    FutureProvider.family<String?, StorageRef>((ref, storageRef) async {
  return ref
      .read(supabaseServiceProvider)
      .resolveUrl(storageRef.bucket, storageRef.reference);
});
