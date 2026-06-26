import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../../models/medicine.dart';
import '../../medicine/medicine_form_screen.dart';

class MedicineTab extends StatelessWidget {
  const MedicineTab({super.key});

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

  void _confirmDeleteMedicine(BuildContext context, Medicine medicine) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
}
