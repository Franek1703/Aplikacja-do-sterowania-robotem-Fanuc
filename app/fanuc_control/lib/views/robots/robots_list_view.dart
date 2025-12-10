import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/primary_button.dart';
import '../../common/widgets/secondary_button.dart';
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
                onPressed: () => context.pop(),
                color: AppColors.textSecondary,
              ),
              title: const Text('Connected Robots'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => context.push('/account'),
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

                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<RobotsCubit>().refreshRobots(deviceId);
                  },
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: ListView.separated(
                          itemCount: state.robots.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final robot = state.robots[index];
                            return _RobotCard(robot: robot, deviceId: deviceId);
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        right: 24,
                        child: FloatingActionButton.extended(
                          onPressed: () => _showAddRobotDialog(context, deviceId, context.read<RobotsCubit>()),
                          backgroundColor: AppColors.primaryYellow,
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text(
                            'Add Robot',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddRobotDialog(BuildContext context, String deviceId, RobotsCubit robotsCubit) {
    final nameController = TextEditingController();
    final ipAddressController = TextEditingController();
    final ftpUserController = TextEditingController();
    final ftpPasswordController = TextEditingController();
    final controllerController = TextEditingController();
    final modelController = TextEditingController();
    final tcpPortController = TextEditingController(text: '18735');
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.primaryYellow),
              SizedBox(width: 8),
              Text(
                'Add New Robot',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  label: 'Name *',
                  controller: nameController,
                  hint: 'e.g., FANUC R-2000iC/165F',
                  errorText: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'IP Address *',
                  controller: ipAddressController,
                  hint: 'e.g., 192.168.0.20',
                  keyboardType: TextInputType.number,
                  errorText: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'FTP User *',
                  controller: ftpUserController,
                  hint: 'e.g., anonymous',
                  errorText: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'FTP Password *',
                  controller: ftpPasswordController,
                  hint: 'Enter FTP password',
                  obscureText: true,
                  errorText: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Controller (optional)',
                  controller: controllerController,
                  hint: 'e.g., R-30iB',
                  errorText: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Model (optional)',
                  controller: modelController,
                  hint: 'e.g., R-2000iC/165F',
                  errorText: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'TCP Port (optional)',
                  controller: tcpPortController,
                  hint: '18735',
                  keyboardType: TextInputType.number,
                  errorText: null,
                ),
              ],
            ),
          ),
          actions: [
            SecondaryButton(
              text: 'Cancel',
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: AppSpacing.sm),
            PrimaryButton(
              text: 'Create',
              icon: Icons.check,
              onPressed: () async {
                final name = nameController.text.trim();
                final ipAddress = ipAddressController.text.trim();
                final ftpUser = ftpUserController.text.trim();
                final ftpPassword = ftpPasswordController.text.trim();
                final controller = controllerController.text.trim();
                final model = modelController.text.trim();
                final tcpPortStr = tcpPortController.text.trim();

                // Validation
                if (name.isEmpty) {
                  setState(() {
                    errorText = 'Name is required';
                  });
                  return;
                }
                if (ipAddress.isEmpty) {
                  setState(() {
                    errorText = 'IP Address is required';
                  });
                  return;
                }
                if (ftpUser.isEmpty) {
                  setState(() {
                    errorText = 'FTP User is required';
                  });
                  return;
                }
                if (ftpPassword.isEmpty) {
                  setState(() {
                    errorText = 'FTP Password is required';
                  });
                  return;
                }

                // Parse TCP port
                int tcpPort = 18735;
                if (tcpPortStr.isNotEmpty) {
                  final parsed = int.tryParse(tcpPortStr);
                  if (parsed == null || parsed <= 0) {
                    setState(() {
                      errorText = 'TCP Port must be a valid positive number';
                    });
                    return;
                  }
                  tcpPort = parsed;
                }

                setState(() {
                  errorText = null;
                });

                try {
                  await robotsCubit.createRobot(
                        deviceId: deviceId,
                        name: name,
                        ipAddress: ipAddress,
                        ftpUser: ftpUser,
                        ftpPassword: ftpPassword,
                        controller: controller.isEmpty ? null : controller,
                        model: model.isEmpty ? null : model,
                        tcpPort: tcpPort,
                      );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: const Text('Robot created successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() {
                    errorText = e.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotCard extends StatelessWidget {
  final robot;
  final String deviceId;

  const _RobotCard({required this.robot, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        context.push('/dashboard?robotId=${robot.robotId}&deviceId=$deviceId');
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
            child: const Icon(Icons.smart_toy, color: Colors.black, size: 24),
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
