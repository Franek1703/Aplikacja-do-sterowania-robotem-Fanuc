import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/secondary_button.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import '../../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../../models/robot_pose.dart';

class PositionEditDialog extends StatefulWidget {
  final RobotPose initialPose;

  const PositionEditDialog({super.key, required this.initialPose});

  @override
  State<PositionEditDialog> createState() => _PositionEditDialogState();
}

class _PositionEditDialogState extends State<PositionEditDialog> {
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  late final TextEditingController _zController;
  late final TextEditingController _wController;
  late final TextEditingController _pController;
  late final TextEditingController _rController;

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController(text: widget.initialPose.x.toStringAsFixed(2));
    _yController = TextEditingController(text: widget.initialPose.y.toStringAsFixed(2));
    _zController = TextEditingController(text: widget.initialPose.z.toStringAsFixed(2));
    _wController = TextEditingController(text: widget.initialPose.w.toStringAsFixed(2));
    _pController = TextEditingController(text: widget.initialPose.p.toStringAsFixed(2));
    _rController = TextEditingController(text: widget.initialPose.r.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _zController.dispose();
    _wController.dispose();
    _pController.dispose();
    _rController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final x = double.tryParse(_xController.text) ?? widget.initialPose.x;
    final y = double.tryParse(_yController.text) ?? widget.initialPose.y;
    final z = double.tryParse(_zController.text) ?? widget.initialPose.z;
    final w = double.tryParse(_wController.text) ?? widget.initialPose.w;
    final p = double.tryParse(_pController.text) ?? widget.initialPose.p;
    final r = double.tryParse(_rController.text) ?? widget.initialPose.r;

    final newPose = RobotPose(
      x: x,
      y: y,
      z: z,
      w: w,
      p: p,
      r: r,
      updatedAt: DateTime.now(),
    );

    context.read<DashboardCubit>().updatePose(newPose);
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
                    Icons.edit_location,
                    color: AppColors.primaryYellow,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Edit Position',
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
                            label: 'X',
                            controller: _xController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: 'Y',
                            controller: _yController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: 'Z',
                            controller: _zController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'W',
                            controller: _wController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: 'P',
                            controller: _pController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: 'R',
                            controller: _rController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

