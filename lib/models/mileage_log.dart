class MileageLog {
  final String id;
  final String vehicleId;
  final int km;
  final DateTime recordedAt;
  final String? note;
  final String? photoUrl;

  const MileageLog({
    required this.id,
    required this.vehicleId,
    required this.km,
    required this.recordedAt,
    this.note,
    this.photoUrl,
  });

  /// A reading backed by an odometer photo is "certifié"; a manually
  /// typed one is "déclaratif".
  bool get isCertified => photoUrl != null;

  factory MileageLog.fromJson(Map<String, dynamic> j) => MileageLog(
        id: j['id'] as String,
        vehicleId: j['vehicle_id'] as String,
        km: (j['km'] as num).toInt(),
        recordedAt: DateTime.parse(j['recorded_at'] as String).toLocal(),
        note: j['note'] as String?,
        photoUrl: j['photo_url'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'vehicle_id': vehicleId,
        'km': km,
        if (note != null) 'note': note,
        if (photoUrl != null) 'photo_url': photoUrl,
      };
}
