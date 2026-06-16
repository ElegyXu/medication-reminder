import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/medicine_provider.dart';

class ScheduleFormScreen extends StatefulWidget {
  final MedicationSchedule? schedule;
  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dosageController = TextEditingController();
  final _prnMaxController = TextEditingController();
  final _prnIntervalController = TextEditingController();

  Medicine? _selectedMedicine;
  ScheduleFrequency _frequency = ScheduleFrequency.daily;
  List<String> _timePoints = ['08:00'];
  List<int> _selectedWeekDays = [1];
  List<int> _selectedMonthDays = [1];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    if (s != null) {
      _isEditing = true;
      _dosageController.text = s.dosage;
      _frequency = s.frequency;
      _timePoints = List.from(s.timePoints);
      _selectedWeekDays = s.weekDays != null ? List.from(s.weekDays!) : [1];
      _selectedMonthDays = s.monthDays != null ? List.from(s.monthDays!) : [1];
      _startDate = s.startDate;
      _endDate = s.endDate;
      _prnMaxController.text = s.prnMaxDaily?.toString() ?? '';
      _prnIntervalController.text = s.prnMinIntervalMinutes?.toString() ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicineProvider>().loadMedicines();
    });
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _prnMaxController.dispose();
    _prnIntervalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择药品')),
      );
      return;
    }

    final provider = context.read<ScheduleProvider>();

    if (_isEditing) {
      final s = widget.schedule!;
      await provider.updateScheduleData(MedicationSchedule(
        id: s.id,
        medicineId: _selectedMedicine!.id,
        medicineName: _selectedMedicine!.name,
        dosage: _dosageController.text.trim(),
        frequency: _frequency,
        timePoints: _timePoints,
        weekDays: _frequency == ScheduleFrequency.weekly ? _selectedWeekDays : null,
        monthDays: _frequency == ScheduleFrequency.monthly ? _selectedMonthDays : null,
        startDate: _startDate,
        endDate: _endDate,
        prnMaxDaily: _frequency == ScheduleFrequency.prn ? int.tryParse(_prnMaxController.text) : null,
        prnMinIntervalMinutes: _frequency == ScheduleFrequency.prn ? int.tryParse(_prnIntervalController.text) : null,
        isActive: s.isActive,
        createdAt: s.createdAt,
        updatedAt: DateTime.now(),
      ));
    } else {
      await provider.addSchedule(
        medicineId: _selectedMedicine!.id,
        medicineName: _selectedMedicine!.name,
        dosage: _dosageController.text.trim(),
        frequency: _frequency,
        timePoints: _timePoints,
        weekDays: _frequency == ScheduleFrequency.weekly ? _selectedWeekDays : null,
        monthDays: _frequency == ScheduleFrequency.monthly ? _selectedMonthDays : null,
        startDate: _startDate,
        endDate: _endDate,
        prnMaxDaily: _frequency == ScheduleFrequency.prn ? int.tryParse(_prnMaxController.text) : null,
        prnMinIntervalMinutes: _frequency == ScheduleFrequency.prn ? int.tryParse(_prnIntervalController.text) : null,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(int index) async {
    if (!mounted) return;

    // Dismiss keyboard first so showTimePicker can use clean context
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    TimeOfDay initialTime;
    try {
      final parts = _timePoints[index].split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      initialTime = const TimeOfDay(hour: 8, minute: 0);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '选择用药时间',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (picked != null && mounted) {
      setState(() {
        _timePoints[index] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑用药计划' : '新建用药计划')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 药品选择
            Consumer<MedicineProvider>(
              builder: (context, mp, _) => DropdownButtonFormField<Medicine>(
                initialValue: _selectedMedicine,
                decoration: const InputDecoration(labelText: '关联药品'),
                hint: const Text('请选择药品'),
                items: mp.activeMedicines.map((m) =>
                  DropdownMenuItem(value: m, child: Text('${m.name} (${m.specification})'))
                ).toList(),
                onChanged: (v) => setState(() => _selectedMedicine = v),
              ),
            ),
            const SizedBox(height: 16),

            // 剂量
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: '剂量', hintText: '如：1片'),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入剂量' : null,
            ),
            const SizedBox(height: 16),

            // 频率选择
            Text('用药频率', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<ScheduleFrequency>(
                segments: const [
                  ButtonSegment(value: ScheduleFrequency.daily, label: Text('每日')),
                  ButtonSegment(value: ScheduleFrequency.weekly, label: Text('每周')),
                  ButtonSegment(value: ScheduleFrequency.monthly, label: Text('每月')),
                  ButtonSegment(value: ScheduleFrequency.prn, label: Text('按需')),
                ],
                selected: {_frequency},
                onSelectionChanged: (v) => setState(() => _frequency = v.first),
              ),
            ),
            const SizedBox(height: 16),

            // 时间点
            if (_frequency != ScheduleFrequency.prn) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('用药时间', style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: _timePoints.length < 5
                        ? () => setState(() => _timePoints.add('12:00'))
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...List.generate(_timePoints.length, (i) {
                final index = i;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickTime(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _timePoints[index],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (_timePoints.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _timePoints.removeAt(index)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // 每周选择
            if (_frequency == ScheduleFrequency.weekly) ...[
              Text('选择星期', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final selected = _selectedWeekDays.contains(day);
                  return FilterChip(
                    label: Text(['', '一', '二', '三', '四', '五', '六', '日'][day]),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedWeekDays.add(day);
                        } else {
                          _selectedWeekDays.remove(day);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],

            // 每月选择
            if (_frequency == ScheduleFrequency.monthly) ...[
              Text('选择日期', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 280,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: 31,
                  itemBuilder: (context, i) {
                    final day = i + 1;
                    final selected = _selectedMonthDays.contains(day);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedMonthDays.remove(day);
                          } else {
                            _selectedMonthDays.add(day);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // PRN配置
            if (_frequency == ScheduleFrequency.prn) ...[
              TextFormField(
                controller: _prnMaxController,
                decoration: const InputDecoration(
                  labelText: '每日最大次数',
                  hintText: '留空不限制',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prnIntervalController,
                decoration: const InputDecoration(
                  labelText: '最小间隔(分钟)',
                  hintText: '两次服药最小间隔',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // 日期范围
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: true),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('开始日期', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: false),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('结束日期', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              _endDate != null
                                  ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                                  : '不限',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        if (_endDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _endDate = null),
                            child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? '保存修改' : '创建计划'),
            ),
          ],
        ),
      ),
    );
  }
}
