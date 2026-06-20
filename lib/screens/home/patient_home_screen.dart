import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../models/reminder.dart';
import '../../models/medicine.dart';
import '../../widgets/reminder_bottom_sheet.dart';
import '../../theme/app_theme.dart';
import '../../utils/lunar_calendar.dart';
import '../medicine/medicine_form_screen.dart';
import '../schedule/schedule_list_screen.dart';
import '../schedule/schedule_form_screen.dart';
import '../symptom/symptom_diary_screen.dart';
import '../guardian/guardian_home_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final int initialTab;
  const PatientHomeScreen({super.key, this.initialTab = 0});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  late int _currentTab;
  String _statsPeriod = 'week'; // week / month / threeMonths

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

  Future<void> _onRefresh() async {
    await _loadData();
  }

  IconData _getStatusIcon(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken: return Icons.check_circle;
      case ReminderStatus.skipped: return Icons.skip_next;
      case ReminderStatus.pending: return Icons.access_time;
      case ReminderStatus.missed: return Icons.warning_amber;
    }
  }

  Color _getStatusColor(ReminderStatus status, ColorScheme cs) {
    switch (status) {
      case ReminderStatus.taken: return AppTheme.medTaken;
      case ReminderStatus.skipped: return AppTheme.medTaken;
      case ReminderStatus.pending: return AppTheme.medPending;
      case ReminderStatus.missed: return AppTheme.medMissed;
    }
  }

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
            _buildHomeTab(cs, tt),
            const ScheduleListScreen(embedded: true),
            _buildMedicineTab(cs, tt),
            _buildStatsTab(cs, tt),
            _buildProfileTab(cs, tt),
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

  // ===========================
  // 标签0：主页
  // ===========================
  Widget _buildHomeTab(ColorScheme cs, TextTheme tt) {
    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr = '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';
    final header = _buildFlexibleHeader(dateStr: dateStr, cs: cs, tt: tt);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            floating: false,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: header,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final medicineProvider = context.watch<MedicineProvider>();
                  final lowStockMedicines = medicineProvider.activeMedicines.where(
                    (m) => m.alertThreshold > 0 && m.currentStock <= m.alertThreshold
                  ).toList();

                  final listItems = <Widget>[
                    _buildProgressRow(cs, tt),
                    const SizedBox(height: 16),
                  ];
                  
                  if (lowStockMedicines.isNotEmpty) {
                    listItems.add(_buildLowStockAlert(lowStockMedicines, cs, tt));
                    listItems.add(const SizedBox(height: 16));
                  }
                  
                  listItems.addAll([
                    _buildWeekStrip(cs, tt),
                    const SizedBox(height: 16),
                    _buildStreakFooter(cs, tt),
                    const SizedBox(height: 16),
                    _buildPeriodSections(cs, tt),
                  ]);
                  
                  if (index < listItems.length) return listItems[index];
                  return null;
                },
                childCount: context.watch<MedicineProvider>().activeMedicines.where((m) => m.alertThreshold > 0 && m.currentStock <= m.alertThreshold).isNotEmpty ? 9 : 7,
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            fillOverscroll: true,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- 可折叠头部 ---
  Widget _buildFlexibleHeader({required String dateStr, required ColorScheme cs, required TextTheme tt}) {
    final now = DateTime.now();
    final hour = now.hour;
    final randomGreetings = <String>[
      if (hour < 6) ...['这么晚还没睡呀', '夜里凉，盖好被子', '半夜啦，眯一会儿吧'],
      if (hour >= 6 && hour < 9) ...['早啊，记得吃早饭', '早上好，今天天气不错', '起床咯，喝杯温水'],
      if (hour >= 9 && hour < 12) ...['上午好，忙起来了吗', '别忘了上午那顿药', '快到中午了，加油'],
      if (hour >= 12 && hour < 14) ...['中午啦，该吃饭了', '吃完饭歇会儿再吃药', '午饭吃好了没'],
      if (hour >= 14 && hour < 18) ...['下午好，喝点水', '下午容易犯困，活动一下', '下半天了，药别忘了'],
      if (hour >= 18 && hour < 21) ...['晚上好，吃了吗', '晚饭后散个步吧', '今天过得怎么样'],
      if (hour >= 21) ...['快休息了，泡泡脚', '晚安前再看看药吃了没', '一天辛苦了，早点睡'],
    ];
    final randomGreeting = randomGreetings[now.millisecond % randomGreetings.length];
    final lunarDate = LunarCalendar.getLunarDate(now);

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        gradient: LinearGradient(
          colors: [cs.surface, cs.primaryContainer],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(randomGreeting,
              style: tt.headlineSmall?.copyWith(color: cs.onPrimaryContainer)),
          const SizedBox(height: 8),
          Text(dateStr,
              style: tt.titleMedium?.copyWith(color: cs.onPrimaryContainer.withAlpha(180))),
          const SizedBox(height: 4),
          Text(lunarDate,
              style: tt.bodyMedium?.copyWith(color: cs.onPrimaryContainer.withAlpha(140))),
        ],
      ),
    );
  }

  // --- 用药进度 ---
  Widget _buildProgressRow(ColorScheme cs, TextTheme tt) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        final total = provider.todayStats['total'] ?? 0;
        final taken = provider.todayStats['taken'] ?? 0;
        final ratio = total > 0 ? taken / total : 0.0;
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.medication, color: cs.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('今日用药', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: '$taken', style: tt.headlineSmall?.copyWith(color: cs.primary)),
                              TextSpan(text: ' / $total', style: tt.titleLarge?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (ratio >= 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: cs.onPrimaryContainer, size: 16),
                            const SizedBox(width: 4),
                            Text('全部完成', style: tt.labelMedium?.copyWith(color: cs.onPrimaryContainer)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ratio >= 1.0 ? '太棒了，今天全部完成！' : '还剩 ${total - taken} 次用药待打卡',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 周历 ---
  Widget _buildWeekStrip(ColorScheme cs, TextTheme tt) {
    final now = DateTime.now();
    final today = now.weekday;
    final monday = now.subtract(Duration(days: today - 1));
    final labels = ['一', '二', '三', '四', '五', '六', '日'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final date = monday.add(Duration(days: i));
            final isToday = date.day == now.day && date.month == now.month;
            final hasReminders = _dayHasReminders(date);

            return Column(
              children: [
                Text(labels[i], style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? cs.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${date.day}',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? cs.onPrimaryContainer : cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hasReminders ? cs.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  bool _dayHasReminders(DateTime date) {
    final reminders = context.read<ReminderProvider>().todayReminders;
    return reminders.any((r) =>
        r.scheduledTime.year == date.year &&
        r.scheduledTime.month == date.month &&
        r.scheduledTime.day == date.day);
  }

  // --- 连续服药 ---
  Widget _buildStreakFooter(ColorScheme cs, TextTheme tt) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            Icon(Icons.local_fire_department, size: 18, color: cs.primary),
            const SizedBox(width: 4),
            Text('已连续服药 ${provider.consecutiveDays} 天',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        );
      },
    );
  }

  // --- 时段分组药品 ---
  Widget _buildPeriodSections(ColorScheme cs, TextTheme tt) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ));
        }

        final reminders = provider.todayReminders;
        if (reminders.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.medication_outlined, size: 48, color: cs.outline),
                  const SizedBox(height: 12),
                  Text('今日暂无用药计划', style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('去药品管理添加药品和用药计划', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }

        final morning = reminders.where((r) => r.scheduledTime.hour >= 6 && r.scheduledTime.hour < 12).toList();
        final noon = reminders.where((r) => r.scheduledTime.hour >= 12 && r.scheduledTime.hour < 18).toList();
        final evening = reminders.where((r) => r.scheduledTime.hour >= 18 || r.scheduledTime.hour < 6).toList();

        morning.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        noon.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        evening.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

        final periods = <_PeriodData>[
          if (morning.isNotEmpty) _PeriodData('早上', Icons.wb_sunny_outlined, morning),
          if (noon.isNotEmpty) _PeriodData('中午', Icons.wb_cloudy_outlined, noon),
          if (evening.isNotEmpty) _PeriodData('晚上', Icons.nights_stay_outlined, evening),
        ];

        return Column(
          children: periods.map((p) => _buildPeriodSection(p, context, cs, tt)).toList(),
        );
      },
    );
  }

  Widget _buildPeriodSection(_PeriodData period, BuildContext context, ColorScheme cs, TextTheme tt) {
    final takenCount = period.reminders.where((r) => r.status == ReminderStatus.taken).length;
    final total = period.reminders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(period.icon, size: 20, color: cs.primary),
              const SizedBox(width: 6),
              Text(period.name, style: tt.titleMedium),
              const Spacer(),
              Text('$takenCount/$total',
                  style: tt.bodyMedium?.copyWith(
                    color: takenCount == total ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
        ...period.reminders.map((r) => _buildMedicineCard(r, context, cs, tt)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMedicineCard(Reminder reminder, BuildContext context, ColorScheme cs, TextTheme tt) {
    final isTaken = reminder.status == ReminderStatus.taken;
    final isSkipped = reminder.status == ReminderStatus.skipped;
    final isMissed = reminder.status == ReminderStatus.missed;
    final canAct = reminder.status == ReminderStatus.pending;

    Color chipBg;
    Color chipFg;
    if (isTaken) {
      chipBg = cs.primaryContainer.withAlpha(40);
      chipFg = cs.primary;
    } else if (isSkipped) {
      chipBg = cs.tertiaryContainer.withAlpha(40);
      chipFg = cs.tertiary;
    } else if (isMissed) {
      chipBg = cs.errorContainer.withAlpha(60);
      chipFg = cs.error;
    } else {
      chipBg = cs.primary.withAlpha(20);
      chipFg = cs.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication,
                color: chipFg,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.medicineName,
                      style: tt.bodyLarge?.copyWith(
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                        color: isTaken ? cs.onSurfaceVariant : null,
                      )),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormat('HH:mm').format(reminder.scheduledTime),
                          style: tt.labelMedium?.copyWith(color: cs.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(reminder.dosage,
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            if (canAct)
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: () => context.read<ReminderProvider>().takeMedicine(reminder),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('打卡'),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(reminder.status),
                  style: tt.labelMedium?.copyWith(color: chipFg),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken: return '已打卡';
      case ReminderStatus.skipped: return '已跳过';
      case ReminderStatus.missed: return '已漏服';
      case ReminderStatus.pending: return '';
    }
  }

  Widget _buildQuickEntry({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required ColorScheme cs}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primary.withAlpha(20),
        child: Icon(icon, color: cs.primary, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      trailing: Icon(Icons.chevron_right, color: cs.outline),
      onTap: onTap,
    );
  }

  // ===========================
  // 标签3：服药统计
  // ===========================
  Widget _buildStatsTab(ColorScheme cs, TextTheme tt) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final todayTaken = provider.todayReminders.where((r) => r.status == ReminderStatus.taken).length;
        final todaySkipped = provider.todayReminders.where((r) => r.status == ReminderStatus.skipped).length;
        final todayMissed = provider.todayReminders.where((r) => r.status == ReminderStatus.missed).length;
        final todayPending = provider.todayReminders.where((r) => r.status == ReminderStatus.pending).length;
        final todayTotal = todayTaken + todaySkipped + todayMissed + todayPending;
        final adherence = provider.todayAdherence;
        final adherencePct = (adherence * 100).toStringAsFixed(1);
        final riskPct = _calcRiskScore(adherence);

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPeriodSelector(cs),
              const SizedBox(height: 16),
              _buildStatsOverview(
                total: todayTotal,
                taken: todayTaken,
                missed: todayMissed + todaySkipped,
                adherence: adherence,
                cs: cs,
              ),
              const SizedBox(height: 16),
              _buildHealthRiskCard(
                riskPct: riskPct,
                adherence: adherence,
                adherencePct: adherencePct,
                cs: cs,
                tt: tt,
              ),
              const SizedBox(height: 16),
              if (provider.todayReminders.isNotEmpty) ...[
                Text('今日提醒记录',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...provider.todayReminders.map((r) => _buildReminderTile(r, context, cs, tt)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(ColorScheme cs) {
    final periods = [
      {'key': 'week', 'label': '本周'},
      {'key': 'month', 'label': '本月'},
      {'key': 'threeMonths', 'label': '近三月'},
    ];

    return Row(
      children: periods.map((p) {
        final selected = _statsPeriod == p['key'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(p['label']!),
            selected: selected,
            onSelected: (_) => setState(() => _statsPeriod = p['key']!),
            selectedColor: cs.secondaryContainer,
            backgroundColor: cs.surfaceContainerHighest,
            labelStyle: TextStyle(
              color: selected ? cs.onSecondaryContainer : cs.onSurface,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsOverview({
    required int total,
    required int taken,
    required int missed,
    required double adherence,
    required ColorScheme cs,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, size: 20, color: cs.tertiary),
                const SizedBox(width: 8),
                Text('数据统计总览',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statsPeriod == 'week' ? '最近一周' : _statsPeriod == 'month' ? '最近一月' : '近三月',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCell('计划服药', '$total次', cs.primary, cs),
                _buildStatCell('已服药', '$taken次', cs.primary, cs),
                _buildStatCell('漏服', '$missed次', cs.error, cs),
                _buildStatCell('完成率', '${(adherence * 100).toStringAsFixed(1)}%', cs.tertiary, cs),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(String label, String value, Color color, ColorScheme cs) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              )),
        ],
      ),
    );
  }

  Widget _buildHealthRiskCard({
    required double riskPct,
    required double adherence,
    required String adherencePct,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final riskLevel = riskPct >= 20 ? '高风险' : riskPct >= 10 ? '中等风险' : '低风险';
    final riskColor = riskPct >= 20 ? cs.error : riskPct >= 10 ? cs.tertiary : cs.primary;
    final needAttention = riskPct >= 10;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: riskColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shield_outlined, size: 20, color: riskColor),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('10年健康风险评估',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(riskLevel,
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('非诊断结果，仅用于长期趋势管理',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${riskPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    )),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(needAttention ? '需要关注' : '状况良好',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (riskPct / 50).clamp(0.0, 1.0),
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: cs.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('数据不足，仅作粗略参考 · 提升服药完成率可进一步降低风险',
                      style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('服药依从性：当前周期完成率 $adherencePct%',
                        style: tt.labelMedium?.copyWith(
                          color: cs.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (adherence < 0.8) ...[
              _buildSuggestion('把漏服较多的时段设置为强提醒，优先把完成率拉回 80% 以上。', cs),
              const SizedBox(height: 6),
            ],
            _buildSuggestion('补齐出生日期、性别、血压后，评估会更稳定。', cs),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(color: cs.onSurface, fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }

  double _calcRiskScore(double adherence) {
    if (adherence >= 0.9) return 5.0;
    if (adherence >= 0.8) return 8.0;
    if (adherence >= 0.6) return 13.0;
    if (adherence >= 0.4) return 18.0;
    return 25.0;
  }

  Widget _buildReminderTile(Reminder reminder, BuildContext context, ColorScheme cs, TextTheme tt) {
    final isPending = reminder.status == ReminderStatus.pending;
    final isPassed = reminder.scheduledTime.isBefore(DateTime.now());
    final statusColor = _getStatusColor(reminder.status, cs);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(30),
          child: Icon(
            _getStatusIcon(reminder.status),
            color: statusColor,
            size: 22,
          ),
        ),
        title: Text(
          '${reminder.medicineName} · ${reminder.dosage}',
          style: tt.bodyLarge,
        ),
        subtitle: Text(
          '${_formatTime(reminder.scheduledTime)}  ${reminder.statusLabel}',
          style: tt.labelMedium?.copyWith(color: statusColor),
        ),
        trailing: isPending && isPassed
            ? IconButton(
                icon: Icon(Icons.more_horiz, color: cs.tertiary),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ReminderBottomSheet(
                      reminder: reminder,
                      provider: context.read<ReminderProvider>(),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  // ===========================
  // 标签2：药品管理
  // ===========================
  Widget _buildMedicineTab(ColorScheme cs, TextTheme tt) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.errorMessage!, style: tt.bodyMedium?.copyWith(color: cs.error)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: () => provider.loadMedicines(), child: const Text('重试')),
                ],
              ),
            ),
          );
        }

        if (provider.medicines.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medication_outlined, size: 48, color: cs.outline),
                const SizedBox(height: 12),
                Text('暂无药品', style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('点击右下角添加', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadMedicines(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.medicines.length,
            itemBuilder: (context, index) {
              final medicine = provider.medicines[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(medicine.colorValue).withAlpha(30),
                    child: Icon(Icons.medication, color: Color(medicine.colorValue), size: 22),
                  ),
                  title: Text(medicine.name, style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
                  subtitle: Text('${medicine.specification}  ·  ${medicine.dosageForm}'),
                  trailing: Switch(
                    value: medicine.isActive,
                    onChanged: (_) => provider.toggleMedicineActive(medicine),
                  ),
                  onTap: () => _navigateToMedicineForm(context, medicine: medicine),
                  onLongPress: () => _confirmDeleteMedicine(context, medicine),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================
  // 标签4：我的
  // ===========================
  Widget _buildProfileTab(ColorScheme cs, TextTheme tt) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.loadTodayReminders(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 用户信息卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.person, size: 32, color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('用户', style: tt.titleMedium),
                            const SizedBox(height: 4),
                            Text('连续用药 ${provider.consecutiveDays} 天',
                              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: cs.outline),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 服药统计
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('服药统计', style: tt.titleMedium),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('今日已服', '${provider.todayStats['taken']}', cs.primary, cs),
                          _buildStatItem('今日待服', '${provider.todayStats['total']! - provider.todayStats['taken']!}', cs.tertiary, cs),
                          _buildStatItem('连续天数', '${provider.consecutiveDays}', cs.tertiary, cs),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '依从率: ${(provider.todayAdherence * 100).toStringAsFixed(0)}%',
                        style: tt.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: provider.todayAdherence,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 快捷入口
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('快捷入口', style: tt.titleMedium),
                      const SizedBox(height: 12),
                      _buildQuickEntry(
                        icon: Icons.edit_note,
                        title: '症状日记',
                        subtitle: '记录身体症状',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen())),
                        cs: cs,
                      ),
                      _buildQuickEntry(
                        icon: Icons.people_outline,
                        title: '家属监护',
                        subtitle: '管理家属绑定与查看',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuardianHomeScreen())),
                        cs: cs,
                      ),
                      _buildQuickEntry(
                        icon: Icons.schedule,
                        title: '用药计划',
                        subtitle: '管理用药计划',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleListScreen())),
                        cs: cs,
                      ),
                      const Divider(height: 24),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: Icon(Icons.info_outline, color: cs.onSurfaceVariant, size: 22),
                        ),
                        title: Text('关于', style: tt.bodyLarge),
                        subtitle: Text('家庭用药管家 v1.0.1', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, ColorScheme cs) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      ],
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

  // ===========================
  // 快捷操作
  // ===========================
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

  Widget _buildLowStockAlert(List<Medicine> meds, ColorScheme cs, TextTheme tt) {
    final names = meds.map((m) => m.name).join('、');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '库存预警: $names 库存不足，请及时补充。',
              style: tt.bodyMedium?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMedicineForm(BuildContext context, {Medicine? medicine}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineFormScreen(medicine: medicine),
      ),
    );
  }

  void _confirmDeleteMedicine(BuildContext context, dynamic medicine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('删除药品'),
        content: Text('确定要删除「${medicine.name}」吗？关联的用药计划也会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              context.read<MedicineProvider>().removeMedicine(medicine.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// --- 时段数据模型 ---
class _PeriodData {
  final String name;
  final IconData icon;
  final List<Reminder> reminders;
  const _PeriodData(this.name, this.icon, this.reminders);
}
