import '../models/robot.dart';
import '../models/robot_pose.dart';
import '../models/alarm.dart';

/// Abstract robot repository interface for Firebase operations
/// TODO: Implement Firebase Firestore and RTDB integration
abstract class RobotRepository {
  /// Get all robots for a device
  Future<List<Robot>> getRobotsForDevice(String deviceId);

  /// Get robot by ID
  Future<Robot?> getRobot(String robotId);

  /// Create new robot
  Future<Robot> createRobot(Robot robot);

  /// Update robot
  Future<Robot> updateRobot(Robot robot);

  /// Delete robot
  Future<void> deleteRobot(String robotId);

  /// Stream robot pose from RTDB
  Stream<RobotPose?> watchRobotPose(String deviceId, String robotId);

  /// Stream robot joints from RTDB
  Stream<RobotJoints?> watchRobotJoints(String deviceId, String robotId);

  /// Stream active alarms from RTDB
  Stream<List<Alarm>> watchActiveAlarms(String deviceId, String robotId);

  /// Send command to robot via RTDB
  Future<void> sendCommand(String deviceId, String robotId, Map<String, dynamic> command);
}

