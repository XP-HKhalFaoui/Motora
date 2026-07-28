import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'auth_provider.dart';
import 'document_provider.dart';
import 'garage_provider.dart';
import 'maintenance_provider.dart';
import 'notification_provider.dart';
import 'ui_state_provider.dart';
import 'vehicle_provider.dart';

final sessionControllerProvider =
    Provider<SessionController>(SessionController.new);

/// Owns the transition between signed-in accounts.
///
/// Signing out used to only clear the Supabase session: every Riverpod
/// cache kept the previous account's rows, so signing into a second account
/// on the same device showed the first account's vehicles, garages and
/// documents until something happened to refetch — and the previous user's
/// maintenance reminders kept firing on the device.
class SessionController {
  SessionController(this.ref);
  final Ref ref;

  Future<void> signOut() async {
    await ref.read(authControllerProvider).signOut();
    await NotificationService.instance.cancelAll();
    resetUserScopedData();
  }

  /// Deletes the account server-side, then tears down the local session
  /// exactly as a sign-out would.
  Future<void> deleteAccount() async {
    await ref.read(authControllerProvider).deleteAccount();
    // The JWT is dead once the user row is gone, so signOut() may well
    // fail against the server; the local session still has to go.
    try {
      await ref.read(authControllerProvider).signOut();
    } catch (_) {
      // Already unusable — nothing to recover.
    }
    await NotificationService.instance.cancelAll();
    resetUserScopedData();
  }

  /// Drops every cached provider that holds rows belonging to one account.
  ///
  /// Passing a family provider invalidates all of its instances, so this
  /// covers per-vehicle caches without having to know which vehicle ids
  /// were visited.
  void resetUserScopedData() {
    ref.invalidate(vehiclesProvider);
    ref.invalidate(mileageLogsProvider);
    ref.invalidate(maintenanceTypesProvider);
    ref.invalidate(maintenanceHistoryProvider);
    ref.invalidate(predictionsProvider);
    ref.invalidate(documentsProvider);
    ref.invalidate(garagesProvider);
    ref.invalidate(garageCountsProvider);
    ref.invalidate(remindersProvider);
    ref.invalidate(selectedVehicleIdProvider);
  }
}
