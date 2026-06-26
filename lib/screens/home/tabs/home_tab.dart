import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/medicine_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../models/reminder.dart';
import '../../../models/medicine.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/lunar_calendar.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<void> _onRefresh(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr = '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';
    final header = _buildFlexibleHeader(dateStr: dateStr, cs: cs, tt: tt);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
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
                    _buildProgressRow(context, cs, tt),
                    const SizedBox(height: 16),
                  ];
                  
                  if (lowStockMedicines.isNotEmpty) {
                    listItems.add(_buildLowStockAlert(lowStockMedicines, cs, tt));
                    listItems.add(const SizedBox(height: 16));
                  }
                  
                  listItems.addAll([
                    _buildWeekStrip(context, cs, tt),
                    const SizedBox(height: 16),
                    _buildStreakFooter(cs, tt),
                    const SizedBox(height: 16),
                    _buildPeriodSections(cs, tt),
                  ]);
                  
                  if (index < listItems.length) return listItems[index];
                  return null;
                },
                childCount: 7, // matches the length of listItems
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlexibleHeader({required String dateStr, required ColorScheme cs, required TextTheme tt}) {
    final lunarDateStr = LunarCalendar.getLunarDate(DateTime.now());
    
    // Select friendly greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting = '您好';
    if (hour >= 5 && hour < 11) {
      greeting = '早上好';
    } else if (hour >= 11 && hour < 13) {
      greeting = '中午好';
    } else if (hour >= 13 && hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.surface,
            cs.primaryContainer,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            dateStr,
            style: tt.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer.withAlpha(200),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lunarDateStr,
            style: tt.labelMedium?.copyWith(
              color: cs.onPrimaryContainer.withAlpha(200),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  greeting,
                  style: tt.headlineSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        final taken = provider.todayStats['taken'] ?? 0;
        final total = provider.todayStats['total'] ?? 0;
        final percent = provider.todayAdherence;

        return Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('今日服用进度', style: tt.bodyLarge),
                            const SizedBox(height: 6),
                            Text('已服 $taken / 应服 $total',
                                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              value: percent,
                              strokeWidth: 6,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: cs.primary,
                            ),
                          ),
                          Text('${(percent * 100).toStringAsFixed(0)}%',
                              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekStrip(BuildContext context, ColorScheme cs, TextTheme tt) {
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
            final hasReminders = _dayHasReminders(context, date);

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

  bool _dayHasReminders(BuildContext context, DateTime date) {
    final reminders = context.read<ReminderProvider>().todayReminders;
    return reminders.any((r) =>
        r.scheduledTime.year == date.year &&
        r.scheduledTime.month == date.month &&
        r.scheduledTime.day == date.day);
  }

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
}

class _PeriodData {
  final String name;
  final IconData icon;
  final List<Reminder> reminders;
  const _PeriodData(this.name, this.icon, this.reminders);
}
