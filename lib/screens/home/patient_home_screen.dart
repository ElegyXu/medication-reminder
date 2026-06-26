import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../models/medicine.dart';
import '../medicine/medicine_form_screen.dart';
import '../schedule/schedule_list_screen.dart';
import '../schedule/schedule_form_screen.dart';
import '../symptom/symptom_diary_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/medicine_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/profile_tab.dart';

class PatientHomeScreen extends StatefulWidget {
  final int initialTab;
  const PatientHomeScreen({super.key, this.initialTab = 0});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  late int _currentTab;

  static const _tabTitles = ['主页', '用药计划', '药品管理', '服药统计', '我的'];
  static const _tabLabels = ['主页', '用药计划', '药品管理', '服药统计', '我的'];
  static const _tabIcons = <IconData>[
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.medication_outlined,
    Icons.bar_chart_outlined,
    Icons.person_outlined,
  ];
  static const _tabSelectedIcons = <IconData>[
    Icons.home,
    Icons.calendar_month,
    Icons.medication,
    Icons.bar_chart,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final reminderProvider = context.read<ReminderProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();
    final medicineProvider = context.read<MedicineProvider>();
    await Future.wait([
      scheduleProvider.loadSchedules(),
      medicineProvider.loadMedicines(),
    ]);
    await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
    await reminderProvider.loadTodayReminders();
  }

  void _navigateToMedicineForm(BuildContext context, {Medicine? medicine}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineFormScreen(medicine: medicine),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<MedicineProvider>().loadMedicines();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_currentTab]),
        actions: null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: IndexedStack(
          key: ValueKey(_currentTab),
          index: _currentTab,
          children: [
            const HomeTab(),
            const ScheduleListScreen(embedded: true),
            const MedicineTab(),
            const StatsTab(),
            const ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() => _currentTab = index);
          if (index == 2) context.read<MedicineProvider>().loadMedicines();
          if (index == 1) context.read<ScheduleProvider>().loadSchedules();
          if (index == 3) _loadData();
        },
        destinations: List.generate(5, (i) => NavigationDestination(
          icon: Icon(_tabIcons[i]),
          selectedIcon: Icon(_tabSelectedIcons[i]),
          label: _tabLabels[i],
        )),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
        child: _currentTab == 0
            ? _buildSmallFAB(
                key: const ValueKey('quick'),
                onPressed: () => _showQuickActions(context),
                icon: Icons.add,
                label: '快捷操作',
              )
            : _currentTab == 1
                ? _buildSmallFAB(
                    key: const ValueKey('schedule'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScheduleFormScreen()),
                      );
                      if (context.mounted) context.read<ScheduleProvider>().loadSchedules();
                    },
                    icon: Icons.add,
                    label: '添加计划',
                  )
                : _currentTab == 2
                    ? _buildSmallFAB(
                        key: const ValueKey('medicine'),
                        onPressed: () => _navigateToMedicineForm(context),
                        icon: Icons.add,
                        label: '添加药品',
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }

  Widget _buildSmallFAB({
    Key? key,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 4),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        elevation: 0,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                title: const Text('添加药品'),
                onTap: () { Navigator.pop(ctx); _navigateToMedicineForm(context); },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(Icons.schedule, color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
                title: const Text('新建用药计划'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleListScreen()));
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.onTertiaryContainer),
                ),
                title: const Text('记录症状'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
