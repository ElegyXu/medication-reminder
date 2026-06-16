import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../database/database_helper.dart';

class MedicineProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Medicine> get medicines => _medicines;
  List<Medicine> get activeMedicines =>
      _medicines.where((m) => m.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMedicines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _medicines = await _db.getMedicines();
    } catch (e) {
      _errorMessage = '加载失败: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMedicine({
    required String name,
    required String dosageForm,
    required String specification,
    String? notes,
    int colorValue = 0xFFC41E3A,
  }) async {
    final now = DateTime.now();
    final medicine = Medicine(
      id: const Uuid().v4(),
      name: name,
      dosageForm: dosageForm,
      specification: specification,
      notes: notes,
      colorValue: colorValue,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertMedicine(medicine);
    await loadMedicines();
  }

  Future<void> updateMedicineData(Medicine medicine) async {
    final updated = medicine.copyWith(updatedAt: DateTime.now());
    await _db.updateMedicine(updated);
    await loadMedicines();
  }

  Future<void> toggleMedicineActive(Medicine medicine) async {
    final updated = medicine.copyWith(
      isActive: !medicine.isActive,
      updatedAt: DateTime.now(),
    );
    await _db.updateMedicine(updated);
    await loadMedicines();
  }

  Future<void> removeMedicine(String id) async {
    await _db.deleteMedicine(id);
    await loadMedicines();
  }
}
