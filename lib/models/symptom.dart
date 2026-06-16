class Symptom {
  final String id;
  final String name;
  final int severity; // 1-5
  final String? notes;
  final String? relatedMedicineId;
  final String? relatedMedicineName;
  final DateTime createdAt;

  Symptom({
    required this.id,
    required this.name,
    required this.severity,
    this.notes,
    this.relatedMedicineId,
    this.relatedMedicineName,
    required this.createdAt,
  });

  String get severityLabel {
    switch (severity) {
      case 1: return '很轻';
      case 2: return '轻度';
      case 3: return '中度';
      case 4: return '较重';
      case 5: return '严重';
      default: return '未知';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'severity': severity,
    'notes': notes,
    'related_medicine_id': relatedMedicineId,
    'related_medicine_name': relatedMedicineName,
    'created_at': createdAt.toIso8601String(),
  };

  factory Symptom.fromMap(Map<String, dynamic> map) => Symptom(
    id: map['id'],
    name: map['name'],
    severity: map['severity'],
    notes: map['notes'],
    relatedMedicineId: map['related_medicine_id'],
    relatedMedicineName: map['related_medicine_name'],
    createdAt: DateTime.parse(map['created_at']),
  );
}
