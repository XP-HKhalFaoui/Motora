class Vehicle {
  final String id;
  final String userId;
  final String name;
  final String? brand;
  final String? model;
  final int? year;
  final String? plateNumber;
  final int currentKm;
  final DateTime? purchaseDate;
  final String? photoUrl;
  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.name,
    this.brand,
    this.model,
    this.year,
    this.plateNumber,
    this.currentKm = 0,
    this.purchaseDate,
    this.photoUrl,
    this.createdAt,
  });

  String get displayTitle {
    final parts = [brand, model].where((e) => e != null && e.isNotEmpty);
    return parts.isEmpty ? name : '$name · ${parts.join(' ')}';
  }

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        name: j['name'] as String,
        brand: j['brand'] as String?,
        model: j['model'] as String?,
        year: j['year'] as int?,
        plateNumber: j['plate_number'] as String?,
        currentKm: (j['current_km'] as num?)?.toInt() ?? 0,
        purchaseDate: _date(j['purchase_date']),
        photoUrl: j['photo_url'] as String?,
        createdAt: _ts(j['created_at']),
      );

  /// Fields writable by the client (id/user_id/created_at managed elsewhere).
  Map<String, dynamic> toInsert() => {
        'name': name,
        'brand': brand,
        'model': model,
        'year': year,
        'plate_number': plateNumber,
        'current_km': currentKm,
        'purchase_date': purchaseDate?.toIso8601String(),
        'photo_url': photoUrl,
      };

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);
  static DateTime? _ts(dynamic v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();
}
