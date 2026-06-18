class Medicine {
  final String id;
  final String name;
  final String dosageForm; // 片剂/胶囊/口服液等
  final String specification; // 规格如 50mg
  final String? notes;
  final int colorValue; // 图标颜色
  final double currentStock;
  final double alertThreshold;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.dosageForm,
    required this.specification,
    this.notes,
    this.colorValue = 0xFFC41E3A,
    this.currentStock = 0.0,
    this.alertThreshold = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'dosage_form': dosageForm,
    'specification': specification,
    'notes': notes,
    'color_value': colorValue,
    'current_stock': currentStock,
    'alert_threshold': alertThreshold,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
    id: map['id'],
    name: map['name'],
    dosageForm: map['dosage_form'],
    specification: map['specification'],
    notes: map['notes'],
    colorValue: map['color_value'],
    currentStock: map['current_stock']?.toDouble() ?? 0.0,
    alertThreshold: map['alert_threshold']?.toDouble() ?? 0.0,
    isActive: map['is_active'] == 1,
    createdAt: DateTime.parse(map['created_at']),
    updatedAt: DateTime.parse(map['updated_at']),
  );

  Medicine copyWith({
    String? id,
    String? name,
    String? dosageForm,
    String? specification,
    String? notes,
    int? colorValue,
    double? currentStock,
    double? alertThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Medicine(
    id: id ?? this.id,
    name: name ?? this.name,
    dosageForm: dosageForm ?? this.dosageForm,
    specification: specification ?? this.specification,
    notes: notes ?? this.notes,
    colorValue: colorValue ?? this.colorValue,
    currentStock: currentStock ?? this.currentStock,
    alertThreshold: alertThreshold ?? this.alertThreshold,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
