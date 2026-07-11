class MileageLog {
  final String id;
  final String vehicleId;
  final int km;
  final DateTime recordedAt;
  final String? note;

  const MileageLog({
    required this.id,
    required this.vehicleId,
    required this.km,
    required this.recordedAt,
    this.note,
  });

  factory MileageLog.fromJson(Map<String, dynamic> j) => MileageLog(
        id: j['id'] as String,
        vehicleId: j['vehicle_id'] as String,
        km: (j['km'] as num).toInt(),
        recordedAt: DateTime.parse(j['recorded_at'] as String).toLocal(),
        note: j['note'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'vehicle_id': vehicleId,
        'km': km,
        if (note != null) 'note': note,
      };
}
