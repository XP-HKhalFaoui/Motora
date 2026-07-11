class AdminDocument {
  final String id;
  final String vehicleId;
  final String docType;
  final int year;
  final DateTime? issuedDate;
  final DateTime expiryDate;
  final String? fileUrl;
  final String status;
  final DateTime? createdAt;

  const AdminDocument({
    required this.id,
    required this.vehicleId,
    required this.docType,
    required this.year,
    this.issuedDate,
    required this.expiryDate,
    this.fileUrl,
    this.status = 'pending',
    this.createdAt,
  });

  /// Days until expiry (negative if already expired).
  int get daysToExpiry {
    final now = DateTime.now();
    return expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isExpired => daysToExpiry < 0;

  factory AdminDocument.fromJson(Map<String, dynamic> j) => AdminDocument(
        id: j['id'] as String,
        vehicleId: j['vehicle_id'] as String,
        docType: j['doc_type'] as String,
        year: (j['year'] as num).toInt(),
        issuedDate: j['issued_date'] == null
            ? null
            : DateTime.parse(j['issued_date'] as String),
        expiryDate: DateTime.parse(j['expiry_date'] as String),
        fileUrl: j['file_url'] as String?,
        status: (j['status'] as String?) ?? 'pending',
        createdAt: j['created_at'] == null
            ? null
            : DateTime.parse(j['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toInsert() => {
        'vehicle_id': vehicleId,
        'doc_type': docType,
        'year': year,
        'issued_date': issuedDate?.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'file_url': fileUrl,
        'status': status,
      };
}
