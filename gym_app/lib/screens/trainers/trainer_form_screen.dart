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
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _expController;
  late final TextEditingController _salaryController;
  late String _status;

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
    _expController = TextEditingController(text: t != null ? '${t.experienceYears}' : '0');
    _salaryController = TextEditingController(
      text: (t?.salary != null) ? t!.salary!.toStringAsFixed(0) : '',
    );
    _status = t?.status ?? 'active';
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
    final provider = context.read<TrainerProvider>();

    final trainer = Trainer(
      id: widget.trainer?.id ?? 0,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
      experienceYears: int.tryParse(_expController.text) ?? 0,
      salary: double.tryParse(_salaryController.text),
      status: _status,
    );

    bool success;
    if (_isEdit) {
      success = await provider.updateTrainer(widget.trainer!.id, trainer);
    } else {
      success = await provider.createTrainer(trainer);
    }

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Đã cập nhật huấn luyện viên thành công!'
                : 'Đã thêm huấn luyện viên mới thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Có lỗi xảy ra, vui lòng thử lại.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá huấn luyện viên?'),
        content: Text('Bạn có chắc muốn xoá "${widget.trainer!.fullName}"? Hành động này không thể hoàn tác.'),
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
      setState(() => _submitting = true);
      final success = await context.read<TrainerProvider>().deleteTrainer(widget.trainer!.id);
      if (mounted) {
        setState(() => _submitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xoá huấn luyện viên!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        } else {
          final err = context.read<TrainerProvider>().errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err ?? 'Lỗi khi xoá huấn luyện viên.'), backgroundColor: AppTheme.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa thông tin HLV' : 'Thêm HLV mới'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              onPressed: _submitting ? null : _confirmDelete,
            ),
        ],
      ),
      body: _submitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Chuyên môn (ví dụ: Gym, Yoga, Boxing)',
                      prefixIcon: Icon(Icons.star),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expController,
                          decoration: const InputDecoration(
                            labelText: 'Kinh nghiệm (năm) *',
                            prefixIcon: Icon(Icons.history),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || int.tryParse(v) == null
                              ? 'Vui lòng nhập số năm kinh nghiệm'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _salaryController,
                          decoration: const InputDecoration(
                            labelText: 'Lương (đ) *',
                            prefixIcon: Icon(Icons.money),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Vui lòng nhập mức lương' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEdit) ...[
                    const Text('Trạng thái hoạt động', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                        DropdownMenuItem(value: 'inactive', child: Text('Tạm dừng hoạt động')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isEdit ? 'CẬP NHẬT' : 'THÊM MỚI'),
                  ),
                ],
              ),
            ),
    );
  }
}
