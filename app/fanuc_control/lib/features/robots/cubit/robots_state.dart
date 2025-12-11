part of 'robots_cubit.dart';

/// Robots state
class RobotsState extends Equatable {
  final List<Robot> robots;
  final bool isLoading;
  final String? error;

  const RobotsState({
    required this.robots,
    this.isLoading = false,
    this.error,
  });

  const RobotsState.initial()
      : robots = const [],
        isLoading = false,
        error = null;

  const RobotsState.loading()
      : robots = const [],
        isLoading = true,
        error = null;

  const RobotsState.loaded(List<Robot> this.robots)
      : isLoading = false,
        error = null;

  const RobotsState.error(String this.error)
      : robots = const [],
        isLoading = false;

  @override
  List<Object?> get props => [robots, isLoading, error];
}

