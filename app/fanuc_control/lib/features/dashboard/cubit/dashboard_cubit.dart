import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/robot.dart';
import '../../../models/robot_pose.dart';
import '../../../models/robot_parameter.dart';
import '../../../models/alarm.dart';
import '../../../models/ftp_file.dart';

part 'dashboard_state.dart';

/// Dashboard cubit managing robot dashboard state with fake data
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required String robotId, required String deviceId})
      : super(DashboardState.initial()) {
    _loadDashboardData(robotId, deviceId);
  }

  void _loadDashboardData(String robotId, String deviceId) {
    // Fake robot data
    final robot = Robot(
      robotId: robotId,
      deviceId: deviceId,
      name: 'FANUC R-2000iC/165F',
      model: 'R-2000iC Series',
      ipAddress: '192.168.0.20',
      isOnline: true,
    );

    // Fake pose data
    final pose = RobotPose(
      x: 450.25,
      y: -125.80,
      z: 320.15,
      w: 180.0,
      p: 0.0,
      r: 90.0,
      updatedAt: DateTime.now(),
    );

    // Fake joints data
    final joints = RobotJoints(
      j1: 45.5,
      j2: -30.2,
      j3: 60.8,
      j4: 0.0,
      j5: 45.0,
      j6: 0.0,
      updatedAt: DateTime.now(),
    );

    // Fake alarms data
    final alarms = [
      Alarm(
        alarmId: '1',
        robotId: robotId,
        deviceId: deviceId,
        code: 'SRVO-050',
        severity: AlarmSeverity.error,
        title: 'Collision detected on J3',
        description: 'Excessive force detected during motion. Check mechanical components.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Alarm(
        alarmId: '2',
        robotId: robotId,
        deviceId: deviceId,
        code: 'WARN-102',
        severity: AlarmSeverity.warning,
        title: 'Low battery voltage',
        description: 'Battery voltage below threshold. Replace battery soon.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Alarm(
        alarmId: '3',
        robotId: robotId,
        deviceId: deviceId,
        code: 'MOTN-023',
        severity: AlarmSeverity.warning,
        title: 'Approaching joint limit on J5',
        description: 'Joint 5 is approaching software limit. Adjust program path.',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Alarm(
        alarmId: '4',
        robotId: robotId,
        deviceId: deviceId,
        code: 'INFO-001',
        severity: AlarmSeverity.info,
        title: 'Maintenance due in 48 hours',
        description: 'Scheduled maintenance recommended based on runtime hours.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    // Fake parameters data
    final parameters = [
      RobotParameter(
        id: '1',
        name: 'Override Speed',
        value: 100,
        type: ParameterType.number,
        unit: '%',
        category: 'Motion',
        isLocked: false,
        description: 'Global speed override percentage',
      ),
      RobotParameter(
        id: '2',
        name: 'Joint Speed Limit',
        value: 250,
        type: ParameterType.number,
        unit: 'deg/sec',
        category: 'Motion',
        isLocked: false,
        description: 'Maximum angular velocity for joints',
      ),
      RobotParameter(
        id: '3',
        name: 'Collision Detection',
        value: true,
        type: ParameterType.boolean,
        category: 'Safety',
        isLocked: true,
        description: 'Enable/disable collision detection system',
      ),
      RobotParameter(
        id: '4',
        name: 'Emergency Stop Enabled',
        value: true,
        type: ParameterType.boolean,
        category: 'Safety',
        isLocked: true,
        description: 'Emergency stop circuit status',
      ),
      RobotParameter(
        id: '5',
        name: 'Payload Weight',
        value: 25.5,
        type: ParameterType.number,
        unit: 'kg',
        category: 'Configuration',
        isLocked: false,
        description: 'Current tool and payload weight',
      ),
      RobotParameter(
        id: '6',
        name: 'TCP Offset X',
        value: 0.0,
        type: ParameterType.number,
        unit: 'mm',
        category: 'Configuration',
        isLocked: false,
        description: 'Tool center point X offset',
      ),
      RobotParameter(
        id: '7',
        name: 'Auto Backup',
        value: true,
        type: ParameterType.boolean,
        category: 'System',
        isLocked: false,
        description: 'Automatic backup of programs',
      ),
      RobotParameter(
        id: '8',
        name: 'Controller IP',
        value: '192.168.1.100',
        type: ParameterType.string,
        category: 'Network',
        isLocked: false,
        description: 'Controller network IP address',
      ),
    ];

    // Fake FTP files data
    final ftpFiles = {
      '/': [
        FtpFile(name: 'Programs', type: FtpFileType.folder),
        FtpFile(name: 'Backups', type: FtpFileType.folder),
        FtpFile(name: 'Logs', type: FtpFileType.folder),
        FtpFile(
          name: 'config.txt',
          type: FtpFileType.file,
          size: '2.4 KB',
          modified: '2025-11-01',
        ),
      ],
      '/Programs': [
        FtpFile(
          name: 'MAIN001.TP',
          type: FtpFileType.file,
          size: '12.8 KB',
          modified: '2025-11-02',
          content: '1: J P[1] 50% FINE\n2: L P[2] 100mm/sec FINE\n3: CALL PICKUP\n4: J P[3] 75% CNT100\n5: END',
        ),
        FtpFile(
          name: 'PICKUP.TP',
          type: FtpFileType.file,
          size: '8.2 KB',
          modified: '2025-10-28',
          content: '1: L P[10] 50mm/sec FINE\n2: WAIT DI[1]=ON\n3: DO[2]=ON\n4: WAIT .5(sec)\n5: L P[11] 100mm/sec CNT50\n6: END',
        ),
        FtpFile(
          name: 'ASSEMBLY.TP',
          type: FtpFileType.file,
          size: '15.6 KB',
          modified: '2025-10-30',
          content: '1: UTOOL_NUM=2\n2: UFRAME_NUM=1\n3: J P[20] 100% FINE\n4: L P[21] 75mm/sec CNT100\n5: ARC START[1]\n6: END',
        ),
      ],
      '/Backups': [
        FtpFile(
          name: 'backup_2025_11_01.dat',
          type: FtpFileType.file,
          size: '45.2 MB',
          modified: '2025-11-01',
        ),
        FtpFile(
          name: 'backup_2025_10_25.dat',
          type: FtpFileType.file,
          size: '44.8 MB',
          modified: '2025-10-25',
        ),
      ],
      '/Logs': [
        FtpFile(
          name: 'error.log',
          type: FtpFileType.file,
          size: '128 KB',
          modified: '2025-11-03',
        ),
        FtpFile(
          name: 'motion.log',
          type: FtpFileType.file,
          size: '256 KB',
          modified: '2025-11-03',
        ),
      ],
    };

    emit(DashboardState.loaded(
      robot: robot,
      pose: pose,
      joints: joints,
      alarms: alarms,
      parameters: parameters,
      ftpFiles: ftpFiles,
      userFrame: 0,
      toolNumber: 1,
      activeProgram: 'MAIN001',
    ));
  }

  void updatePose(RobotPose pose) {
    if (state.robot != null) {
      emit(state.copyWith(pose: pose));
    }
  }

  void updateJoints(RobotJoints joints) {
    if (state.robot != null) {
      emit(state.copyWith(joints: joints));
    }
  }

  void updateParameter(String parameterId, dynamic value) {
    if (state.robot != null) {
      final updatedParameters = state.parameters.map((p) {
        if (p.id == parameterId) {
          return p.copyWith(value: value);
        }
        return p;
      }).toList();
      emit(state.copyWith(parameters: updatedParameters));
    }
  }

  void clearAlarm(String alarmId) {
    if (state.robot != null) {
      final updatedAlarms = state.alarms
          .where((a) => a.alarmId != alarmId)
          .toList();
      emit(state.copyWith(alarms: updatedAlarms));
    }
  }

  void setUserFrame(int frame) {
    if (state.robot != null) {
      emit(state.copyWith(userFrame: frame));
    }
  }

  void setToolNumber(int tool) {
    if (state.robot != null) {
      emit(state.copyWith(toolNumber: tool));
    }
  }

  void setActiveProgram(String program) {
    if (state.robot != null) {
      emit(state.copyWith(activeProgram: program));
    }
  }
}

