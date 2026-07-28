/// Resolving what the database stores for an uploaded file.
///
/// Rows written today hold a plain object path (`<uid>/<filename>`). Rows
/// written before that held a full signed URL with a one-year expiry, which
/// nothing ever refreshed — so those files break permanently once the year
/// is up. The path is still embedded in the URL, so it can be recovered and
/// re-signed rather than lost.
library;

/// The storage object path for [reference], or null if it can't be derived.
String? storagePathFor(String bucket, String? reference) {
  if (reference == null || reference.isEmpty) return null;
  if (!reference.startsWith('http')) return reference;

  // .../object/sign/<bucket>/<uid>/<file>?token=...
  final marker = '/$bucket/';
  final start = reference.indexOf(marker);
  if (start < 0) return null;

  final path = reference.substring(start + marker.length).split('?').first;
  if (path.isEmpty) return null;
  return Uri.decodeComponent(path);
}
