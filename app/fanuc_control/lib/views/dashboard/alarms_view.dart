import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../common/widgets/secondary_button.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../features/dashboard/widgets/alarm_card.dart';
import '../../features/dashboard/widgets/no_alarms_card.dart';

class AlarmsView extends StatelessWidget {
  final String robotId;
  final String deviceId;

  const AlarmsView({
    super.key,
    required this.robotId,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final alarms = state.alarms;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Alarms',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alarms.length} total',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SecondaryButton(
                    text: 'Refresh',
                    icon: Icons.refresh,
                    onPressed: () {
                      // TODO: Implement refresh
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Alarms list
              if (alarms.isEmpty)
                const NoAlarmsCard()
              else
                ...alarms.map((alarm) => AlarmCard(
                      alarm: alarm,
                      onClear: () {
                        context.read<DashboardCubit>().clearAlarm(alarm.alarmId);
                      },
                    )),
            ],
          ),
        );
      },
    );
  }
}
