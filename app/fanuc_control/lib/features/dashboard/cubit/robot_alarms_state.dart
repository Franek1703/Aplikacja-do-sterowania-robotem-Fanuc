part of 'robot_alarms_cubit.dart';

/// Robot alarms state
class RobotAlarmsState extends Equatable {
  final List<Alarm> alarms;
  final bool isLoading;
  final String? error;

  const RobotAlarmsState({
    this.alarms = const [],
    this.isLoading = false,
    this.error,
  });

  const RobotAlarmsState.initial()
      : alarms = const [],
        isLoading = false,
        error = null;

  const RobotAlarmsState.loading()
      : alarms = const [],
        isLoading = true,
        error = null;

  const RobotAlarmsState.loaded(List<Alarm> this.alarms)
      : isLoading = false,
        error = null;

  const RobotAlarmsState.error(String this.error)
      : alarms = const [],
        isLoading = false;

  @override
  List<Object?> get props => [alarms, isLoading, error];
}

