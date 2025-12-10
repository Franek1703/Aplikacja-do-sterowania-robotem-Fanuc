import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/status_indicator.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/robots/cubit/robots_cubit.dart';
import '../../features/auth/cubit/auth_cubit.dart';

class RobotsListView extends StatelessWidget {
  final String deviceId;

  const RobotsListView({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RobotsCubit(deviceId: deviceId),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (!authState.isAuthenticated) {
            context.go('/login');
            return const SizedBox.shrink();
          }

          return AppScaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/devices'),
                color: AppColors.textSecondary,
              ),
              title: const Text('Connected Robots'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => context.go('/account'),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            body: BlocBuilder<RobotsCubit, RobotsState>(
              builder: (context, state) {
                if (state.isLoading) {
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

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ListView.separated(
                    itemCount: state.robots.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final robot = state.robots[index];
                      return _RobotCard(
                        robot: robot,
                        deviceId: deviceId,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RobotCard extends StatelessWidget {
  final robot;
  final String deviceId;

  const _RobotCard({
    required this.robot,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        context.go('/dashboard?robotId=${robot.robotId}&deviceId=$deviceId');
      },
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Robot icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Robot info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  robot.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  robot.model ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          StatusIndicator(isOnline: robot.isOnline),
        ],
      ),
    );
  }
}

