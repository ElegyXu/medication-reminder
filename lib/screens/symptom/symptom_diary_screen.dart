import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/symptom_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../models/medicine.dart';
import '../../theme/app_theme.dart';

class SymptomDiaryScreen extends StatefulWidget {
  const SymptomDiaryScreen({super.key});

  @override
  State<SymptomDiaryScreen> createState() => _SymptomDiaryScreenState();
}

class _SymptomDiaryScreenState extends State<SymptomDiaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SymptomProvider>().loadSymptoms();
      context.read<MedicineProvider>().loadMedicines();
    });
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    double severity = 3;
    Medicine? selectedMedicine;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('记录症状'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '症状名称',
                    hintText: '如：头痛',
                  ),
                ),
                const SizedBox(height: 16),
                Text('严重程度: ${severity.toInt()}级'),
                Slider(
                  value: severity,
                  min: 1, max: 5, divisions: 4,
                  activeColor: AppTheme.primaryColor,
                  label: '${severity.toInt()}级',
                  onChanged: (v) => setDialogState(() => severity = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSeverityChip(1, severity, setDialogState),
                    _buildSeverityChip(2, severity, setDialogState),
                    _buildSeverityChip(3, severity, setDialogState),
                    _buildSeverityChip(4, severity, setDialogState),
                    _buildSeverityChip(5, severity, setDialogState),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<MedicineProvider>(
                  builder: (context, mp, _) => DropdownButtonFormField<Medicine>(
                    initialValue: selectedMedicine,
                    decoration: const InputDecoration(labelText: '关联药品（可选）'),
                    hint: const Text('不关联'),
                    items: [
                      const DropdownMenuItem<Medicine>(value: null, child: Text('不关联')),
                      ...mp.activeMedicines.map((m) =>
                        DropdownMenuItem(value: m, child: Text(m.name))
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => selectedMedicine = v),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await context.read<SymptomProvider>().addSymptom(
                  name: nameController.text.trim(),
                  severity: severity.toInt(),
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  relatedMedicineId: selectedMedicine?.id,
                  relatedMedicineName: selectedMedicine?.name,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityChip(int level, double current, Function setState) {
    final isSelected = current.toInt() == level;
    return GestureDetector(
      onTap: () => setState(() => current = level.toDouble()),
      child: Chip(
        avatar: Icon(
          Icons.star,
          size: 18,
          color: isSelected ? _severityColor(level) : Colors.grey,
        ),
        label: Text('$level', style: TextStyle(
          color: isSelected ? _severityColor(level) : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
        backgroundColor: isSelected ? _severityColor(level).withAlpha(20) : null,
      ),
    );
  }

  Color _severityColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 4: return Colors.deepOrange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('症状日记')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<SymptomProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.symptoms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('暂无记录', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadSymptoms(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.symptoms.length,
              itemBuilder: (context, index) {
                final symptom = provider.symptoms[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _severityColor(symptom.severity).withAlpha(30),
                      child: Text(
                        '${symptom.severity}',
                        style: TextStyle(
                          color: _severityColor(symptom.severity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(symptom.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${symptom.severityLabel} · ${DateFormat('MM-dd HH:mm').format(symptom.createdAt)}'),
                        if (symptom.relatedMedicineName != null)
                          Text('关联: ${symptom.relatedMedicineName}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        if (symptom.notes != null && symptom.notes!.isNotEmpty)
                          Text(symptom.notes!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => provider.removeSymptom(symptom.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
