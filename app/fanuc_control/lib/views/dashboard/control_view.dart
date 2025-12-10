import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/primary_button.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../models/robot_pose.dart';

class ControlView extends StatelessWidget {
  final String robotId;
  final String deviceId;

  const ControlView({
    super.key,
    required this.robotId,
    required this.deviceId,
  });

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
                children: [
                  // Left axis controls
                  SizedBox(
                    width: 200,
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
                  const SizedBox(width: AppSpacing.md),
                  // Center info cards
                  Expanded(
                    child: Column(
                      children: [
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
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Right axis controls
                  SizedBox(
                    width: 200,
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
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        PrimaryButton(
          text: '$label+',
          icon: Icons.arrow_drop_up,
          onPressed: onIncrement,
          width: double.infinity,
        ),
        const SizedBox(height: 4),
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
        // TODO: Open position edit dialog
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
        // TODO: Open joints edit dialog
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
              _ValueTile('J1', '${joints.j1.toStringAsFixed(1)}°', isHighlight: true),
              _ValueTile('J2', '${joints.j2.toStringAsFixed(1)}°', isHighlight: true),
              _ValueTile('J3', '${joints.j3.toStringAsFixed(1)}°', isHighlight: true),
              _ValueTile('J4', '${joints.j4.toStringAsFixed(1)}°', isHighlight: true),
              _ValueTile('J5', '${joints.j5.toStringAsFixed(1)}°', isHighlight: true),
              _ValueTile('J6', '${joints.j6.toStringAsFixed(1)}°', isHighlight: true),
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

  const _ValueTile(
    this.label,
    this.value, {
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.primaryYellow : AppColors.textPrimary,
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
            labels: const ['Frame 0 (World)', 'Frame 1 (Custom)', 'Frame 2 (Workpiece)'],
            onChanged: (value) => onUserFrameChanged(int.parse(value)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ConfigDropdown(
            label: 'Tool Number',
            value: toolNumber.toString(),
            items: const ['1', '2', '3'],
            labels: const ['Tool 1 (Gripper)', 'Tool 2 (Welder)', 'Tool 3 (Camera)'],
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
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

