import '../../../config/repositories/realtime_database_repository.dart';
import '../../../models/alarm.dart';

/// Repository for robot alarms from RTDB
class RobotAlarmsRepository {
  final RealtimeDatabaseRepository _rtdb;

  RobotAlarmsRepository({RealtimeDatabaseRepository? rtdb})
      : _rtdb = rtdb ?? RealtimeDatabaseRepository();

  /// Stream active alarms for a robot
  Stream<List<Alarm>> streamActiveAlarms(String deviceId, String robotId) {
    return _rtdb
        .streamValue('devices/$deviceId/robots/$robotId/alarms/active')
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <Alarm>[];

      final alarms = <Alarm>[];
      final alarmsMap = Map<String, dynamic>.from(data);

      alarmsMap.forEach((alarmId, alarmData) {
        if (alarmData is Map) {
          try {
            final alarmJson = Map<String, dynamic>.from(alarmData);
            alarmJson['alarmId'] = alarmId;
            alarmJson['robotId'] = robotId;
            alarmJson['deviceId'] = deviceId;
            alarms.add(Alarm.fromJson(alarmJson));
          } catch (e) {
            // Skip invalid alarm entries
          }
        }
      });

      return alarms;
    });
  }

  /// Get active alarms (one-time)
  Future<List<Alarm>> getActiveAlarms(String deviceId, String robotId) async {
    try {
      final snapshot =
          await _rtdb.getValue('devices/$deviceId/robots/$robotId/alarms/active');
      final data = snapshot.value;
      if (data == null || data is! Map) return <Alarm>[];

      final alarms = <Alarm>[];
      final alarmsMap = Map<String, dynamic>.from(data);

      alarmsMap.forEach((alarmId, alarmData) {
        if (alarmData is Map) {
          try {
            final alarmJson = Map<String, dynamic>.from(alarmData);
            alarmJson['alarmId'] = alarmId;
            alarmJson['robotId'] = robotId;
            alarmJson['deviceId'] = deviceId;
            alarms.add(Alarm.fromJson(alarmJson));
          } catch (e) {
            // Skip invalid alarm entries
          }
        }
      });

      return alarms;
    } catch (e) {
      return <Alarm>[];
    }
  }
}

