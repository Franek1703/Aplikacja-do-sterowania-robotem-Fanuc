import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/status_indicator.dart';
import '../../config/constants/app_colors.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../dashboard/control_view.dart';
import '../dashboard/ftp_view.dart';
import '../dashboard/alarms_view.dart';
import '../dashboard/parameters_view.dart';

class DashboardView extends StatefulWidget {
  final String robotId;
  final String deviceId;

  const DashboardView({
    super.key,
    required this.robotId,
    required this.deviceId,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(
        robotId: widget.robotId,
        deviceId: widget.deviceId,
      ),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (!authState.isAuthenticated) {
            context.go('/login');
            return const SizedBox.shrink();
          }

          return BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              if (state.isLoading) {
                return AppScaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  body: const Center(child: CircularProgressIndicator()),
                );
              }

              if (state.robot == null) {
                return AppScaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  body: const Center(
                    child: Text(
                      'Robot not found',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                );
              }

              return AppScaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                    color: AppColors.textSecondary,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.robot!.name),
                      Text(
                        state.robot!.model ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: StatusIndicator(
                        isOnline: state.robot!.isOnline,
                        size: 10,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: () => context.push('/account'),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                body: IndexedStack(
                  index: _selectedTab,
                  children: [
                    ControlView(
                      robotId: widget.robotId,
                      deviceId: widget.deviceId,
                    ),
                    FtpView(
                      robotId: widget.robotId,
                      deviceId: widget.deviceId,
                    ),
                    AlarmsView(
                      robotId: widget.robotId,
                      deviceId: widget.deviceId,
                    ),
                    ParametersView(
                      robotId: widget.robotId,
                      deviceId: widget.deviceId,
                    ),
                  ],
                ),
                bottomNavigationBar: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BottomNavItem(
                          icon: Icons.gamepad,
                          label: 'Control',
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        _BottomNavItem(
                          icon: Icons.folder,
                          label: 'FTP',
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                        _BottomNavItem(
                          icon: Icons.warning,
                          label: 'Alarms',
                          isSelected: _selectedTab == 2,
                          onTap: () => setState(() => _selectedTab = 2),
                        ),
                        _BottomNavItem(
                          icon: Icons.settings,
                          label: 'Parameters',
                          isSelected: _selectedTab == 3,
                          onTap: () => setState(() => _selectedTab = 3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    top: BorderSide(color: AppColors.primaryYellow, width: 2),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryYellow
                    : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryYellow
                      : AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

