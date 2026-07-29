import 'package:flutter/material.dart';

import '../models/maintenance_history.dart';
import 'theme.dart';

/// Icon and colour for one ledger entry.
class EntryStyle {
  const EntryStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}

/// How a ledger row is badged.
///
/// A mixed timeline of interventions, fill-ups and expenses is only
/// scannable if each type is recognisable before you read it — which is
/// the whole reason the palette grew a hue per type.
EntryStyle entryStyleFor(AppPalette p, MaintenanceHistory entry) {
  switch (entry.kind) {
    case HistoryEntryKind.fuel:
      return EntryStyle(Icons.local_gas_station, p.entryFuel);
    case HistoryEntryKind.expense:
      return EntryStyle(Icons.receipt_long, p.entryExpense);
    case HistoryEntryKind.maintenance:
      return EntryStyle(Icons.build, p.entryMaintenance);
  }
}
