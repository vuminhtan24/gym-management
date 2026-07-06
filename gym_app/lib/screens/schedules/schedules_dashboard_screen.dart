import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pt_schedule_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../providers/member_provider.dart';
import '../../models/pt_schedule.dart';
import '../../models/class_schedule.dart';
import '../../models/trainer.dart';
import '../../models/member.dart';
import '../../models/group_class.dart';
import 'pt_schedule_form_sheet.dart';
import '../classes/class_detail_screen.dart';

class SchedulesDashboardScreen extends StatefulWidget {
  const SchedulesDashboardScreen({super.key});

  @override
  State<SchedulesDashboardScreen> createState() => _SchedulesDashboardScreenState();
}

class _SchedulesDashboardScreenState extends State<SchedulesDashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _loadDataForSelectedDay();
    });
    _loadDataForSelectedDay();
    // Pre-fetch lists needed for booking forms
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainerProvider>().fetchTrainers();
      context.read<MemberProvider>().fetchMembers();
      context.read<ClassProvider>().fetchClasses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDataForSelectedDay() {
    final startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final endOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59);

    if (_tabController.index == 0) {
      context.read<PTScheduleProvider>().fetchSchedules(
            dateFrom: startOfDay,
            dateTo: endOfDay,
          );
    } else {
      context.read<ClassProvider>().fetchSchedules(
            dateFrom: startOfDay,
            dateTo: endOfDay,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManage = auth.staff?.isAdminOrManager ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Hoạt Động'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Lịch dạy PT 1-1'),
            Tab(icon: Icon(Icons.groups), text: 'Lớp học nhóm'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0
            ? _openAddPtScheduleSheet()
            : _openAddClassScheduleDialog(canManage),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 1.5,
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadDataForSelectedDay();
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPtSchedulesTab(),
                _buildClassSchedulesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPtSchedulesTab() {
    final provider = context.watch<PTScheduleProvider>();
    final trainers = context.watch<TrainerProvider>().trainers;
    final members = context.watch<MemberProvider>().members;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.schedules.isEmpty) {
      return _buildEmptyState('Không có lịch tập PT nào trong ngày này');
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDataForSelectedDay(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: provider.schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final s = provider.schedules[index];
          // Find trainer & member name
          final trainer = trainers.firstWhere((t) => t.id == s.trainerId,
              orElse: () => Trainer(id: 0, fullName: 'HLV #${s.trainerId}', phone: '', specialty: '', experienceYears: 0, status: ''));
          final member = members.firstWhere((m) => m.id == s.memberId,
              orElse: () => Member(id: 0, fullName: 'Thành viên #${s.memberId}', phone: '', gender: Gender.other, joinDate: DateTime.now(), status: ''));

          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showPtScheduleActions(s, member.fullName, trainer.fullName),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.access_time, color: AppTheme.primary, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            s.startTime.substring(0, 5),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HV: ${member.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                          const SizedBox(height: 4),
                          Text('HLV: ${trainer.fullName}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (s.notes != null && s.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Ghi chú: ${s.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    _buildPtStatusBadge(s.status),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassSchedulesTab() {
    final provider = context.watch<ClassProvider>();
    final classes = provider.classes;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.schedules.isEmpty) {
      return _buildEmptyState('Không có lớp học nhóm nào trong ngày này');
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDataForSelectedDay(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: provider.schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final s = provider.schedules[index];
          // Find class details
          final groupClass = classes.firstWhere((c) => c.id == s.classId,
              orElse: () => GroupClass(id: 0, name: 'Lớp học #${s.classId}', maxParticipants: 20));

          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ClassDetailScreen(
                    scheduleId: s.id,
                    className: groupClass.name,
                    timeRange: s.timeRange,
                    date: s.date,
                    maxParticipants: groupClass.maxParticipants,
                    room: groupClass.room,
                  ),
                ),
              ).then((_) => _loadDataForSelectedDay()),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.class_outlined, color: Colors.purple, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            s.startTime.substring(0, 5),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(groupClass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                          const SizedBox(height: 4),
                          Text(
                            'Phòng: ${groupClass.room ?? "Chưa set"} • Thời gian: ${s.timeRange}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đã đăng ký: ${s.registeredCount}/${groupClass.maxParticipants}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildPtStatusBadge(String status) {
    Color color = Colors.blue;
    String label = 'Đã lên lịch';
    if (status == 'completed') {
      color = Colors.green;
      label = 'Hoàn thành';
    } else if (status == 'cancelled') {
      color = Colors.red;
      label = 'Đã hủy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _openAddPtScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PtScheduleFormSheet(selectedDate: _selectedDay),
    ).then((result) {
      if (result == true) _loadDataForSelectedDay();
    });
  }

  Future<void> _openAddClassScheduleDialog(bool canManage) async {
    if (!canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ Admin/Quản lý mới được lên lịch lớp nhóm.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    final classProvider = context.read<ClassProvider>();
    if (classProvider.classes.isEmpty) {
      await classProvider.fetchClasses();
    }

    if (!mounted) return;

    if (classProvider.classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo lớp học nhóm trước tại tab Quản lý.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    int? selectedClassId = classProvider.classes.first.id;
    final timeStartController = TextEditingController(text: '08:00');
    final timeEndController = TextEditingController(text: '09:00');

    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lên lịch buổi học nhóm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedClassId,
                decoration: const InputDecoration(labelText: 'Lớp học'),
                items: classProvider.classes
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (val) {
                  setDialogState(() => selectedClassId = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: timeStartController,
                decoration: const InputDecoration(labelText: 'Giờ bắt đầu (HH:MM)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: timeEndController,
                decoration: const InputDecoration(labelText: 'Giờ kết thúc (HH:MM)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(
              onPressed: () async {
                final schedule = ClassSchedule(
                  id: 0,
                  classId: selectedClassId!,
                  date: _selectedDay,
                  startTime: '${timeStartController.text}:00',
                  endTime: '${timeEndController.text}:00',
                );
                final success = await classProvider.createSchedule(schedule);
                if (ctx.mounted) {
                  Navigator.pop(ctx, success);
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadDataForSelectedDay();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lên lịch buổi học thành công!'), backgroundColor: Colors.green),
        );
      }
    });
  }

  void _showPtScheduleActions(PTSchedule s, String memberName, String trainerName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('HV: $memberName - HLV: $trainerName', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Thời gian: ${s.timeRange} | ${DateFormat('dd/MM/yyyy').format(s.date)}'),
            ),
            const Divider(),
            if (s.status == 'scheduled') ...[
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Đánh dấu: Đã hoàn thành ca dạy'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<PTScheduleProvider>().updateScheduleStatus(s.id, 'completed');
                  _loadDataForSelectedDay();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text('Hủy ca dạy này'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<PTScheduleProvider>().updateScheduleStatus(s.id, 'cancelled');
                  _loadDataForSelectedDay();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
              title: const Text('Xóa lịch tập', style: TextStyle(color: AppTheme.danger)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Xóa lịch tập?'),
                    content: const Text('Bạn có chắc muốn xóa lịch tập PT này không?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Hủy')),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text('Xóa', style: TextStyle(color: AppTheme.danger)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await context.read<PTScheduleProvider>().deleteSchedule(s.id);
                  _loadDataForSelectedDay();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
