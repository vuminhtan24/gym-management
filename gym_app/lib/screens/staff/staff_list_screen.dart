import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../models/staff.dart';
import 'staff_form_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().fetchStaff();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.staff?.role == StaffRole.admin; // Chỉ Admin được CRUD Staff

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý nhân viên')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StaffFormScreen()),
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
                hintText: 'Tìm theo tên nhân viên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<StaffProvider>().setSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => context.read<StaffProvider>().setSearch(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: provider.roleFilter == null,
                  onTap: () => context.read<StaffProvider>().setRoleFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Quản trị viên',
                  selected: provider.roleFilter == 'admin',
                  onTap: () => context.read<StaffProvider>().setRoleFilter('admin'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Quản lý',
                  selected: provider.roleFilter == 'manager',
                  onTap: () => context.read<StaffProvider>().setRoleFilter('manager'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Lễ tân',
                  selected: provider.roleFilter == 'receptionist',
                  onTap: () => context.read<StaffProvider>().setRoleFilter('receptionist'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(provider, canManage, auth.staff?.id)),
        ],
      ),
    );
  }

  Widget _buildBody(StaffProvider provider, bool canManage, int? currentStaffId) {
    if (provider.isLoading && provider.staffList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.staffList.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchStaff(),
      );
    }
    if (provider.staffList.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: provider.fetchStaff,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: provider.staffList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final staff = provider.staffList[index];
          final isMe = staff.id == currentStaffId;
          return _StaffCard(
            staff: staff,
            isMe: isMe,
            canManage: canManage && !isMe, // Không được chỉnh sửa chính mình tại đây (đã có tab Tài khoản)
            onTap: () {
              if (canManage && !isMe) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => StaffFormScreen(staff: staff)),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Staff staff;
  final bool isMe;
  final bool canManage;
  final VoidCallback onTap;

  const _StaffCard({
    required this.staff,
    required this.isMe,
    required this.canManage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: canManage ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            staff.fullName + (isMe ? ' (Tôi)' : ''),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        _StatusBadge(status: staff.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Username: @${staff.username} • SĐT: ${staff.phone}',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vai trò: ${staff.role.label} ${staff.email != null ? "• Email: ${staff.email}" : ""}',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Khóa',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.grey[700],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
          Icon(Icons.people_outline, size: 56, color: Colors.black26),
          const SizedBox(height: 12),
          Text('Không tìm thấy nhân viên nào', style: TextStyle(color: Colors.black54)),
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
