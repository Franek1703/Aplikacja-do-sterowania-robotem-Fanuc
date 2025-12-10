import 'package:flutter/material.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../config/constants/app_colors.dart';

class AxisControl extends StatelessWidget {
  final String label;
  final double value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const AxisControl({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        const SizedBox(height: 4),
        PrimaryButton(
          text: '$label+',
          icon: Icons.arrow_drop_up,
          onPressed: onIncrement,
          width: double.infinity,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onDecrement,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_drop_down, size: 20),
              Text('$label−'),
            ],
          ),
        ),
      ],
    );
  }
}

