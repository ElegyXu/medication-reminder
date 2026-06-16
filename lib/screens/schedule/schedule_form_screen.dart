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
      locale: const Locale('zh'),
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
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

  /// 先弹出时间选择器，选完后再添加到列表
  Future<void> _addTimePoint() async {
    FocusScope.of(context).unfocus();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _TimePickerSheet(initialHour: 8, initialMinute: 0),
    );

    if (result != null && mounted) {
      setState(() {
        _timePoints.add(result);
      });
    }
  }

  Future<void> _pickTime(int index) async {
    FocusScope.of(context).unfocus();

    final parts = _timePoints[index].split(':');
    int hour = 8;
    int minute = 0;
    try {
      hour = int.parse(parts[0]);
      minute = int.parse(parts[1]);
    } catch (_) {}

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TimePickerSheet(initialHour: hour, initialMinute: minute),
    );

    if (result != null && mounted) {
      setState(() {
        _timePoints[index] = result;
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
          clipBehavior: Clip.none,
          children: [
            // 药品选择
            Consumer<MedicineProvider>(
              builder: (context, mp, _) => DropdownButtonFormField<Medicine>(
                initialValue: _selectedMedicine,
                decoration: const InputDecoration(labelText: '关联药品'),
                hint: const Text('请选择药品'),
                validator: (v) => v == null ? '必须选择药品' : null,
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
                    onPressed: _timePoints.length < 5 ? _addTimePoint : null,
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
              SizedBox(
                height: 48,
                child: Row(
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final selected = _selectedWeekDays.contains(day);
                    const labels = ['一', '二', '三', '四', '五', '六', '日'];
                    return Expanded(
                      child: _DayCell(
                        label: labels[i],
                        selected: selected,
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedWeekDays.remove(day);
                            } else {
                              _selectedWeekDays.add(day);
                            }
                          });
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 每月选择
            if (_frequency == ScheduleFrequency.monthly) ...[
              Text('选择日期', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final cellW = (constraints.maxWidth - 6 * 6) / 7;
                  final cellH = cellW / 1.2;
                  final totalH = cellH * 5 + 6 * 4;
                  return SizedBox(
                    height: totalH,
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
                  itemBuilder: (ctx, i) {
                    final day = i + 1;
                    final selected = _selectedMonthDays.contains(day);
                    return _DayCell(
                      label: '$day',
                      selected: selected,
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedMonthDays.remove(day);
                          } else {
                            _selectedMonthDays.add(day);
                          }
                        });
                      },
                    );
                  },
                    ),
                  );
                },
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

// ── Shared day cell for weekly & monthly ──
class _DayCell extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DayCell({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Custom time picker bottom sheet ──
class _TimePickerSheet extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  const _TimePickerSheet({required this.initialHour, required this.initialMinute});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late int _hour;
  late int _minute;
  final _hourCtrl = FixedExtentScrollController();
  final _minuteCtrl = FixedExtentScrollController();

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourCtrl.jumpToItem(_hour);
      _minuteCtrl.jumpToItem(_minute);
    });
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                Text('选择用药时间', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () {
                    final t = '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';
                    Navigator.pop(context, t);
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
            const Divider(),
            // Pickers
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(child: _buildPicker(24, _hourCtrl, (v) => _hour = v, _hour)),
                  _buildColon(cs),
                  Expanded(child: _buildPicker(60, _minuteCtrl, (v) => _minute = v, _minute)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColon(ColorScheme cs) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSurface)),
      ),
    );
  }

  Widget _buildPicker(int count, FixedExtentScrollController ctrl, ValueChanged<int> onChanged, int current) {
    return ListWheelScrollView.useDelegate(
      controller: ctrl,
      itemExtent: 48,
      physics: const FixedExtentScrollPhysics(),
      overAndUnderCenterOpacity: 0.3,
      perspective: 0.002,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (ctx, i) => Center(
          child: Text(
            i.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: i == current
                  ? Theme.of(ctx).colorScheme.primary
                  : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        childCount: count,
      ),
    );
  }
}
