import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/member_provider.dart';
import '../../models/class_registration.dart';
import '../../models/member.dart';

class ClassDetailScreen extends StatefulWidget {
  final int scheduleId;
  final String className;
  final String timeRange;
  final DateTime date;
  final int maxParticipants;
  final String? room;

  const ClassDetailScreen({
    super.key,
    required this.scheduleId,
    required this.className,
    required this.timeRange,
    required this.date,
    required this.maxParticipants,
    this.room,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    context.read<ClassProvider>().fetchRegistrations(widget.scheduleId);
    context.read<MemberProvider>().fetchMembers();
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = context.watch<ClassProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.staff?.isAdminOrManager ?? false;

    // Filter registrations that aren't cancelled
    final activeRegs = classProvider.registrations.where((r) => r.status != RegistrationStatus.cancelled).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              onPressed: () => _confirmDeleteSchedule(context),
            ),
        ],
      ),
      floatingActionButton: activeRegs.length < widget.maxParticipants
          ? FloatingActionButton.extended(
              onPressed: () => _openRegisterMemberDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Đăng ký học viên'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Danh sách điểm danh',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Expanded(child: _buildAttendanceList(classProvider)),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    final formattedDate = DateFormat('dd/MM/yyyy').format(widget.date);
    final count = context.read<ClassProvider>().registrations.where((r) => r.status != RegistrationStatus.cancelled).length;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeaderDetail(Icons.calendar_today, 'Ngày học', formattedDate),
                _buildHeaderDetail(Icons.access_time, 'Thời gian', widget.timeRange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeaderDetail(Icons.room, 'Phòng', widget.room ?? 'Chưa set'),
                _buildHeaderDetail(Icons.people, 'Sĩ số', '$count / ${widget.maxParticipants}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceList(ClassProvider provider) {
    if (provider.isLoading && provider.registrations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.registrations.isEmpty) {
      return const Center(
        child: Text('Chưa có học viên nào đăng ký buổi học này', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      itemCount: provider.registrations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = provider.registrations[index];
        final memberProvider = context.read<MemberProvider>();

        // Find member details
        final memberName = r.memberName ??
            memberProvider.members.firstWhere((m) => m.id == r.memberId,
                orElse: () => Member(id: 0, fullName: 'HV #${r.memberId}', phone: '', gender: Gender.other, joinDate: DateTime.now(), status: '')).fullName;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (r.memberPhone != null) ...[
                        const SizedBox(height: 4),
                        Text(r.memberPhone!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ]
                    ],
                  ),
                ),
                _buildAttendanceSelector(r),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceSelector(ClassRegistration r) {
    Color color = Colors.blue;
    String label = 'Đăng ký';
    if (r.status == RegistrationStatus.attended) {
      color = Colors.green;
      label = 'Có mặt';
    } else if (r.status == RegistrationStatus.absent) {
      color = Colors.orange;
      label = 'Vắng mặt';
    } else if (r.status == RegistrationStatus.cancelled) {
      color = Colors.red;
      label = 'Đã hủy';
    }

    return PopupMenuButton<RegistrationStatus>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: color, size: 16),
          ],
        ),
      ),
      onSelected: (status) async {
        await context.read<ClassProvider>().updateAttendance(
              r.id,
              status.name,
              widget.scheduleId,
            );
        _refreshData();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: RegistrationStatus.registered,
          child: Text('Đã đăng ký'),
        ),
        const PopupMenuItem(
          value: RegistrationStatus.attended,
          child: Text('Có mặt (Điểm danh)'),
        ),
        const PopupMenuItem(
          value: RegistrationStatus.absent,
          child: Text('Vắng mặt'),
        ),
        const PopupMenuItem(
          value: RegistrationStatus.cancelled,
          child: Text('Hủy đăng ký', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Future<void> _openRegisterMemberDialog() async {
    final memberProvider = context.read<MemberProvider>();
    final classProvider = context.read<ClassProvider>();

    if (memberProvider.members.isEmpty) {
      await memberProvider.fetchMembers();
    }

    // Filter members who aren't already registered
    final registeredIds = classProvider.registrations
        .where((r) => r.status != RegistrationStatus.cancelled)
        .map((r) => r.memberId)
        .toSet();

    final availableMembers = memberProvider.members
        .where((m) => m.isActive && !registeredIds.contains(m.id))
        .toList();

    if (!mounted) return;

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có thành viên hoạt động nào sẵn có để đăng ký.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    int? selectedMemberId = availableMembers.first.id;

    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đăng ký học viên vào lớp'),
          content: DropdownButtonFormField<int>(
            value: selectedMemberId,
            decoration: const InputDecoration(labelText: 'Chọn học viên'),
            items: availableMembers
                .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.fullName} (${m.phone})')))
                .toList(),
            onChanged: (val) {
              setDialogState(() => selectedMemberId = val);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(
              onPressed: () async {
                final success = await classProvider.registerMember(widget.scheduleId, selectedMemberId!);
                if (ctx.mounted) Navigator.pop(ctx, success);
              },
              child: const Text('Đăng ký'),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng ký học viên thành công!'), backgroundColor: Colors.green),
        );
      }
    });
  }

  Future<void> _confirmDeleteSchedule(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa buổi học nhóm?'),
        content: const Text('Hành động này sẽ xóa buổi học này khỏi lịch biểu và hủy tất cả đăng ký học viên.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final classProvider = context.read<ClassProvider>();
      final success = await classProvider.deleteSchedule(widget.scheduleId);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa buổi học nhóm thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }
}
