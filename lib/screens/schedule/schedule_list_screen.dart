import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/schedule.dart';
import '../../models/reminder.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../theme/app_theme.dart';
import 'schedule_form_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  final bool embedded;
  const ScheduleListScreen({super.key, this.embedded = false});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadTodayReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody(context);

    return Scaffold(
      appBar: AppBar(title: const Text('用药计划')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: FloatingActionButton.extended(
          onPressed: () => _addSchedule(context),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('添加计划', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer2<ScheduleProvider, ReminderProvider>(
      builder: (context, scheduleProvider, reminderProvider, _) {
        if (scheduleProvider.isLoading || reminderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (scheduleProvider.schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('暂无用药计划', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                const SizedBox(height: 4),
                Text('点击右下角添加', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          );
        }

        // Group reminders by medicine name for stats
        final remindersByMedicine = <String, List<Reminder>>{};
        for (final r in reminderProvider.todayReminders) {
          remindersByMedicine.putIfAbsent(r.medicineName, () => []).add(r);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await scheduleProvider.loadSchedules();
            if (context.mounted) await context.read<ReminderProvider>().loadTodayReminders();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSearchBar(cs),
              const SizedBox(height: 12),
              _buildSafetyCard(reminderProvider, cs),
              const SizedBox(height: 12),
              ...scheduleProvider.schedules.map((s) {
                final reminders = remindersByMedicine[s.medicineName] ?? [];
                return _buildScheduleCard(context, s, reminders, scheduleProvider, cs);
              }),
              const SizedBox(height: 12),
              _buildNextDoseReminder(reminderProvider.todayReminders, cs),
            ],
          ),
        );
      },
    );
  }

  // ========================
  // 搜索栏
  // ========================
  Widget _buildSearchBar(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索药品、疾病或症状...',
              hintStyle: TextStyle(color: cs.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.list_alt, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  // ========================
  // 安全检测卡片
  // ========================
  Widget _buildSafetyCard(ReminderProvider rp, ColorScheme cs) {
    final adherence = rp.todayAdherence;
    final taken = rp.todayStats['taken'] ?? 0;
    final total = rp.todayStats['total'] ?? 0;
    final skipped = rp.todayReminders.where((r) => r.status == ReminderStatus.skipped).length;

    final bool hasIssues = total > 0 && (adherence < 0.8 || skipped > 0);
    final Color bgColor = hasIssues ? cs.errorContainer : cs.primaryContainer;
    final Color iconBg = hasIssues ? cs.errorContainer.withAlpha(140) : cs.primaryContainer.withAlpha(140);
    final Color iconColor = hasIssues ? cs.onErrorContainer : cs.onPrimaryContainer;
    final Color badgeBg = hasIssues ? cs.errorContainer.withAlpha(180) : cs.primaryContainer.withAlpha(180);
    final Color badgeColor = hasIssues ? cs.onErrorContainer : cs.onPrimaryContainer;

    String statusText;
    if (total == 0) {
      statusText = '今日无用药计划';
    } else if (adherence >= 1.0) {
      statusText = '今日已全部按时服药';
    } else if (adherence >= 0.8) {
      statusText = '今日依从性良好';
    } else if (skipped > 0) {
      statusText = '有 $skipped 次未服药';
    } else {
      statusText = '有 ${total - taken} 次待完成';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shield, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: hasIssues ? cs.onErrorContainer : cs.onPrimaryContainer),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasIssues ? '需关注' : '监控中',
                  style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: badgeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // 药品用药计划卡片
  // ========================
  Widget _buildScheduleCard(
    BuildContext context,
    MedicationSchedule schedule,
    List<Reminder> reminders,
    ScheduleProvider provider,
    ColorScheme cs,
  ) {
    final medicineProvider = context.read<MedicineProvider>();
    final medicine = medicineProvider.medicines
        .where((m) => m.id == schedule.medicineId)
        .firstOrNull;

    final takenCount = reminders.where((r) => r.status == ReminderStatus.taken).length;
    final total = reminders.length;
    final completionRate = total > 0 ? (takenCount / total * 100).toStringAsFixed(0) : '0';

    // Period labels for time points
    final periodLabels = schedule.timePoints.map((t) {
      final hour = int.parse(t.split(':')[0]);
      if (hour >= 6 && hour < 12) return '早上 $t';
      if (hour >= 12 && hour < 18) return '下午 ${_to12Hour(t)}';
      return '晚上 ${_to12Hour(t)}';
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: medicine icon + name + specs + more menu
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medical_services, color: cs.onPrimaryContainer, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.medicineName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      if (medicine != null)
                        Text(
                          '${medicine.dosageForm} · ${medicine.specification}',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _editSchedule(context, schedule, provider);
                    } else if (action == 'delete') {
                      _confirmDelete(context, schedule, provider);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: frequency + completion rate
            Row(
              children: [
                // Frequency tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule.frequencyLabel}${schedule.frequency == ScheduleFrequency.daily ? '${schedule.timePoints.length}次' : ''}',
                        style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Completion rate
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, size: 14, color: cs.onSecondaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        '完成率 $completionRate%',
                        style: TextStyle(color: cs.onSecondaryContainer, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Active switch
                Switch(
                  value: schedule.isActive,
                  activeTrackColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => provider.toggleScheduleActive(schedule),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: time tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: periodLabels.map((label) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(color: cs.onSecondaryContainer, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ========================
  // 下次服药提醒
  // ========================
  Widget _buildNextDoseReminder(List<Reminder> reminders, ColorScheme cs) {
    final now = DateTime.now();
    final pending = reminders
        .where((r) => r.status == ReminderStatus.pending && r.scheduledTime.isAfter(now))
        .toList();
    pending.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 24, color: cs.primary),
            const SizedBox(width: 12),
            const Text('今日已完成全部服药', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    final next = pending.first;
    final diff = next.scheduledTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    String timeStr;
    if (hours > 0) {
      timeStr = '$hours小时';
      if (minutes > 0) timeStr += '$minutes分钟';
    } else {
      timeStr = '$minutes分钟';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withAlpha(200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_active, color: cs.onSecondaryContainer, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 15, color: cs.onSurface),
                children: [
                  const TextSpan(text: '下次服药 '),
                  TextSpan(
                    text: '$timeStr后',
                    style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' · ${next.medicineName} ${next.dosage}'),
                ],
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSecondaryContainer),
        ],
      ),
    );
  }

  String _to12Hour(String time24) {
    final hour = int.parse(time24.split(':')[0]);
    final minute = time24.split(':')[1];
    if (hour == 0) return '12:$minute';
    if (hour <= 12) return '$hour:$minute';
    return '${hour - 12}:$minute';
  }

  Future<void> _addSchedule(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleFormScreen()),
    );
    if (context.mounted) context.read<ScheduleProvider>().loadSchedules();
  }

  Future<void> _editSchedule(
    BuildContext context,
    MedicationSchedule schedule,
    ScheduleProvider provider,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScheduleFormScreen(schedule: schedule)),
    );
    if (context.mounted) provider.loadSchedules();
  }

  void _confirmDelete(
    BuildContext context,
    MedicationSchedule schedule,
    ScheduleProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('删除计划'),
        content: Text('确定要删除「${schedule.medicineName}」的用药计划吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              provider.removeSchedule(schedule.id);
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
