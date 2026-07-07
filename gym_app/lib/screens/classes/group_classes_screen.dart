import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../models/group_class.dart';
import '../../models/trainer.dart';

class GroupClassesScreen extends StatefulWidget {
  const GroupClassesScreen({super.key});

  @override
  State<GroupClassesScreen> createState() => _GroupClassesScreenState();
}

class _GroupClassesScreenState extends State<GroupClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().fetchClasses();
      context.read<TrainerProvider>().fetchTrainers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassProvider>();
    final trainers = context.watch<TrainerProvider>().trainers;
    final auth = context.watch<AuthProvider>();
    final canManage = auth.staff?.isAdminOrManager ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Lớp học nhóm')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _openClassFormDialog(canManage),
              child: const Icon(Icons.add),
            )
          : null,
      body: provider.isLoading && provider.classes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.classes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => provider.fetchClasses(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.classes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = provider.classes[index];
                      // Find trainer name
                      final trainer = trainers.firstWhere((t) => t.id == c.trainerId,
                          orElse: () => Trainer(id: 0, fullName: 'Chưa chỉ định', phone: '', specialty: '', experienceYears: 0, status: ''));

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text('HLV: ${trainer.fullName}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                              Text('Phòng: ${c.room ?? "Chưa chỉ định"} • Sĩ số tối đa: ${c.maxParticipants}',
                                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
                              if (c.description != null && c.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(c.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ]
                            ],
                          ),
                          trailing: canManage
                              ? IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _openClassFormDialog(canManage, groupClass: c),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined, size: 56, color: Colors.black26),
          const SizedBox(height: 12),
          Text('Chưa có lớp học nhóm nào', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  void _openClassFormDialog(bool canManage, {GroupClass? groupClass}) {
    if (!canManage) return;

    final trainerProvider = context.read<TrainerProvider>();
    final classProvider = context.read<ClassProvider>();

    final nameController = TextEditingController(text: groupClass?.name ?? '');
    final descController = TextEditingController(text: groupClass?.description ?? '');
    final roomController = TextEditingController(text: groupClass?.room ?? '');
    final maxController = TextEditingController(text: groupClass != null ? '${groupClass.maxParticipants}' : '20');
    int? selectedTrainerId = groupClass?.trainerId;

    // Filter active trainers
    final activeTrainers = trainerProvider.trainers.where((t) => t.isActive).toList();

    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(groupClass == null ? 'Thêm lớp học nhóm mới' : 'Sửa lớp học nhóm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên lớp học *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedTrainerId,
                  decoration: const InputDecoration(labelText: 'Huấn luyện viên phụ trách'),
                  items: activeTrainers
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedTrainerId = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Phòng học'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: maxController,
                  decoration: const InputDecoration(labelText: 'Số học viên tối đa'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả lớp học'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            if (groupClass != null)
              TextButton(
                onPressed: () async {
                  final success = await classProvider.deleteClass(groupClass.id);
                  if (ctx.mounted) Navigator.pop(ctx, success);
                },
                child: const Text('Xóa', style: TextStyle(color: AppTheme.danger)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(
              onPressed: () async {
                final c = GroupClass(
                  id: groupClass?.id ?? 0,
                  name: nameController.text.trim(),
                  trainerId: selectedTrainerId,
                  description: descController.text.trim(),
                  maxParticipants: int.tryParse(maxController.text) ?? 20,
                  room: roomController.text.trim(),
                );

                bool success;
                if (groupClass != null) {
                  success = await classProvider.updateClass(groupClass.id, c);
                } else {
                  success = await classProvider.createClass(c);
                }

                if (ctx.mounted) Navigator.pop(ctx, success);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result == true) {
        classProvider.fetchClasses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật lớp học nhóm thành công!'), backgroundColor: Colors.green),
        );
      }
    });
  }
}
