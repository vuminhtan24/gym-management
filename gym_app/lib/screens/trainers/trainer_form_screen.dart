import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/trainer.dart';
import '../../providers/trainer_provider.dart';

/// Nếu [trainer] == null -> màn hình tạo mới. Ngược lại -> chỉnh sửa.
class TrainerFormScreen extends StatefulWidget {
  final Trainer? trainer;
  const TrainerFormScreen({super.key, this.trainer});

  @override
  State<TrainerFormScreen> createState() => _TrainerFormScreenState();
}

class _TrainerFormScreenState extends State<TrainerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _specialtyController;
  late TextEditingController _expController;
  late TextEditingController _salaryController;
  bool _isActive = true;
  bool _submitting = false;

  bool get _isEdit => widget.trainer != null;

  @override
  void initState() {
    super.initState();
    final t = widget.trainer;
    _nameController = TextEditingController(text: t?.fullName ?? '');
    _phoneController = TextEditingController(text: t?.phone ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _specialtyController = TextEditingController(text: t?.specialty ?? '');
    _expController = TextEditingController(text: t != null ? t.experienceYears.toString() : '0');
    _salaryController = TextEditingController(
        text: t?.salary != null ? t!.salary!.toStringAsFixed(0) : '');
    _isActive = t == null ? true : t.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _expController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final trainer = Trainer(
      id: widget.trainer?.id ?? 0,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      specialty: _specialtyController.text.trim(),
      experienceYears: int.tryParse(_expController.text.trim()) ?? 0,
      salary: double.tryParse(_salaryController.text.trim()),
      status: _isActive ? 'active' : 'inactive',
    );

    final provider = context.read<TrainerProvider>();
    final success = _isEdit
        ? await provider.updateTrainer(widget.trainer!.id, trainer)
        : await provider.createTrainer(trainer);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa huấn luyện viên' : 'Thêm huấn luyện viên')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Họ và tên *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                labelText: 'Chuyên môn',
                hintText: 'VD: Yoga, Gym, Boxing...',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _expController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số năm kinh nghiệm'),
              validator: (v) {
                if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                  return 'Vui lòng nhập số nguyên';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Lương (VNĐ)'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Đang hoạt động'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(_isEdit ? 'Lưu thay đổi' : 'Thêm huấn luyện viên'),
            ),
          ],
        ),
      ),
    );
  }
}
