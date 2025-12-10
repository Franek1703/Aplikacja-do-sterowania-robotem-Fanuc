import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_text_field.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../models/robot_parameter.dart';

class ParametersView extends StatefulWidget {
  final String robotId;
  final String deviceId;

  const ParametersView({
    super.key,
    required this.robotId,
    required this.deviceId,
  });

  @override
  State<ParametersView> createState() => _ParametersViewState();
}

class _ParametersViewState extends State<ParametersView> {
  String? _editingId;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final parameters = state.parameters;
        final categories = parameters.map((p) => p.category).toSet().toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.yellowOverlay,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: AppColors.primaryYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Robot Parameters',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Configure robot settings',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Parameters by category
              ...categories.map((category) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...parameters
                          .where((p) => p.category == category)
                          .map((param) => _ParameterCard(
                                parameter: param,
                                isEditing: _editingId == param.id,
                                editValue: _editController.text,
                                onEdit: () {
                                  setState(() {
                                    _editingId = param.id;
                                    _editController.text = param.value.toString();
                                  });
                                },
                                onSave: () {
                                  final value = param.type == ParameterType.number
                                      ? double.tryParse(_editController.text)
                                      : _editController.text;
                                  if (value != null) {
                                    context
                                        .read<DashboardCubit>()
                                        .updateParameter(param.id, value);
                                  }
                                  setState(() {
                                    _editingId = null;
                                    _editController.clear();
                                  });
                                },
                                onCancel: () {
                                  setState(() {
                                    _editingId = null;
                                    _editController.clear();
                                  });
                                },
                                onToggle: (value) {
                                  context
                                      .read<DashboardCubit>()
                                      .updateParameter(param.id, value);
                                },
                                onEditValueChanged: (value) {
                                  _editController.text = value;
                                },
                              )),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final RobotParameter parameter;
  final bool isEditing;
  final String editValue;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onEditValueChanged;

  const _ParameterCard({
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

