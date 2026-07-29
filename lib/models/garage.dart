/// A repair shop / mécanicien — a user-level directory entry that
/// interventions ([MaintenanceHistory]) can be attached to.
class Garage {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final DateTime? createdAt;

  const Garage({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    this.createdAt,
  });

  factory Garage.fromJson(Map<String, dynamic> j) => Garage(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        address: j['address'] as String?,
        note: j['note'] as String?,
        createdAt: j['created_at'] == null
            ? null
            : DateTime.parse(j['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toInsert() => {
        'name': name,
        'phone': phone,
        'address': address,
        'note': note,
      };
}
