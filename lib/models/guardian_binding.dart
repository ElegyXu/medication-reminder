enum BindingStatus { active, pending, rejected, revoked }

class GuardianBinding {
  final String id;
  final String patientPhone;
  final String patientNickname;
  final String guardianPhone;
  final BindingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  GuardianBinding({
    required this.id,
    required this.patientPhone,
    required this.patientNickname,
    required this.guardianPhone,
    this.status = BindingStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case BindingStatus.active: return '已绑定';
      case BindingStatus.pending: return '待确认';
      case BindingStatus.rejected: return '已拒绝';
      case BindingStatus.revoked: return '已解除';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_phone': patientPhone,
    'patient_nickname': patientNickname,
    'guardian_phone': guardianPhone,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory GuardianBinding.fromMap(Map<String, dynamic> map) => GuardianBinding(
    id: map['id'],
    patientPhone: map['patient_phone'],
    patientNickname: map['patient_nickname'],
    guardianPhone: map['guardian_phone'],
    status: BindingStatus.values.byName(map['status']),
    createdAt: DateTime.parse(map['created_at']),
    updatedAt: DateTime.parse(map['updated_at']),
  );
}
