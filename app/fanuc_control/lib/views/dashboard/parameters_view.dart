import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../features/dashboard/widgets/parameter_card.dart';
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
                          .map((param) => ParameterCard(
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
