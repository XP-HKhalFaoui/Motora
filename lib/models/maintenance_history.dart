import '../core/formatters.dart';

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
  final bool isFuel;
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
    this.isFuel = false,
    this.liters,
    this.isFullTank = true,
    this.createdAt,
  });

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
        isFuel: j['is_fuel'] as bool? ?? false,
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
        'is_fuel': isFuel,
        'liters': liters,
        'is_full_tank': isFullTank,
      };
}
