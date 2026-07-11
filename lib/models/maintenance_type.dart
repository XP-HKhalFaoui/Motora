class MaintenanceType {
  final String id;
  final String vehicleId;
  final String label;
  final int? intervalKm;
  final int? intervalMonths;
  final int? lastDoneKm;
  final DateTime? lastDoneDate;
  final String? icon;

  const MaintenanceType({
    required this.id,
    required this.vehicleId,
    required this.label,
    this.intervalKm,
    this.intervalMonths,
    this.lastDoneKm,
    this.lastDoneDate,
    this.icon,
  });

  factory MaintenanceType.fromJson(Map<String, dynamic> j) => MaintenanceType(
        id: j['id'] as String,
        vehicleId: j['vehicle_id'] as String,
        label: j['label'] as String,
        intervalKm: (j['interval_km'] as num?)?.toInt(),
        intervalMonths: (j['interval_months'] as num?)?.toInt(),
        lastDoneKm: (j['last_done_km'] as num?)?.toInt(),
        lastDoneDate: j['last_done_date'] == null
            ? null
            : DateTime.parse(j['last_done_date'] as String),
        icon: j['icon'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'vehicle_id': vehicleId,
        'label': label,
        'interval_km': intervalKm,
        'interval_months': intervalMonths,
        'last_done_km': lastDoneKm,
        'last_done_date': lastDoneDate?.toIso8601String(),
        'icon': icon,
      };

  MaintenanceType copyWith({
    int? lastDoneKm,
    DateTime? lastDoneDate,
  }) =>
      MaintenanceType(
        id: id,
        vehicleId: vehicleId,
        label: label,
        intervalKm: intervalKm,
        intervalMonths: intervalMonths,
        lastDoneKm: lastDoneKm ?? this.lastDoneKm,
        lastDoneDate: lastDoneDate ?? this.lastDoneDate,
        icon: icon,
      );
}
