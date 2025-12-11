import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import '../../../models/robot_parameter.dart';

class ParameterCard extends StatelessWidget {
  final RobotParameter parameter;
  final bool isEditing;
  final String editValue;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onEditValueChanged;

  const ParameterCard({
    super.key,
    required this.parameter,
    required this.isEditing,
    required this.editValue,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onToggle,
    required this.onEditValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                parameter.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (parameter.isLocked) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.lock,
                  size: 16,
                  color: AppColors.primaryYellow,
                ),
              ],
            ],
          ),
          if (parameter.description != null) ...[
            const SizedBox(height: 4),
            Text(
              parameter.description!,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (isEditing && !parameter.isLocked)
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: TextEditingController(text: editValue),
                    onChanged: onEditValueChanged,
                    keyboardType: parameter.type == ParameterType.number
                        ? TextInputType.number
                        : TextInputType.text,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: onSave,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: onCancel,
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (parameter.type == ParameterType.boolean)
                  Switch(
                    value: parameter.value as bool,
                    onChanged: parameter.isLocked
                        ? null
                        : (value) => onToggle(value),
                    activeColor: AppColors.primaryYellow,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${parameter.value}${parameter.unit ?? ''}',
                      style: const TextStyle(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (parameter.type != ParameterType.boolean && !parameter.isLocked)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

