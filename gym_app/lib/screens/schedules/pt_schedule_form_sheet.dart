import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/pt_schedule.dart';
import '../../providers/pt_schedule_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../providers/member_provider.dart';

class PtScheduleFormSheet extends StatefulWidget {
  final DateTime selectedDate;
  const PtScheduleFormSheet({super.key, required this.selectedDate});

  @override
  State<PtScheduleFormSheet> createState() => _PtScheduleFormSheetState();
}

class _PtScheduleFormSheetState extends State<PtScheduleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedMemberId;
  int? _selectedTrainerId;
  late DateTime _date;
  final _timeStartController = TextEditingController(text: '08:00');
  final _timeEndController = TextEditingController(text: '09:00');
  final _notesController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate;
  }

  @override
  void dispose() {
    _timeStartController.dispose();
    _timeEndController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null || _selectedTrainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ Học viên và Huấn luyện viên'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<PTScheduleProvider>();

    final schedule = PTSchedule(
      id: 0,
      memberId: _selectedMemberId!,
      trainerId: _selectedTrainerId!,
      date: _date,
      startTime: '${_timeStartController.text}:00',
      endTime: '${_timeEndController.text}:00',
      status: 'scheduled',
      notes: _notesController.text.trim(),
    );

    final success = await provider.createSchedule(schedule);

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lịch tập PT thành công!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Trùng lịch dạy hoặc lỗi hệ thống'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainers = context.watch<TrainerProvider>().trainers.where((t) => t.isActive).toList();
    final members = context.watch<MemberProvider>().members.where((m) => m.isActive).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Đặt lịch tập PT 1-1 mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            if (_submitting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              DropdownButtonFormField<int>(
                value: _selectedMemberId,
                decoration: const InputDecoration(
                  labelText: 'Học viên (Thành viên) *',
                  prefixIcon: Icon(Icons.person),
                ),
                items: members
                    .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.fullName} (${m.phone})')))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMemberId = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedTrainerId,
                decoration: const InputDecoration(
                  labelText: 'Huấn luyện viên *',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                items: trainers
                    .map((t) => DropdownMenuItem(value: t.id, child: Text('${t.fullName} (${t.specialty ?? "Gym"})')))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTrainerId = val),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                title: const Text('Ngày hẹn', style: TextStyle(fontSize: 13, color: Colors.black54)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('Chọn ngày'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timeStartController,
                      decoration: const InputDecoration(labelText: 'Giờ bắt đầu (HH:MM) *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeEndController,
                      decoration: const InputDecoration(labelText: 'Giờ kết thúc (HH:MM) *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú thêm',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('XÁC NHẬN ĐẶT LỊCH'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
