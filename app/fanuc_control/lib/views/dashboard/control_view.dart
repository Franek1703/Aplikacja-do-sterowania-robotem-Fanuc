import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/dashboard/cubit/robot_control_cubit.dart';
import '../../features/dashboard/widgets/axis_control.dart';
import '../../features/dashboard/widgets/position_card.dart';
import '../../features/dashboard/widgets/joints_card.dart';
import '../../features/dashboard/widgets/config_card.dart';

class ControlView extends StatelessWidget {
  final String robotId;
  final String deviceId;

  const ControlView({super.key, required this.robotId, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.uid ?? '';

    return BlocProvider(
      create: (context) => RobotControlCubit(
        deviceId: deviceId,
        robotId: robotId,
        userId: userId,
      ),
      child: BlocBuilder<RobotControlCubit, RobotControlState>(
        builder: (context, state) {
          if (state.isLoading || state.pose == null || state.joints == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
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
                        AxisControl(
                          label: 'X',
                          value: state.pose!.x,
                          onIncrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'x',
                              'delta': 1.0,
                            });
                          },
                          onDecrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'x',
                              'delta': -1.0,
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AxisControl(
                          label: 'Y',
                          value: state.pose!.y,
                          onIncrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'y',
                              'delta': 1.0,
                            });
                          },
                          onDecrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'y',
                              'delta': -1.0,
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AxisControl(
                          label: 'Z',
                          value: state.pose!.z,
                          onIncrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'z',
                              'delta': 1.0,
                            });
                          },
                          onDecrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'z',
                              'delta': -1.0,
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: Column(
                      children: [
                        AxisControl(
                          label: 'W',
                          value: state.pose!.w,
                          onIncrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'w',
                              'delta': 1.0,
                            });
                          },
                          onDecrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'w',
                              'delta': -1.0,
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AxisControl(
                          label: 'P',
                          value: state.pose!.p,
                          onIncrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'p',
                              'delta': 1.0,
                            });
                          },
                          onDecrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'p',
                              'delta': -1.0,
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AxisControl(
                          label: 'R',
                          value: state.pose!.r,
                          onIncrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'r',
                              'delta': 1.0,
                            });
                          },
                          onDecrement: () {
                            context.read<RobotControlCubit>().sendMoveCommand({
                              'axis': 'r',
                              'delta': -1.0,
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PositionCard(pose: state.pose!),
              const SizedBox(height: AppSpacing.md),
              JointsCard(joints: state.joints!),
              const SizedBox(height: AppSpacing.md),
              ConfigCard(
                userFrame: state.userFrame,
                toolNumber: state.toolNumber,
                activeProgram: state.activeProgram,
                onUserFrameChanged: (frame) {
                  context.read<RobotControlCubit>().updateConfig(userFrame: frame);
                },
                onToolNumberChanged: (tool) {
                  context.read<RobotControlCubit>().updateConfig(toolNumber: tool);
                },
                onActiveProgramChanged: (program) {
                  context.read<RobotControlCubit>().updateConfig(activeProgram: program);
                },
              ),
            ],
          ),
        );
        },
      ),
    );
  }
}

