import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/package.dart';
import '../../providers/package_provider.dart';

class PackageFormScreen extends StatefulWidget {
  final GymPackage? package;
  const PackageFormScreen({super.key, this.package});

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  bool _isActive = true;
  bool _submitting = false;

  bool get _isEdit => widget.package != null;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _nameController = TextEditingController(text: p?.name ?? '');
    _durationController = TextEditingController(text: p != null ? p.durationDays.toString() : '');
    _priceController = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _isActive = p == null ? true : p.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final pkg = GymPackage(
      id: widget.package?.id ?? 0,
      name: _nameController.text.trim(),
      durationDays: int.parse(_durationController.text.trim()),
      price: double.parse(_priceController.text.trim()),
      description: _descriptionController.text.trim(),
      isActive: _isActive ? 'active' : 'inactive',
    );

    final provider = context.read<PackageProvider>();
    final success = _isEdit
        ? await provider.updatePackage(widget.package!.id, pkg)
        : await provider.createPackage(pkg);

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
      appBar: AppBar(title: Text(_isEdit ? 'Sửa gói tập' : 'Thêm gói tập')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên gói tập *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Thời hạn (ngày) *'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Phải là số nguyên dương';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Giá (đ) *'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                final n = double.tryParse(v.trim());
                if (n == null || n < 0) return 'Giá không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Đang mở bán'),
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
                  : Text(_isEdit ? 'Lưu thay đổi' : 'Thêm gói tập'),
            ),
          ],
        ),
      ),
    );
  }
}
