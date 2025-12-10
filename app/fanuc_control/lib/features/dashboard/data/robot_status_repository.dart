import '../../../config/repositories/realtime_database_repository.dart';
import '../../../models/robot_pose.dart';

/// Repository for robot status, pose, and joints from RTDB
class RobotStatusRepository {
  final RealtimeDatabaseRepository _rtdb;

  RobotStatusRepository({RealtimeDatabaseRepository? rtdb})
      : _rtdb = rtdb ?? RealtimeDatabaseRepository();

  /// Stream robot pose
  Stream<RobotPose?> streamPose(String deviceId, String robotId) {
    return _rtdb
        .streamValue('devices/$deviceId/robots/$robotId/currentPose')
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      return RobotPose.fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Stream robot joints
  Stream<RobotJoints?> streamJoints(String deviceId, String robotId) {
    return _rtdb
        .streamValue('devices/$deviceId/robots/$robotId/currentJoints')
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      return RobotJoints.fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Stream robot status (mode, eStop, alarmCount)
  Stream<Map<String, dynamic>> streamStatus(String deviceId, String robotId) {
    return _rtdb
        .streamValue('devices/$deviceId/robots/$robotId/status')
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        return {
          'mode': 'UNKNOWN',
          'eStop': false,
          'alarmCount': 0,
        };
      }
      return Map<String, dynamic>.from(data);
    });
  }

  /// Stream robot config (userFrame, toolNumber, coordSystem)
  Stream<Map<String, dynamic>> streamConfig(String deviceId, String robotId) {
    return _rtdb
        .streamValue('devices/$deviceId/robots/$robotId/config')
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        return {
          'userFrame': 0,
          'toolNumber': 1,
          'coordSystem': 'WORLD',
        };
      }
      return Map<String, dynamic>.from(data);
    });
  }

  /// Send a robot command
  Future<String> sendCommand(
    String deviceId,
    String robotId,
    String userId,
    String type,
    Map<String, dynamic> payload,
  ) async {
    final commandId = DateTime.now().millisecondsSinceEpoch.toString();
    final commandPath =
        'devices/$deviceId/robots/$robotId/commands/$commandId';

    await _rtdb.setValue(commandPath, {
      'type': type,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'createdBy': userId,
      'payload': payload,
      'result': {
        'code': null,
        'message': null,
        'data': null,
        'completedAt': null,
      },
    });

    return commandId;
  }

  /// Stream command result
  Stream<Map<String, dynamic>?> streamCommandResult(
    String deviceId,
    String robotId,
    String commandId,
  ) {
    return _rtdb
        .streamValue(
            'devices/$deviceId/robots/$robotId/commands/$commandId')
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      return Map<String, dynamic>.from(data);
    });
  }
}

