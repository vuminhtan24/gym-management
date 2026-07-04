import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/package.dart';
import '../../providers/package_provider.dart';

class AddSubscriptionSheet extends StatefulWidget {
  final int memberId;
  final List<GymPackage> packages;
  const AddSubscriptionSheet({super.key, required this.memberId, required this.packages});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  GymPackage? _selectedPackage;
  DateTime _startDate = DateTime.now();
  final _priceController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPackage = widget.packages.isNotEmpty ? widget.packages.first : null;
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedPackage == null) return;
    setState(() => _submitting = true);
    final provider = context.read<PackageProvider>();
    final priceText = _priceController.text.trim();
    final success = await provider.subscribeMember(
      memberId: widget.memberId,
      packageId: _selectedPackage!.id,
      startDate: _startDate,
      pricePaid: priceText.isEmpty ? null : double.tryParse(priceText),
    );
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Đăng ký gói tập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          DropdownButtonFormField<GymPackage>(
            initialValue: _selectedPackage,
            decoration: const InputDecoration(labelText: 'Gói tập'),
            items: widget.packages
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (${p.durationDays} ngày)'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedPackage = v),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Ngày bắt đầu'),
              child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Giá thanh toán (để trống = giá gói)',
              suffixText: _selectedPackage != null
                  ? '${NumberFormat.decimalPattern('vi_VN').format(_selectedPackage!.price)} đ'
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text('Xác nhận đăng ký'),
          ),
        ],
      ),
    );
  }
}
