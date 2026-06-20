import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../database/database_helper.dart';
import '../../models/guardian_binding.dart';
import '../../theme/app_theme.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<GuardianBinding> _bindings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBindings();
  }

  Future<void> _loadBindings() async {
    setState(() => _isLoading = true);
    _bindings = await _db.getBindings();
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final phoneController = TextEditingController();
    final nicknameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('添加家属绑定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '患者手机号',
                hintText: '输入患者手机号',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: '称呼',
                hintText: '如：父亲',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '本地版本：绑定将直接生效，云端版本将等待对方确认',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final nickname = nicknameController.text.trim();
              if (phone.isEmpty || nickname.isEmpty) return;

              final now = DateTime.now();
              final binding = GuardianBinding(
                id: const Uuid().v4(),
                patientPhone: phone,
                patientNickname: nickname,
                guardianPhone: 'local_user',
                status: BindingStatus.active,
                createdAt: now,
                updatedAt: now,
              );
              await _db.insertBinding(binding);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              _loadBindings();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(GuardianBinding binding) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('解除绑定'),
        content: Text('确定解除与「${binding.patientNickname}」的绑定吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await _db.deleteBinding(binding.id);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              _loadBindings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('解除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('家属监护')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bindings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: cs.outline),
                      const SizedBox(height: 12),
                      Text('暂无绑定患者', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('添加家属绑定后可查看患者服药情况',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bindings.length,
                  itemBuilder: (context, index) {
                    final binding = _bindings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                          child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(binding.patientNickname,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('${binding.patientPhone} · ${binding.statusLabel}'),
                        trailing: TextButton(
                          onPressed: () => _confirmDelete(binding),
                          style: TextButton.styleFrom(foregroundColor: cs.error),
                          child: const Text('解除'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
