import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/widgets/app_card.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import '../cubit/robot_control_cubit.dart';
import '../../../models/robot_pose.dart';
import 'joints_edit_dialog.dart';
import 'pose_value_tile.dart';

class JointsCard extends StatelessWidget {
  final RobotJoints joints;

  const JointsCard({super.key, required this.joints});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        final cubit = context.read<RobotControlCubit>();
        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider.value(
            value: cubit,
            child: JointsEditDialog(initialJoints: joints),
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
              PoseValueTile(
                'J1',
                '${joints.j1.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              PoseValueTile(
                'J2',
                '${joints.j2.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              PoseValueTile(
                'J3',
                '${joints.j3.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              PoseValueTile(
                'J4',
                '${joints.j4.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              PoseValueTile(
                'J5',
                '${joints.j5.toStringAsFixed(1)}°',
                isHighlight: true,
              ),
              PoseValueTile(
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

