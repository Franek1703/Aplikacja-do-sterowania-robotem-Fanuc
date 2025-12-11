import 'package:flutter/material.dart';
import '../../../config/constants/app_colors.dart';

class PoseValueTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const PoseValueTile(
    this.label,
    this.value, {
    super.key,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: isHighlight
                  ? AppColors.primaryYellow
                  : AppColors.textPrimary,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

