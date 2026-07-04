import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/member_provider.dart';
import '../../widgets/member_card.dart';
import 'member_detail_screen.dart';
import 'member_form_screen.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().fetchMembers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thành viên')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MemberFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT hoặc email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<MemberProvider>().setSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => context.read<MemberProvider>().setSearch(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: provider.statusFilter == null,
                  onTap: () => context.read<MemberProvider>().setStatusFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Đang hoạt động',
                  selected: provider.statusFilter == 'active',
                  onTap: () => context.read<MemberProvider>().setStatusFilter('active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Ngừng hoạt động',
                  selected: provider.statusFilter == 'inactive',
                  onTap: () => context.read<MemberProvider>().setStatusFilter('inactive'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(MemberProvider provider) {
    if (provider.isLoading && provider.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.members.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchMembers(),
      );
    }
    if (provider.members.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: provider.fetchMembers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: provider.members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final member = provider.members[index];
          return MemberCard(
            member: member,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MemberDetailScreen(memberId: member.id)),
            ),
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
      backgroundColor: AppTheme.primary.withOpacity(0.08),
      side: BorderSide.none,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 56, color: Colors.black26),
          const SizedBox(height: 12),
          const Text('Chưa có thành viên nào', style: TextStyle(color: Colors.black54)),
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
