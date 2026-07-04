import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/member.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;

  const MemberCard({super.key, required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(
                  member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 13, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(member.phone,
                            style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(status: member.status),
            ],
          ),
        ),
      ),
    );
  }
}
