import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../models/reminder.dart';
import '../../theme/app_theme.dart';
import '../../models/medicine.dart';
import '../../widgets/reminder_bottom_sheet.dart';
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

  Color _getStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken: return Colors.green;
      case ReminderStatus.skipped: return Colors.orange;
      case ReminderStatus.pending: return AppTheme.primaryColor;
      case ReminderStatus.missed: return Colors.red;
    }
  }

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);

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
            _buildHomeTab(),
            const ScheduleListScreen(embedded: true),
            _buildMedicineTab(),
            _buildStatsTab(),
            _buildProfileTab(),
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
  Widget _buildHomeTab() {
    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr = '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';
    final header = _buildFlexibleHeader(dateStr: dateStr);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: false,
            floating: false,
            backgroundColor: const Color(0xFFC41E3A),
            flexibleSpace: FlexibleSpaceBar(
              background: header,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => switch (index) {
                  0 => _buildProgressRow(),
                  1 => const SizedBox(height: 14),
                  2 => _buildWeekStrip(),
                  3 => const SizedBox(height: 12),
                  4 => _buildStreakFooter(),
                  5 => const SizedBox(height: 16),
                  6 => _buildPeriodSections(),
                  7 => const SizedBox(height: 400), // ensure SliverAppBar can always scroll away
                  _ => null,
                },
                childCount: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 可折叠头部（SliverAppBar flexibleSpace）---
  Widget _buildFlexibleHeader({required String dateStr}) {
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFC41E3A), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(randomGreeting,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(dateStr,
              style: const TextStyle(color: Colors.white70, fontSize: 17)),
          const SizedBox(height: 4),
          Text(lunarDate,
              style: const TextStyle(color: Colors.white54, fontSize: 15)),
        ],
      ),
    );
  }

  // --- 用药进度（Material Design 3） ---
  Widget _buildProgressRow() {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        final total = provider.todayStats['total'] ?? 0;
        final taken = provider.todayStats['taken'] ?? 0;
        final ratio = total > 0 ? taken / total : 0.0;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        color: const Color(0xFFC41E3A).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medication, color: Color(0xFFC41E3A), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('今日用药', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: '$taken', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFC41E3A))),
                              TextSpan(text: ' / $total', style: TextStyle(fontSize: 18, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
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
                          color: const Color(0xFFC41E3A).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFFC41E3A), size: 16),
                            SizedBox(width: 4),
                            Text('全部完成', style: TextStyle(color: Color(0xFFC41E3A), fontSize: 13, fontWeight: FontWeight.w600)),
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
                      backgroundColor: const Color(0xFFC41E3A).withAlpha(20),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC41E3A)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ratio >= 1.0 ? '太棒了，今天全部完成！' : '还剩 ${total - taken} 次用药待打卡',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 周历（独立区块）---
  Widget _buildWeekStrip() {
    final now = DateTime.now();
    final today = now.weekday;
    final monday = now.subtract(Duration(days: today - 1));
    final labels = ['一', '二', '三', '四', '五', '六', '日'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                Text(labels[i], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFFC41E3A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: hasReminders ? const Color(0xFFC41E3A) : Colors.transparent,
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
  Widget _buildStreakFooter() {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            Icon(Icons.local_fire_department, size: 18, color: const Color(0xFFC41E3A)),
            const SizedBox(width: 4),
            Text('已连续服药 ${provider.consecutiveDays} 天',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        );
      },
    );
  }

  // --- 时段分组药品 ---
  Widget _buildPeriodSections() {
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
                  Icon(Icons.medication_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('今日暂无用药计划', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('去药品管理添加药品和用药计划', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        // Group by period: 早上 06:00-11:59, 中午 12:00-17:59, 晚上 18:00-23:59
        final morning = reminders.where((r) => r.scheduledTime.hour >= 6 && r.scheduledTime.hour < 12).toList();
        final noon = reminders.where((r) => r.scheduledTime.hour >= 12 && r.scheduledTime.hour < 18).toList();
        final evening = reminders.where((r) => r.scheduledTime.hour >= 18 || r.scheduledTime.hour < 6).toList();

        morning.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        noon.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        evening.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

        // Only show periods that have reminders
        final periods = <_PeriodData>[
          if (morning.isNotEmpty) _PeriodData('早上', Icons.wb_sunny_outlined, morning),
          if (noon.isNotEmpty) _PeriodData('中午', Icons.wb_cloudy_outlined, noon),
          if (evening.isNotEmpty) _PeriodData('晚上', Icons.nights_stay_outlined, evening),
        ];

        return Column(
          children: periods.map((p) => _buildPeriodSection(p, context)).toList(),
        );
      },
    );
  }

  Widget _buildPeriodSection(_PeriodData period, BuildContext context) {
    final takenCount = period.reminders.where((r) => r.status == ReminderStatus.taken).length;
    final total = period.reminders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(period.icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(period.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$takenCount/$total',
                  style: TextStyle(
                    fontSize: 14,
                    color: takenCount == total ? const Color(0xFFC41E3A) : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
        ...period.reminders.map((r) => _buildMedicineCard(r, context)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMedicineCard(Reminder reminder, BuildContext context) {
    final isTaken = reminder.status == ReminderStatus.taken;
    final isSkipped = reminder.status == ReminderStatus.skipped;
    final isMissed = reminder.status == ReminderStatus.missed;
    final canAct = reminder.status == ReminderStatus.pending;

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
                color: isTaken ? Colors.green.shade50
                    : isSkipped ? Colors.orange.shade50
                    : isMissed ? Colors.red.shade50
                    : AppTheme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication,
                color: isTaken ? Colors.green
                    : isSkipped ? Colors.orange
                    : isMissed ? Colors.red
                    : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.medicineName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                        color: isTaken ? Colors.grey : null,
                      )),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC41E3A).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormat('HH:mm').format(reminder.scheduledTime),
                          style: TextStyle(color: const Color(0xFFC41E3A), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(reminder.dosage,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
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
                  color: isTaken ? Colors.green.shade50
                      : isSkipped ? Colors.orange.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(reminder.status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isTaken ? Colors.green
                        : isSkipped ? Colors.orange
                        : Colors.red,
                  ),
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

  Widget _buildQuickEntry({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withAlpha(20),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // ===========================
  // 标签3：服药统计
  // ===========================
  Widget _buildStatsTab() {
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
              // 时间范围选择器
              _buildPeriodSelector(),
              const SizedBox(height: 16),

              // 数据统计总览
              _buildStatsOverview(
                total: todayTotal,
                taken: todayTaken,
                missed: todayMissed + todaySkipped,
                adherence: adherence,
              ),
              const SizedBox(height: 16),

              // 10年健康风险评估
              _buildHealthRiskCard(
                riskPct: riskPct,
                adherence: adherence,
                adherencePct: adherencePct,
              ),
              const SizedBox(height: 16),

              // 提醒记录
              if (provider.todayReminders.isNotEmpty) ...[
                Text('今日提醒记录',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...provider.todayReminders.map((r) => _buildReminderTile(r, context)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
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
            selectedColor: Colors.pink.shade50,
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: selected ? Colors.pink.shade700 : Colors.grey.shade600,
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
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, size: 20, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text('数据统计总览',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statsPeriod == 'week' ? '最近一周' : _statsPeriod == 'month' ? '最近一月' : '近三月',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCell('计划服药', '$total次', Colors.orange.shade700),
                _buildStatCell('已服药', '$taken次', Colors.green.shade600),
                _buildStatCell('漏服', '$missed次', Colors.red.shade500),
                _buildStatCell('完成率', '${(adherence * 100).toStringAsFixed(1)}%', Colors.orange.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(String label, String value, Color color) {
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
                color: Colors.grey.shade500,
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
  }) {
    final riskLevel = riskPct >= 20 ? '高风险' : riskPct >= 10 ? '中等风险' : '低风险';
    final riskColor = riskPct >= 20 ? Colors.red : riskPct >= 10 ? Colors.orange : Colors.green;
    final needAttention = riskPct >= 10;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: riskColor.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shield_outlined, size: 20, color: riskColor.shade700),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('10年健康风险评估',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(riskLevel,
                      style: TextStyle(
                        color: riskColor.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('非诊断结果，仅用于长期趋势管理',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            const SizedBox(height: 16),

            // Risk percentage
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${riskPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: riskColor.shade700,
                    )),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(needAttention ? '需要关注' : '状况良好',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (riskPct / 50).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(riskColor.shade400),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Data note
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('数据不足，仅作粗略参考 · 提升服药完成率可进一步降低风险',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Adherence warning
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('服药依从性：当前周期完成率 $adherencePct%',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Suggestions
            if (adherence < 0.8) ...[
              _buildSuggestion('把漏服较多的时段设置为强提醒，优先把完成率拉回 80% 以上。'),
              const SizedBox(height: 6),
            ],
            _buildSuggestion('补齐出生日期、性别、血压后，评估会更稳定。'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.orange.shade400,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
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

  Widget _buildReminderTile(Reminder reminder, BuildContext context) {
    final isPending = reminder.status == ReminderStatus.pending;
    final isPassed = reminder.scheduledTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(reminder.status).withAlpha(30),
          child: Icon(
            _getStatusIcon(reminder.status),
            color: _getStatusColor(reminder.status),
            size: 22,
          ),
        ),
        title: Text(
          '${reminder.medicineName} · ${reminder.dosage}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${_formatTime(reminder.scheduledTime)}  ${reminder.statusLabel}',
          style: TextStyle(color: _getStatusColor(reminder.status), fontSize: 13),
        ),
        trailing: isPending && isPassed
            ? IconButton(
                icon: const Icon(Icons.more_horiz, color: Color(0xFFFF6B35)),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
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
  // 标签3：药品管理
  // ===========================
  Widget _buildMedicineTab() {
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
                  Text(provider.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
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
                Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('暂无药品', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                const SizedBox(height: 4),
                Text('点击右下角添加', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
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
                  title: Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${medicine.specification}  ·  ${medicine.dosageForm}'),
                  trailing: Switch(
                    value: medicine.isActive,
                    activeTrackColor: AppTheme.primaryColor,
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
  Widget _buildProfileTab() {
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
                        backgroundColor: AppTheme.primaryColor.withAlpha(30),
                        child: const Icon(Icons.person, size: 32, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('用户', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('连续用药 ${provider.consecutiveDays} 天',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
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
                      const Text('服药统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('今日已服', '${provider.todayStats['taken']}', Colors.green),
                          _buildStatItem('今日待服', '${provider.todayStats['total']! - provider.todayStats['taken']!}', AppTheme.primaryColor),
                          _buildStatItem('连续天数', '${provider.consecutiveDays}', Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '依从率: ${(provider.todayAdherence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: provider.todayAdherence,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
                      const Text('快捷入口', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildQuickEntry(
                        icon: Icons.edit_note,
                        title: '症状日记',
                        subtitle: '记录身体症状',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen())),
                      ),
                      _buildQuickEntry(
                        icon: Icons.people_outline,
                        title: '家属监护',
                        subtitle: '管理家属绑定与查看',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuardianHomeScreen())),
                      ),
                      _buildQuickEntry(
                        icon: Icons.schedule,
                        title: '用药计划',
                        subtitle: '管理用药计划',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleListScreen())),
                      ),
                      const Divider(height: 24),
                      _buildQuickEntry(
                        icon: Icons.info_outline,
                        title: '关于',
                        subtitle: '家庭用药管家 v1.0.1',
                        onTap: () {},
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
        elevation: 2,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===========================
  // 快捷操作
  // ===========================
  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.add)),
                title: const Text('添加药品'),
                onTap: () { Navigator.pop(ctx); _navigateToMedicineForm(context); },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.schedule)),
                title: const Text('新建用药计划'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleListScreen()));
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.edit_note)),
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
        title: const Text('删除药品'),
        content: Text('确定要删除「${medicine.name}」吗？关联的用药计划也会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<MedicineProvider>().removeMedicine(medicine.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
