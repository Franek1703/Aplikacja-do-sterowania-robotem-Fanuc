import 'package:flutter/material.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.yellowOverlay,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.factory,
            size: 48,
            color: AppColors.primaryYellow,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'FANUC Controller',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Remote Robot Management Platform',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

