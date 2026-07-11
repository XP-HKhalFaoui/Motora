import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> remove(String vehicleId, String id) async {
    await ref.read(supabaseServiceProvider).deleteDocument(id);
    ref.invalidate(documentsProvider(vehicleId));
  }
}
