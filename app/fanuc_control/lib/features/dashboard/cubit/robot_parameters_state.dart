part of 'robot_parameters_cubit.dart';

/// Robot parameters state
class RobotParametersState extends Equatable {
  final List<RobotParameter> parameters;
  final bool isLoading;
  final String? error;

  const RobotParametersState({
    this.parameters = const [],
    this.isLoading = false,
    this.error,
  });

  const RobotParametersState.loading()
      : parameters = const [],
        isLoading = true,
        error = null;

  const RobotParametersState.loaded(List<RobotParameter> this.parameters)
      : isLoading = false,
        error = null;

  const RobotParametersState.error(String this.error)
      : parameters = const [],
        isLoading = false;

  @override
  List<Object?> get props => [parameters, isLoading, error];
}

