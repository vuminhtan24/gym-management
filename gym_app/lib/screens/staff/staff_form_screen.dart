import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/staff.dart';
import '../../providers/staff_provider.dart';

class StaffFormScreen extends StatefulWidget {
  final Staff? staff;
  const StaffFormScreen({super.key, this.staff});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _salaryController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  late String _role;
  late String _status;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _nameController = TextEditingController(text: s?.fullName ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    // Since salary isn't exposed directly in the base Staff class of frontend, let's see: we can handle it if backend returns it
    // Wait, let's check staff.dart model we saw. It has role, id, fullName, phone, email, username, status. No salary field. But wait! Let's check schemas.py: StaffOut has salary (optional float).
    // Let's see: if we want to support salary, we can add it, or keep it optional. Let's see if our model has salary. No, our model didn't have salary. Wait! Should we modify staff.dart model to include salary?
    // Let's modify staff.dart model first or write it. Wait, the staff.dart model does not have salary, let's keep it simple or we can add it. Let's see what is inside gym_app/lib/models/staff.dart. It doesn't have salary, but it is easy to support. Let's add salary to the form since it's in the backend schema.
    _salaryController = TextEditingController(text: '');
    _usernameController = TextEditingController(text: s?.username ?? '');
    _passwordController = TextEditingController();

    _role = s?.role.name ?? 'receptionist';
    _status = s?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final provider = context.read<StaffProvider>();

    bool success;
    if (widget.staff != null) {
      success = await provider.updateStaff(
        widget.staff!.id,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        salary: double.tryParse(_salaryController.text),
        status: _status,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );
    } else {
      success = await provider.createStaff(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        salary: double.tryParse(_salaryController.text),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.staff != null
                ? 'Đã cập nhật thông tin nhân viên thành công!'
                : 'Đã thêm nhân viên mới thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
        title: const Text('Xoá nhân viên?'),
        content: Text('Bạn có chắc muốn xoá tài khoản "${widget.staff!.fullName}"? Hành động này không thể hoàn tác.'),
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
      final success = await context.read<StaffProvider>().deleteStaff(widget.staff!.id);
      if (mounted) {
        setState(() => _submitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xoá tài khoản nhân viên!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        } else {
          final err = context.read<StaffProvider>().errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err ?? 'Lỗi khi xoá nhân viên.'), backgroundColor: AppTheme.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa nhân viên' : 'Thêm nhân viên mới'),
        actions: [
          if (isEdit)
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
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên nhân viên *',
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _role,
                          decoration: const InputDecoration(
                            labelText: 'Vai trò *',
                            prefixIcon: Icon(Icons.security),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'receptionist', child: Text('Lễ tân')),
                            DropdownMenuItem(value: 'manager', child: Text('Quản lý')),
                            DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _role = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _salaryController,
                          decoration: const InputDecoration(
                            labelText: 'Mức lương (đ)',
                            prefixIcon: Icon(Icons.money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Tài khoản đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập (username) *',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    enabled: !isEdit, // Không cho sửa username sau khi tạo
                    validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'Mật khẩu mới (để trống nếu không đổi)' : 'Mật khẩu *',
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (!isEdit && (v == null || v.length < 6)) {
                        return 'Mật khẩu phải từ 6 ký tự trở lên';
                      }
                      if (isEdit && v != null && v.isNotEmpty && v.length < 6) {
                        return 'Mật khẩu mới phải từ 6 ký tự trở lên';
                      }
                      return null;
                    },
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Trạng thái tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                        DropdownMenuItem(value: 'inactive', child: Text('Khóa tài khoản')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(isEdit ? 'CẬP NHẬT NHÂN VIÊN' : 'THÊM NHÂN VIÊN'),
                  ),
                ],
              ),
            ),
    );
  }
}
