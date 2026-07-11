class MaintenanceHistory {
  final String id;
  final String vehicleId;
  final String? maintenanceTypeId;
  final String title;
  final String? description;
  final int? km;
  final double? cost;
  final String? garageName;
  final DateTime doneAt;
  final String? invoiceUrl;
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
    required this.doneAt,
    this.invoiceUrl,
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
        doneAt: DateTime.parse(j['done_at'] as String),
        invoiceUrl: j['invoice_url'] as String?,
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
        'done_at': doneAt.toIso8601String(),
        'invoice_url': invoiceUrl,
      };
}
