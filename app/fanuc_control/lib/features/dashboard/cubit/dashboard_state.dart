part of 'dashboard_cubit.dart';

/// Dashboard state
class DashboardState extends Equatable {
  final Robot? robot;
  final RobotPose? pose;
  final RobotJoints? joints;
  final List<Alarm> alarms;
  final List<RobotParameter> parameters;
  final Map<String, List<FtpFile>> ftpFiles;
  final int userFrame;
  final int toolNumber;
  final String activeProgram;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.robot,
    this.pose,
    this.joints,
    this.alarms = const [],
    this.parameters = const [],
    this.ftpFiles = const {},
    this.userFrame = 0,
    this.toolNumber = 1,
    this.activeProgram = 'MAIN001',
    this.isLoading = false,
    this.error,
  });

  const DashboardState.initial()
      : robot = null,
        pose = null,
        joints = null,
        alarms = const [],
        parameters = const [],
        ftpFiles = const {},
        userFrame = 0,
        toolNumber = 1,
        activeProgram = 'MAIN001',
        isLoading = false,
        error = null;

  const DashboardState.loading()
      : robot = null,
        pose = null,
        joints = null,
        alarms = const [],
        parameters = const [],
        ftpFiles = const {},
        userFrame = 0,
        toolNumber = 1,
        activeProgram = 'MAIN001',
        isLoading = true,
        error = null;

  const DashboardState.loaded({
    required Robot this.robot,
    required RobotPose this.pose,
    required RobotJoints this.joints,
    required List<Alarm> this.alarms,
    required List<RobotParameter> this.parameters,
    required Map<String, List<FtpFile>> this.ftpFiles,
    this.userFrame = 0,
    this.toolNumber = 1,
    this.activeProgram = 'MAIN001',
  })  : isLoading = false,
        error = null;

  const DashboardState.error(String this.error)
      : robot = null,
        pose = null,
        joints = null,
        alarms = const [],
        parameters = const [],
        ftpFiles = const {},
        userFrame = 0,
        toolNumber = 1,
        activeProgram = 'MAIN001',
        isLoading = false;

  DashboardState copyWith({
    Robot? robot,
    RobotPose? pose,
    RobotJoints? joints,
    List<Alarm>? alarms,
    List<RobotParameter>? parameters,
    Map<String, List<FtpFile>>? ftpFiles,
    int? userFrame,
    int? toolNumber,
    String? activeProgram,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      robot: robot ?? this.robot,
      pose: pose ?? this.pose,
      joints: joints ?? this.joints,
      alarms: alarms ?? this.alarms,
      parameters: parameters ?? this.parameters,
      ftpFiles: ftpFiles ?? this.ftpFiles,
      userFrame: userFrame ?? this.userFrame,
      toolNumber: toolNumber ?? this.toolNumber,
      activeProgram: activeProgram ?? this.activeProgram,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        robot,
        pose,
        joints,
        alarms,
        parameters,
        ftpFiles,
        userFrame,
        toolNumber,
        activeProgram,
        isLoading,
        error,
      ];
}

