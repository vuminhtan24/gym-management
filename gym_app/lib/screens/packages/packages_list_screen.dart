import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/package_provider.dart';
import 'package_form_screen.dart';

class PackagesListScreen extends StatefulWidget {
  const PackagesListScreen({super.key});

  @override
  State<PackagesListScreen> createState() => _PackagesListScreenState();
}

class _PackagesListScreenState extends State<PackagesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().fetchPackages();
    });
  }

  Future<void> _confirmDelete(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá gói tập?'),
        content: Text('Bạn có chắc muốn xoá gói "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<PackageProvider>().deletePackage(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();
    final auth = context.watch<AuthProvider>();
    final canEdit = auth.staff?.isAdminOrManager ?? false;
    final isAdmin = auth.staff?.isAdmin ?? false;
    final currency = NumberFormat.decimalPattern('vi_VN');

    return Scaffold(
      appBar: AppBar(title: const Text('Gói tập')),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PackageFormScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(provider, currency, canEdit, isAdmin),
    );
  }

  Widget _buildBody(PackageProvider provider, NumberFormat currency, bool canEdit, bool isAdmin) {
    if (provider.isLoading && provider.packages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.packages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
              const SizedBox(height: 12),
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: provider.fetchPackages,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.packages.isEmpty) {
      return const Center(
        child: Text('Chưa có gói tập nào', style: TextStyle(color: Colors.black54)),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchPackages,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: provider.packages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final pkg = provider.packages[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.card_membership, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(pkg.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                            StatusBadge(status: pkg.isActive),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${pkg.durationDays} ngày · ${currency.format(pkg.price)} đ',
                            style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        if (pkg.description != null && pkg.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(pkg.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black45, fontSize: 12.5)),
                        ],
                        if (canEdit) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PackageFormScreen(package: pkg),
                                  ),
                                ),
                                child: const Text('Sửa'),
                              ),
                              if (isAdmin)
                                TextButton(
                                  onPressed: () => _confirmDelete(pkg.id, pkg.name),
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                                  child: const Text('Xoá'),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
