part of 'robot_control_cubit.dart';

/// Robot control state
class RobotControlState extends Equatable {
  final RobotPose? pose;
  final RobotJoints? joints;
  final int userFrame;
  final int toolNumber;
  final String coordSystem;
  final bool isLoading;
  final String? error;

  const RobotControlState({
    this.pose,
    this.joints,
    this.userFrame = 0,
    this.toolNumber = 1,
    this.coordSystem = 'WORLD',
    this.isLoading = false,
    this.error,
  });

  const RobotControlState.initial()
      : pose = null,
        joints = null,
        userFrame = 0,
        toolNumber = 1,
        coordSystem = 'WORLD',
        isLoading = false,
        error = null;

  const RobotControlState.loading()
      : pose = null,
        joints = null,
        userFrame = 0,
        toolNumber = 1,
        coordSystem = 'WORLD',
        isLoading = true,
        error = null;

  const RobotControlState.error(String this.error)
      : pose = null,
        joints = null,
        userFrame = 0,
        toolNumber = 1,
        coordSystem = 'WORLD',
        isLoading = false;

  RobotControlState copyWith({
    RobotPose? pose,
    RobotJoints? joints,
    int? userFrame,
    int? toolNumber,
    String? coordSystem,
    bool? isLoading,
    String? error,
  }) {
    return RobotControlState(
      pose: pose ?? this.pose,
      joints: joints ?? this.joints,
      userFrame: userFrame ?? this.userFrame,
      toolNumber: toolNumber ?? this.toolNumber,
      coordSystem: coordSystem ?? this.coordSystem,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        pose,
        joints,
        userFrame,
        toolNumber,
        coordSystem,
        isLoading,
        error,
      ];
}

