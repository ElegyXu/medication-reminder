import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/medicine_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../models/reminder.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/reminder_bottom_sheet.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  String _statsPeriod = 'week'; // week / month / threeMonths

  Future<void> _onRefresh() async {
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

  double _calcRiskScore(double adherence) {
    if (adherence >= 0.9) return 5.0;
    if (adherence >= 0.8) return 8.0;
    if (adherence >= 0.6) return 13.0;
    if (adherence >= 0.4) return 18.0;
    return 25.0;
  }

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCell('计划用药', '$total', cs.primary, cs),
                _buildStatCell('实际已服', '$taken', cs.tertiary, cs),
                _buildStatCell('漏服/跳过', '$missed', cs.error, cs),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('今日用药依从率',
                          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: adherence,
                          minHeight: 8,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            adherence >= 0.8 ? cs.tertiary : cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text('${(adherence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(String label, String value, Color color, ColorScheme cs) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            )),
      ],
    );
  }

  Widget _buildHealthRiskCard({
    required double riskPct,
    required double adherence,
    required String adherencePct,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    String level;
    Color levelColor;
    String desc;
    List<String> suggestions;

    if (adherence >= 0.9) {
      level = '极低';
      levelColor = cs.tertiary;
      desc = '您的服药依从率极高，继续保持！目前健康风险极低，药物正在发挥最佳治疗效果。';
      suggestions = ['继续维持当前的用药习惯。', '如有任何轻微不适，记录在症状日记中。'];
    } else if (adherence >= 0.8) {
      level = '低风险';
      levelColor = cs.secondary;
      desc = '您的服药依从性良好，但偶尔有漏服或延迟。建议设置更显著的提醒，减少遗漏。';
      suggestions = ['将药盒放在视线内易见的地方。', '可以绑定家属，让家人协助提醒。'];
    } else if (adherence >= 0.6) {
      level = '中度风险';
      levelColor = cs.primary;
      desc = '您的服药依从性一般。当前漏服较多，可能会导致血药浓度不稳定，影响治疗效果。';
      suggestions = ['使用智能药盒或药袋分类装药。', '如有副作用导致不想服药，请及时咨询医生。'];
    } else {
      level = '高风险';
      levelColor = cs.error;
      desc = '您的服药依从率过低！极易导致病情反复或加重，请务必引起重视，必要时联系医生。';
      suggestions = ['立刻与家属取得联系，开启家属监护。', '重新评估用药计划是否过于复杂，与医生沟通简化方案。'];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text('依从性健康风险评估', style: tt.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('今日用药健康风险等级', style: TextStyle(fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: levelColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: levelColor.withAlpha(80)),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.5),
            ),
            const Divider(height: 28),
            Text('改进建议', style: tt.bodyLarge),
            const SizedBox(height: 10),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSuggestion(s, cs),
                )),
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

  Widget _buildReminderTile(Reminder reminder, BuildContext context, ColorScheme cs, TextTheme tt) {
    final isPending = reminder.status == ReminderStatus.pending;
    final isPassed = reminder.scheduledTime.isBefore(DateTime.now());
    final statusColor = AppTheme.getStatusColor(reminder.status, cs);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(30),
          child: Icon(
            AppTheme.getStatusIcon(reminder.status),
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
}
