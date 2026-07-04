import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/member.dart';
import '../../models/subscription.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/package_provider.dart';
import '../packages/add_subscription_sheet.dart';
import 'member_form_screen.dart';

class MemberDetailScreen extends StatefulWidget {
  final int memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  List<Subscription> _subscriptions = [];
  bool _loadingSubs = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().fetchPackages();
    });
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _loadingSubs = true);
    try {
      final subs = await context.read<MemberProvider>().getSubscriptions(widget.memberId);
      if (mounted) setState(() => _subscriptions = subs);
    } finally {
      if (mounted) setState(() => _loadingSubs = false);
    }
  }

  Member? _findMember(MemberProvider provider) {
    try {
      return provider.members.firstWhere((m) => m.id == widget.memberId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmDelete(Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá thành viên?'),
        content: Text('Bạn có chắc muốn xoá "${member.fullName}"? Hành động này không thể hoàn tác.'),
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
      final success = await context.read<MemberProvider>().deleteMember(member.id);
      if (success && mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = context.watch<MemberProvider>();
    final packageProvider = context.watch<PackageProvider>();
    final auth = context.watch<AuthProvider>();
    final member = _findMember(memberProvider);

    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết thành viên')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canManage = auth.staff?.isAdminOrManager ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thành viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MemberFormScreen(member: member)),
            ),
          ),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(member),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscriptions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(member: member),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gói tập đã đăng ký',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Đăng ký gói'),
                  onPressed: packageProvider.packages.isEmpty
                      ? null
                      : () async {
                          final result = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => AddSubscriptionSheet(
                              memberId: member.id,
                              packages: packageProvider.packages,
                            ),
                          );
                          if (result == true) _loadSubscriptions();
                        },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingSubs)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_subscriptions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Chưa đăng ký gói tập nào', style: TextStyle(color: Colors.black54)),
                ),
              )
            else
              ..._subscriptions.map((sub) => _SubscriptionTile(
                    subscription: sub,
                    packageName: packageProvider.packages
                        .firstWhere(
                          (p) => p.id == sub.packageId,
                          orElse: () => packageProvider.packages.first,
                        )
                        .name,
                  )),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Member member;
  const _InfoCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(member.fullName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                StatusBadge(status: member.status),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(icon: Icons.phone_outlined, label: member.phone),
            if (member.email != null && member.email!.isNotEmpty)
              _InfoRow(icon: Icons.email_outlined, label: member.email!),
            _InfoRow(icon: Icons.wc_outlined, label: member.gender.label),
            if (member.dob != null)
              _InfoRow(
                icon: Icons.cake_outlined,
                label: DateFormat('dd/MM/yyyy').format(member.dob!),
              ),
            if (member.address != null && member.address!.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, label: member.address!),
            _InfoRow(
              icon: Icons.event_available_outlined,
              label: 'Tham gia: ${DateFormat('dd/MM/yyyy').format(member.joinDate)}',
            ),
            if (member.note != null && member.note!.isNotEmpty) ...[
              const Divider(height: 24),
              Text(member.note!, style: const TextStyle(color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final Subscription subscription;
  final String packageName;
  const _SubscriptionTile({required this.subscription, required this.packageName});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern('vi_VN');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(packageName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(subscription.startDate)} - ${DateFormat('dd/MM/yyyy').format(subscription.endDate)}',
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text('${currency.format(subscription.pricePaid)} đ',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                ],
              ),
            ),
            StatusBadge(status: subscription.status),
          ],
        ),
      ),
    );
  }
}
