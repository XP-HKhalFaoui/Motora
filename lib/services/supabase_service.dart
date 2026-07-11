import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/admin_document.dart';
import '../models/maintenance_history.dart';
import '../models/maintenance_type.dart';
import '../models/mileage_log.dart';
import '../models/vehicle.dart';

/// All Supabase reads/writes live here so the rest of the app never talks
/// to the raw client directly.
class SupabaseService {
  SupabaseClient get _c => Db.client;

  // ---------------- Vehicles ----------------------------------------

  Future<List<Vehicle>> fetchVehicles() async {
    final rows = await _c
        .from('vehicles')
        .select()
        .order('created_at', ascending: true);
    return (rows as List).map((e) => Vehicle.fromJson(e)).toList();
  }

  Future<Vehicle> createVehicle(Vehicle v) async {
    final data = v.toInsert()..['user_id'] = Db.uid;
    final row = await _c.from('vehicles').insert(data).select().single();
    return Vehicle.fromJson(row);
  }

  Future<Vehicle> updateVehicle(String id, Map<String, dynamic> patch) async {
    final row =
        await _c.from('vehicles').update(patch).eq('id', id).select().single();
    return Vehicle.fromJson(row);
  }

  Future<void> deleteVehicle(String id) async {
    await _c.from('vehicles').delete().eq('id', id);
  }

  // ---------------- Mileage -----------------------------------------

  Future<List<MileageLog>> fetchMileageLogs(String vehicleId) async {
    final rows = await _c
        .from('mileage_logs')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('recorded_at', ascending: false);
    return (rows as List).map((e) => MileageLog.fromJson(e)).toList();
  }

  /// Insert a reading. A DB trigger keeps vehicles.current_km in sync.
  Future<MileageLog> addMileageLog(String vehicleId, int km,
      {String? note}) async {
    final row = await _c
        .from('mileage_logs')
        .insert({'vehicle_id': vehicleId, 'km': km, if (note != null) 'note': note})
        .select()
        .single();
    return MileageLog.fromJson(row);
  }

  // ---------------- Maintenance types --------------------------------

  Future<List<MaintenanceType>> fetchMaintenanceTypes(String vehicleId) async {
    final rows = await _c
        .from('maintenance_types')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('label', ascending: true);
    return (rows as List).map((e) => MaintenanceType.fromJson(e)).toList();
  }

  Future<MaintenanceType> createMaintenanceType(MaintenanceType t) async {
    final row = await _c
        .from('maintenance_types')
        .insert(t.toInsert())
        .select()
        .single();
    return MaintenanceType.fromJson(row);
  }

  Future<MaintenanceType> updateMaintenanceType(
      String id, Map<String, dynamic> patch) async {
    final row = await _c
        .from('maintenance_types')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return MaintenanceType.fromJson(row);
  }

  Future<void> deleteMaintenanceType(String id) async {
    await _c.from('maintenance_types').delete().eq('id', id);
  }

  // ---------------- Maintenance history ------------------------------

  Future<List<MaintenanceHistory>> fetchHistory(String vehicleId) async {
    final rows = await _c
        .from('maintenance_history')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('done_at', ascending: false);
    return (rows as List).map((e) => MaintenanceHistory.fromJson(e)).toList();
  }

  Future<MaintenanceHistory> addHistory(MaintenanceHistory h) async {
    final row = await _c
        .from('maintenance_history')
        .insert(h.toInsert())
        .select()
        .single();

    // Advance the linked maintenance type's "last done" markers.
    if (h.maintenanceTypeId != null) {
      await _c.from('maintenance_types').update({
        'last_done_km': h.km,
        'last_done_date': h.doneAt.toIso8601String(),
      }).eq('id', h.maintenanceTypeId!);
    }
    return MaintenanceHistory.fromJson(row);
  }

  Future<void> deleteHistory(String id) async {
    await _c.from('maintenance_history').delete().eq('id', id);
  }

  // ---------------- Admin documents ----------------------------------

  Future<List<AdminDocument>> fetchDocuments(String vehicleId) async {
    final rows = await _c
        .from('admin_documents')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('expiry_date', ascending: true);
    return (rows as List).map((e) => AdminDocument.fromJson(e)).toList();
  }

  Future<AdminDocument> addDocument(AdminDocument d) async {
    final row = await _c
        .from('admin_documents')
        .insert(d.toInsert())
        .select()
        .single();
    return AdminDocument.fromJson(row);
  }

  Future<void> deleteDocument(String id) async {
    await _c.from('admin_documents').delete().eq('id', id);
  }

  // ---------------- Storage ------------------------------------------

  /// Uploads [file] to <bucket>/<uid>/<filename> and returns a signed URL.
  Future<String> uploadFile({
    required String bucket,
    required File file,
    required String filename,
  }) async {
    final path = '${Db.uid}/$filename';
    await _c.storage.from(bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    // Signed URL valid for a year — buckets are private.
    return _c.storage.from(bucket).createSignedUrl(path, 60 * 60 * 24 * 365);
  }
}
