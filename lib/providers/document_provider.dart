import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/admin_document.dart';
import 'service_providers.dart';

/// Administrative documents for a vehicle (ordered by expiry).
final documentsProvider =
    FutureProvider.family<List<AdminDocument>, String>((ref, vehicleId) async {
  return ref.read(supabaseServiceProvider).fetchDocuments(vehicleId);
});

final documentControllerProvider =
    Provider<DocumentController>((ref) => DocumentController(ref));

class DocumentController {
  DocumentController(this.ref);
  final Ref ref;

  Future<void> add(AdminDocument d) async {
    await ref.read(supabaseServiceProvider).addDocument(d);
    ref.invalidate(documentsProvider(d.vehicleId));
  }

  Future<void> update(AdminDocument d) async {
    await ref.read(supabaseServiceProvider).updateDocument(d);
    ref.invalidate(documentsProvider(d.vehicleId));
  }

  /// Removes the row *and* its scan. Deleting only the row would strand
  /// the object in the bucket forever — nothing else references it.
  Future<void> remove(String vehicleId, String id, {String? fileUrl}) async {
    final service = ref.read(supabaseServiceProvider);
    await service.deleteDocument(id);
    await service.deleteFile(Buckets.adminDocuments, fileUrl);
    ref.invalidate(documentsProvider(vehicleId));
  }
}
