import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
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
                        AxisControl(
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
                        AxisControl(
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
                        AxisControl(
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
                        AxisControl(
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
                        AxisControl(
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
                        AxisControl(
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
              PositionCard(pose: state.pose!),
              const SizedBox(height: AppSpacing.md),
              JointsCard(joints: state.joints!),
              const SizedBox(height: AppSpacing.md),
              ConfigCard(
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

