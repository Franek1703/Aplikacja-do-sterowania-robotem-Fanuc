import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/primary_button.dart';
import '../../common/widgets/secondary_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../models/robot_pose.dart';

class ControlView extends StatelessWidget {
  final String robotId;
  final String deviceId;

  const ControlView({super.key, required this.robotId, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.pose == null || state.joints == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Three column layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left axis controls
                  SizedBox(
                    width: 160,
                    child: Column(
                      children: [
                        _AxisControl(
                          label: 'X',
                          value: state.pose!.x,
                          onIncrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(x: state.pose!.x + 1),
                            );
                          },
                          onDecrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(x: state.pose!.x - 1),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _AxisControl(
                          label: 'Y',
                          value: state.pose!.y,
                          onIncrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(y: state.pose!.y + 1),
                            );
                          },
                          onDecrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(y: state.pose!.y - 1),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _AxisControl(
                          label: 'Z',
                          value: state.pose!.z,
                          onIncrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(z: state.pose!.z + 1),
                            );
                          },
                          onDecrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(z: state.pose!.z - 1),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: Column(
                      children: [
                        _AxisControl(
                          label: 'W',
                          value: state.pose!.w,
                          onIncrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(w: state.pose!.w + 1),
                            );
                          },
                          onDecrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(w: state.pose!.w - 1),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _AxisControl(
                          label: 'P',
                          value: state.pose!.p,
                          onIncrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(p: state.pose!.p + 1),
                            );
                          },
                          onDecrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(p: state.pose!.p - 1),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _AxisControl(
                          label: 'R',
                          value: state.pose!.r,
                          onIncrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(r: state.pose!.r + 1),
                            );
                          },
                          onDecrement: () {
                            context.read<DashboardCubit>().updatePose(
                              state.pose!.copyWith(r: state.pose!.r - 1),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PositionCard(pose: state.pose!),
              const SizedBox(height: AppSpacing.md),
              _JointsCard(joints: state.joints!),
              const SizedBox(height: AppSpacing.md),
              _ConfigCard(
                userFrame: state.userFrame,
                toolNumber: state.toolNumber,
                activeProgram: state.activeProgram,
                onUserFrameChanged: (frame) {
                  context.read<DashboardCubit>().setUserFrame(frame);
                },
                onToolNumberChanged: (tool) {
                  context.read<DashboardCubit>().setToolNumber(tool);
                },
                onActiveProgramChanged: (program) {
                  context.read<DashboardCubit>().setActiveProgram(program);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AxisControl extends StatelessWidget {
  final String label;
  final double value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _AxisControl({
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

class _PositionCard extends StatelessWidget {
  final RobotPose pose;

  const _PositionCard({required this.pose});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        final cubit = context.read<DashboardCubit>();
        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider.value(
            value: cubit,
            child: _PositionEditDialog(initialPose: pose),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Position',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2,
            children: [
              _ValueTile('X', pose.x.toStringAsFixed(2)),
              _ValueTile('Y', pose.y.toStringAsFixed(2)),
              _ValueTile('Z', pose.z.toStringAsFixed(2)),
              _ValueTile('W', pose.w.toStringAsFixed(2)),
              _ValueTile('P', pose.p.toStringAsFixed(2)),
              _ValueTile('R', pose.r.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _JointsCard extends StatelessWidget {
  final RobotJoints joints;

  const _JointsCard({required this.joints});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        final cubit = context.read<DashboardCubit>();
        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider.value(
            value: cubit,
            child: _JointsEditDialog(initialJoints: joints),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Joint Values',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2,
            children: [
              _ValueTile(
                'J1',
                '${joints.j1.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              _ValueTile(
                'J2',
                '${joints.j2.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              _ValueTile(
                'J3',
                '${joints.j3.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              _ValueTile(
                'J4',
                '${joints.j4.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              _ValueTile(
                'J5',
                '${joints.j5.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              _ValueTile(
                'J6',
                '${joints.j6.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _ValueTile(this.label, this.value, {this.isHighlight = false});

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

class _ConfigCard extends StatelessWidget {
  final int userFrame;
  final int toolNumber;
  final String activeProgram;
  final ValueChanged<int> onUserFrameChanged;
  final ValueChanged<int> onToolNumberChanged;
  final ValueChanged<String> onActiveProgramChanged;

  const _ConfigCard({
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
          _ConfigDropdown(
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
          _ConfigDropdown(
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
          _ConfigDropdown(
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

class _ConfigDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final List<String> labels;
  final ValueChanged<String> onChanged;

  const _ConfigDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          items: List.generate(
            items.length,
            (index) => DropdownMenuItem(
              value: items[index],
              child: Text(labels[index]),
            ),
          ),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _PositionEditDialog extends StatefulWidget {
  final RobotPose initialPose;

  const _PositionEditDialog({required this.initialPose});

  @override
  State<_PositionEditDialog> createState() => _PositionEditDialogState();
}

class _PositionEditDialogState extends State<_PositionEditDialog> {
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

class _JointsEditDialog extends StatefulWidget {
  final RobotJoints initialJoints;

  const _JointsEditDialog({required this.initialJoints});

  @override
  State<_JointsEditDialog> createState() => _JointsEditDialogState();
}

class _JointsEditDialogState extends State<_JointsEditDialog> {
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

    final newJoints = RobotJoints(
      j1: j1,
      j2: j2,
      j3: j3,
      j4: j4,
      j5: j5,
      j6: j6,
      updatedAt: DateTime.now(),
    );

    context.read<DashboardCubit>().updateJoints(newJoints);
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
