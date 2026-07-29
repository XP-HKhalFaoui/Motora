import '../core/formatters.dart';

/// What a ledger row actually is.
///
/// `maintenance_history` was always more than its name suggests: it held
/// interventions plus fuel fill-ups, told apart by an `is_fuel` boolean.
/// Expenses make that a three-way distinction, which a boolean can no
/// longer carry.
enum HistoryEntryKind {
  maintenance,
  fuel,

  /// Money spent on the car that isn't an intervention and isn't fuel —
  /// insurance, vignette, tolls, fines. Carries a [ExpenseCategories]
  /// category and never touches a maintenance type's anchor.
  expense;

  static HistoryEntryKind fromJson(Map<String, dynamic> j) {
    switch (j['kind'] as String?) {
      case 'fuel':
        return HistoryEntryKind.fuel;
      case 'expense':
        return HistoryEntryKind.expense;
      case 'maintenance':
        return HistoryEntryKind.maintenance;
    }
    // Rows written before migration 0007 only have the boolean.
    return (j['is_fuel'] as bool? ?? false)
        ? HistoryEntryKind.fuel
        : HistoryEntryKind.maintenance;
  }
}

class MaintenanceHistory {
  final String id;
  final String vehicleId;
  final String? maintenanceTypeId;
  final String title;
  final String? description;
  final int? km;
  final double? cost;
  final String? garageName;
  final String? garageId;
  final DateTime doneAt;
  final String? invoiceUrl;
  final HistoryEntryKind kind;

  /// One of [ExpenseCategories.all] — set only when [kind] is
  /// [HistoryEntryKind.expense].
  final String? category;

  final double? liters;

  /// Whether the tank was brimmed. Only the stretch between two full tanks
  /// yields a meaningful L/100km, so partial fills are accumulated rather
  /// than measured (see [FuelService]).
  final bool isFullTank;

  final DateTime? createdAt;

  const MaintenanceHistory({
    required this.id,
    required this.vehicleId,
    this.maintenanceTypeId,
    required this.title,
    this.description,
    this.km,
    this.cost,
    this.garageName,
    this.garageId,
    required this.doneAt,
    this.invoiceUrl,
    this.kind = HistoryEntryKind.maintenance,
    this.category,
    this.liters,
    this.isFullTank = true,
    this.createdAt,
  });

  bool get isFuel => kind == HistoryEntryKind.fuel;
  bool get isExpense => kind == HistoryEntryKind.expense;
  bool get isMaintenance => kind == HistoryEntryKind.maintenance;

  factory MaintenanceHistory.fromJson(Map<String, dynamic> j) =>
      MaintenanceHistory(
        id: j['id'] as String,
        vehicleId: j['vehicle_id'] as String,
        maintenanceTypeId: j['maintenance_type_id'] as String?,
        title: j['title'] as String,
        description: j['description'] as String?,
        km: (j['km'] as num?)?.toInt(),
        cost: (j['cost'] as num?)?.toDouble(),
        garageName: j['garage_name'] as String?,
        garageId: j['garage_id'] as String?,
        doneAt: DateTime.parse(j['done_at'] as String),
        invoiceUrl: j['invoice_url'] as String?,
        kind: HistoryEntryKind.fromJson(j),
        category: j['category'] as String?,
        liters: (j['liters'] as num?)?.toDouble(),
        isFullTank: j['is_full_tank'] as bool? ?? true,
        createdAt: j['created_at'] == null
            ? null
            : DateTime.parse(j['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toInsert() => {
        'vehicle_id': vehicleId,
        'maintenance_type_id': maintenanceTypeId,
        'title': title,
        'description': description,
        'km': km,
        'cost': cost,
        'garage_name': garageName,
        'garage_id': garageId,
        'done_at': Fmt.isoDate(doneAt),
        'invoice_url': invoiceUrl,
        'kind': kind.name,
        'category': category,
        // Kept in sync so an APK built before migration 0007 still reads
        // fuel entries correctly. Can go once no such install remains.
        'is_fuel': isFuel,
        'liters': liters,
        'is_full_tank': isFullTank,
      };
}
