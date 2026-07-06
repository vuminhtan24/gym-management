import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/trainer.dart';

class TrainerCard extends StatelessWidget {
  final Trainer trainer;
  final VoidCallback onTap;

  const TrainerCard({super.key, required this.trainer, required this.onTap});

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
                backgroundColor: AppTheme.accent.withOpacity(0.12),
                child: Text(
                  trainer.fullName.isNotEmpty ? trainer.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.accent,
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
                      trainer.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (trainer.specialty != null && trainer.specialty!.isNotEmpty) ...[
                          const Icon(Icons.fitness_center, size: 13, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(
                            trainer.specialty!,
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Icon(Icons.phone, size: 13, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          trainer.phone,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                    if (trainer.experienceYears > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${trainer.experienceYears} năm kinh nghiệm',
                          style: const TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              StatusBadge(status: trainer.status),
            ],
          ),
        ),
      ),
    );
  }
}
