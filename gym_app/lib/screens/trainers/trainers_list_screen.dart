import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../models/trainer.dart';
import '../../widgets/trainer_card.dart';
import 'trainer_form_screen.dart';

class TrainersListScreen extends StatefulWidget {
  const TrainersListScreen({super.key});

  @override
  State<TrainersListScreen> createState() => _TrainersListScreenState();
}

class _TrainersListScreenState extends State<TrainersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainerProvider>().fetchTrainers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc muốn xoá huấn luyện viên "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final provider = context.read<TrainerProvider>();
      final success = await provider.deleteTrainer(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã xoá huấn luyện viên' : (provider.errorMessage ?? 'Lỗi')),
            backgroundColor: success ? AppTheme.primaryLight : AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainerProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.staff?.isAdminOrManager ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Huấn luyện viên')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrainerFormScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên HLV...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TrainerProvider>().setSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => context.read<TrainerProvider>().setSearch(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: provider.statusFilter == null,
                  onTap: () => context.read<TrainerProvider>().setStatusFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Đang hoạt động',
                  selected: provider.statusFilter == 'active',
                  onTap: () => context.read<TrainerProvider>().setStatusFilter('active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Ngừng hoạt động',
                  selected: provider.statusFilter == 'inactive',
                  onTap: () => context.read<TrainerProvider>().setStatusFilter('inactive'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(provider, canManage)),
        ],
      ),
    );
  }

  Widget _buildBody(TrainerProvider provider, bool canManage) {
    if (provider.isLoading && provider.trainers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.trainers.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchTrainers(),
      );
    }
    if (provider.trainers.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: provider.fetchTrainers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: provider.trainers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final trainer = provider.trainers[index];
          return TrainerCard(
            trainer: trainer,
            onTap: () {
              if (!canManage) return;
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                builder: (_) => _TrainerActions(
                  trainer: trainer,
                  onEdit: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => TrainerFormScreen(trainer: trainer)),
                    );
                  },
                  onDelete: () {
                    Navigator.pop(context);
                    _confirmDelete(context, trainer.id, trainer.fullName);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 56, color: Colors.black26),
          const SizedBox(height: 12),
          Text('Không tìm thấy huấn luyện viên nào', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _TrainerActions extends StatelessWidget {
  final Trainer trainer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TrainerActions({required this.trainer, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Chỉnh sửa'),
              onTap: onEdit,
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
              title: const Text('Xoá', style: TextStyle(color: AppTheme.danger)),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
