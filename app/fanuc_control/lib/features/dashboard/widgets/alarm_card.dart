import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import '../../../models/alarm.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onClear;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getSeverityConfig(alarm.severity);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              config.icon,
              color: config.color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: config.bgColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: config.color),
                      ),
                      child: Text(
                        alarm.code,
                        style: TextStyle(
                          color: config.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alarm.severity.toString(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alarm.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(alarm.timestamp),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                if (alarm.description != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      alarm.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClear,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  _SeverityConfig _getSeverityConfig(AlarmSeverity severity) {
    switch (severity) {
      case AlarmSeverity.error:
        return _SeverityConfig(
          icon: Icons.error,
          color: AppColors.error,
          bgColor: AppColors.error.withOpacity(0.1),
        );
      case AlarmSeverity.warning:
        return _SeverityConfig(
          icon: Icons.warning,
          color: AppColors.warning,
          bgColor: AppColors.warning.withOpacity(0.1),
        );
      case AlarmSeverity.info:
        return _SeverityConfig(
          icon: Icons.info,
          color: AppColors.info,
          bgColor: AppColors.info.withOpacity(0.1),
        );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}

class _SeverityConfig {
  final IconData icon;
  final Color color;
  final Color bgColor;

  _SeverityConfig({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

