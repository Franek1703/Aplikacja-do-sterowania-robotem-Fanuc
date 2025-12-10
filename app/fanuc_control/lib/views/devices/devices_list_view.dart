import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/status_indicator.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/devices/cubit/devices_cubit.dart';
import '../../features/auth/cubit/auth_cubit.dart';

class DevicesListView extends StatelessWidget {
  const DevicesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DevicesCubit(),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (!authState.isAuthenticated) {
            context.go('/login');
            return const SizedBox.shrink();
          }

          return AppScaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.yellowOverlay,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.factory,
                      color: AppColors.primaryYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FANUC Controller'),
                      Text(
                        'Remote Device Management',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => context.go('/account'),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            body: BlocBuilder<DevicesCubit, DevicesState>(
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
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: state.devices.length,
                    itemBuilder: (context, index) {
                      final device = state.devices[index];
                      return _DeviceCard(device: device);
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

class _DeviceCard extends StatelessWidget {
  final device;

  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        context.go('/robots?deviceId=${device.deviceId}');
      },
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: device.imageUrl != null
                      ? Image.network(
                          device.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.surface,
                              child: const Icon(
                                Icons.factory,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.factory,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                        ),
                ),
                // Status indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusIndicator(isOnline: device.online),
                ),
              ],
            ),
          ),
          // Device info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  device.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.online ? 'Online' : 'Offline',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

