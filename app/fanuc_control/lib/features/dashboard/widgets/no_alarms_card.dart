import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';

class NoAlarmsCard extends StatelessWidget {
  const NoAlarmsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No active alarms',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'All systems operating normally',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

