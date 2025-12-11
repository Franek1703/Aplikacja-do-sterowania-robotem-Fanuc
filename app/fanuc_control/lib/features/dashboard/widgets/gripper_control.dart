import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/secondary_button.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';

class GripperControl extends StatelessWidget {
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final VoidCallback? onToggle;
  final bool isLoading;

  const GripperControl({
    super.key,
    this.onOpen,
    this.onClose,
    this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.precision_manufacturing,
                color: AppColors.primaryYellow,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Gripper Control',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Open',
                  icon: Icons.open_in_new,
                  onPressed: isLoading ? null : onOpen,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  text: 'Close',
                  icon: Icons.close,
                  onPressed: isLoading ? null : onClose,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  text: 'Toggle',
                  icon: Icons.swap_horiz,
                  onPressed: isLoading ? null : onToggle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

