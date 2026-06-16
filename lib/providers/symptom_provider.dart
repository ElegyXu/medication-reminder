import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/symptom.dart';
import '../database/database_helper.dart';

class SymptomProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Symptom> _symptoms = [];
  bool _isLoading = false;

  List<Symptom> get symptoms => _symptoms;
  bool get isLoading => _isLoading;

  Future<void> loadSymptoms() async {
    _isLoading = true;
    notifyListeners();
    _symptoms = await _db.getSymptoms();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSymptom({
    required String name,
    required int severity,
    String? notes,
    String? relatedMedicineId,
    String? relatedMedicineName,
  }) async {
    final symptom = Symptom(
      id: const Uuid().v4(),
      name: name,
      severity: severity,
      notes: notes,
      relatedMedicineId: relatedMedicineId,
      relatedMedicineName: relatedMedicineName,
      createdAt: DateTime.now(),
    );
    await _db.insertSymptom(symptom);
    await loadSymptoms();
  }

  Future<void> removeSymptom(String id) async {
    await _db.deleteSymptom(id);
    await loadSymptoms();
  }
}
