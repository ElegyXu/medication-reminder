import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../symptom/symptom_diary_screen.dart';
// Let's verify the path of GuardianHomeScreen.
// In patient_home_screen.dart: import '../guardian/guardian_home_screen.dart'; was commented as "patient_home_screen imports".
// Wait, let's make sure we get the correct relative path for GuardianHomeScreen and ScheduleListScreen.
// Let's check imports in patient_home_screen.dart lines 1-17:
// 12: import '../medicine/medicine_form_screen.dart';
// 13: import '../schedule/schedule_list_screen.dart';
// 14: import '../schedule/schedule_form_screen.dart';
// 15: import '../symptom/symptom_diary_screen.dart';
// 16: import '../guardian/guardian_home_screen.dart';
// So for tabs (which are in screens/home/tabs/):
// GuardianHomeScreen is in screens/guardian/guardian_home_screen.dart.
// Relative path from screens/home/tabs/ to screens/guardian/guardian_home_screen.dart is: ../../guardian/guardian_home_screen.dart.
// Relative path to SymptomDiaryScreen is: ../../symptom/symptom_diary_screen.dart.
// Relative path to ScheduleListScreen is: ../../schedule/schedule_list_screen.dart.
// This is perfect!
import '../../guardian/guardian_home_screen.dart';
import '../../schedule/schedule_list_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickEntry({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
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
}
