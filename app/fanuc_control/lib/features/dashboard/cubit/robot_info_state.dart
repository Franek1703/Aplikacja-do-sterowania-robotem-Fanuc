part of 'robot_info_cubit.dart';

/// Robot info state
class RobotInfoState extends Equatable {
  final Robot? robot;
  final bool isLoading;
  final String? error;

  const RobotInfoState({
    this.robot,
    this.isLoading = false,
    this.error,
  });

  const RobotInfoState.initial()
      : robot = null,
        isLoading = false,
        error = null;

  const RobotInfoState.loading()
      : robot = null,
        isLoading = true,
        error = null;

  const RobotInfoState.loaded(Robot this.robot)
      : isLoading = false,
        error = null;

  const RobotInfoState.error(String this.error)
      : robot = null,
        isLoading = false;

  @override
  List<Object?> get props => [robot, isLoading, error];
}

