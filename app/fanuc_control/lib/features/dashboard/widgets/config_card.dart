import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import 'config_dropdown.dart';

class ConfigCard extends StatelessWidget {
  final int userFrame;
  final int toolNumber;
  final String activeProgram;
  final ValueChanged<int> onUserFrameChanged;
  final ValueChanged<int> onToolNumberChanged;
  final ValueChanged<String> onActiveProgramChanged;

  const ConfigCard({
    super.key,
    required this.userFrame,
    required this.toolNumber,
    required this.activeProgram,
    required this.onUserFrameChanged,
    required this.onToolNumberChanged,
    required this.onActiveProgramChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ConfigDropdown(
            label: 'User Frame',
            value: userFrame.toString(),
            items: const ['0', '1', '2'],
            labels: const [
              'Frame 0 (World)',
              'Frame 1 (Custom)',
              'Frame 2 (Workpiece)',
            ],
            onChanged: (value) => onUserFrameChanged(int.parse(value)),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConfigDropdown(
            label: 'Tool Number',
            value: toolNumber.toString(),
            items: const ['1', '2', '3'],
            labels: const [
              'Tool 1 (Gripper)',
              'Tool 2 (Welder)',
              'Tool 3 (Camera)',
            ],
            onChanged: (value) => onToolNumberChanged(int.parse(value)),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConfigDropdown(
            label: 'Active Program',
            value: activeProgram,
            items: const ['MAIN001', 'PICKUP', 'ASSEMBLY'],
            labels: const ['MAIN001', 'PICKUP', 'ASSEMBLY'],
            onChanged: onActiveProgramChanged,
          ),
        ],
      ),
    );
  }
}

