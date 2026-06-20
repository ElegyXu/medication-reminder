import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine.dart';
import '../../providers/medicine_provider.dart';

class MedicineFormScreen extends StatefulWidget {
  final Medicine? medicine;
  const MedicineFormScreen({super.key, this.medicine});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _specController;
  late TextEditingController _notesController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;
  String _dosageForm = '片剂';
  int _colorValue = 0xFFC62828;

  final List<String> _dosageForms = ['片剂', '胶囊', '口服液', '颗粒', '丸剂', '注射剂', '外用', '其他'];
  final List<Color> _medicineColors = [
    const Color(0xFFC62828),  // 红 (seed red)
    const Color(0xFFA31520),  // 深红 (primary)
    const Color(0xFF8D4E2A),  // 红棕
    const Color(0xFF5C7A2E),  // 绿棕
    const Color(0xFF2E7D32),  // 深绿
    const Color(0xFF1B6D1B),  // 绿 (tertiary)
  ];

  bool get isEditing => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _nameController = TextEditingController(text: m?.name ?? '');
    _specController = TextEditingController(text: m?.specification ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');
    _stockController = TextEditingController(text: m?.currentStock.toString() ?? '0.0');
    _thresholdController = TextEditingController(text: m?.alertThreshold.toString() ?? '0.0');
    if (m != null) {
      _dosageForm = m.dosageForm;
      _colorValue = m.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specController.dispose();
    _notesController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<MedicineProvider>();

    if (isEditing) {
      final updated = widget.medicine!.copyWith(
        name: _nameController.text.trim(),
        dosageForm: _dosageForm,
        specification: _specController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        colorValue: _colorValue,
        currentStock: double.tryParse(_stockController.text.trim()) ?? 0.0,
        alertThreshold: double.tryParse(_thresholdController.text.trim()) ?? 0.0,
        updatedAt: DateTime.now(),
      );
      await provider.updateMedicineData(updated);
    } else {
      await provider.addMedicine(
        name: _nameController.text.trim(),
        dosageForm: _dosageForm,
        specification: _specController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        colorValue: _colorValue,
        currentStock: double.tryParse(_stockController.text.trim()) ?? 0.0,
        alertThreshold: double.tryParse(_thresholdController.text.trim()) ?? 0.0,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '编辑药品' : '添加药品')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '药品名称', hintText: '如：阿莫西林'),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入药品名称' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _dosageForm,
              decoration: const InputDecoration(labelText: '剂型'),
              items: _dosageForms.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) => setState(() => _dosageForm = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specController,
              decoration: const InputDecoration(labelText: '规格', hintText: '如：50mg'),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入规格' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: '备注', hintText: '可选'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(labelText: '当前库存', hintText: '如：30'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _thresholdController,
                    decoration: const InputDecoration(labelText: '低库存预警', hintText: '如：5'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('图标颜色', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _medicineColors.map((c) => GestureDetector(
                onTap: () => setState(() => _colorValue = c.toARGB32()),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: _colorValue == c.toARGB32()
                        ? Border.all(color: Theme.of(context).colorScheme.surface, width: 3)
                        : null,
                    boxShadow: _colorValue == c.toARGB32()
                        ? [BoxShadow(color: c.withAlpha(100), blurRadius: 8, spreadRadius: 1)]
                        : null,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? '保存修改' : '添加药品'),
            ),
          ],
        ),
      ),
    );
  }
}
