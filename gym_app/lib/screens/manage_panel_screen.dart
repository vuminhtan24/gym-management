import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/staff.dart';
import 'trainers/trainers_list_screen.dart';
import 'classes/group_classes_screen.dart';
import 'staff/staff_list_screen.dart';
import 'packages/packages_list_screen.dart';

class ManagePanelScreen extends StatelessWidget {
  const ManagePanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.staff?.role == StaffRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Trung tâm quản lý')),
      body: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        padding: const EdgeInsets.all(16),
        children: [
          _buildManageCard(
            context: context,
            title: 'Huấn luyện viên',
            subtitle: 'Quản lý HLV & chuyên môn',
            icon: Icons.fitness_center,
            color: Colors.blue,
            destination: const TrainersListScreen(),
          ),
          _buildManageCard(
            context: context,
            title: 'Lớp học nhóm',
            subtitle: 'Quản lý các lớp yoga, boxing...',
            icon: Icons.class_outlined,
            color: Colors.purple,
            destination: const GroupClassesScreen(),
          ),
          _buildManageCard(
            context: context,
            title: 'Gói tập gym',
            subtitle: 'Thiết lập các gói tập & giá tiền',
            icon: Icons.card_membership,
            color: Colors.orange,
            destination: const PackagesListScreen(),
          ),
          if (isAdmin)
            _buildManageCard(
              context: context,
              title: 'Nhân viên',
              subtitle: 'Quản lý tài khoản lễ tân/quản lý',
              icon: Icons.badge_outlined,
              color: Colors.green,
              destination: const StaffListScreen(),
            ),
        ],
      ),
    );
  }

  Widget _buildManageCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
