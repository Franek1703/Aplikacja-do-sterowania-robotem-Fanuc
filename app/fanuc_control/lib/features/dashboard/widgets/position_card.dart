import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/widgets/app_card.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import '../../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../../models/robot_pose.dart';
import 'pose_value_tile.dart';
import 'position_edit_dialog.dart';

class PositionCard extends StatelessWidget {
  final RobotPose pose;

  const PositionCard({super.key, required this.pose});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        final cubit = context.read<DashboardCubit>();
        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider.value(
            value: cubit,
            child: PositionEditDialog(initialPose: pose),
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
              PoseValueTile('X', pose.x.toStringAsFixed(2)),
              PoseValueTile('Y', pose.y.toStringAsFixed(2)),
              PoseValueTile('Z', pose.z.toStringAsFixed(2)),
              PoseValueTile('W', pose.w.toStringAsFixed(2)),
              PoseValueTile('P', pose.p.toStringAsFixed(2)),
              PoseValueTile('R', pose.r.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }
}

