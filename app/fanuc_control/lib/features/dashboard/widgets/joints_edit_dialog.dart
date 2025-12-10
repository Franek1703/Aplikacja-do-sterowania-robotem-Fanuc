import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/secondary_button.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import '../cubit/robot_control_cubit.dart';
import '../../../models/robot_pose.dart';

class JointsEditDialog extends StatefulWidget {
  final RobotJoints initialJoints;

  const JointsEditDialog({super.key, required this.initialJoints});

  @override
  State<JointsEditDialog> createState() => _JointsEditDialogState();
}

class _JointsEditDialogState extends State<JointsEditDialog> {
  late final TextEditingController _j1Controller;
  late final TextEditingController _j2Controller;
  late final TextEditingController _j3Controller;
  late final TextEditingController _j4Controller;
  late final TextEditingController _j5Controller;
  late final TextEditingController _j6Controller;

  @override
  void initState() {
    super.initState();
    _j1Controller = TextEditingController(text: widget.initialJoints.j1.toStringAsFixed(1));
    _j2Controller = TextEditingController(text: widget.initialJoints.j2.toStringAsFixed(1));
    _j3Controller = TextEditingController(text: widget.initialJoints.j3.toStringAsFixed(1));
    _j4Controller = TextEditingController(text: widget.initialJoints.j4.toStringAsFixed(1));
    _j5Controller = TextEditingController(text: widget.initialJoints.j5.toStringAsFixed(1));
    _j6Controller = TextEditingController(text: widget.initialJoints.j6.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _j1Controller.dispose();
    _j2Controller.dispose();
    _j3Controller.dispose();
    _j4Controller.dispose();
    _j5Controller.dispose();
    _j6Controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final j1 = double.tryParse(_j1Controller.text) ?? widget.initialJoints.j1;
    final j2 = double.tryParse(_j2Controller.text) ?? widget.initialJoints.j2;
    final j3 = double.tryParse(_j3Controller.text) ?? widget.initialJoints.j3;
    final j4 = double.tryParse(_j4Controller.text) ?? widget.initialJoints.j4;
    final j5 = double.tryParse(_j5Controller.text) ?? widget.initialJoints.j5;
    final j6 = double.tryParse(_j6Controller.text) ?? widget.initialJoints.j6;

    // Send move command with joint values
    context.read<RobotControlCubit>().sendMoveCommand({
      'type': 'moveJoints',
      'joints': {
        'j1': j1,
        'j2': j2,
        'j3': j3,
        'j4': j4,
        'j5': j5,
        'j6': j6,
      },
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_ethernet,
                    color: AppColors.primaryYellow,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Edit Joint Values',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'J1',
                            controller: _j1Controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                '°',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: 'J2',
                            controller: _j2Controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                '°',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: 'J3',
                            controller: _j3Controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                '°',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'J4',
                            controller: _j4Controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                '°',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: 'J5',
                            controller: _j5Controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                '°',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: 'J6',
                            controller: _j6Controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                '°',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Cancel',
                      icon: Icons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Move',
                      icon: Icons.check,
                      onPressed: _handleSave,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

