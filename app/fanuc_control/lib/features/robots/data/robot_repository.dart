import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/repositories/firestore_repository.dart';
import '../../../config/repositories/realtime_database_repository.dart';
import '../../../models/robot.dart';

/// Repository for robot operations
class RobotRepository {
  final FirestoreRepository _firestore;
  final RealtimeDatabaseRepository _rtdb;

  RobotRepository({
    FirestoreRepository? firestore,
    RealtimeDatabaseRepository? rtdb,
  })  : _firestore = firestore ?? FirestoreRepository(),
        _rtdb = rtdb ?? RealtimeDatabaseRepository();

  /// Get all robots for a device
  Future<List<Robot>> getRobotsForDevice(String deviceId) async {
    try {
      final snapshot = await _firestore.queryCollection(
        'robots',
        queryBuilder: (query) => query.where('deviceId', isEqualTo: deviceId),
      );

      final robots = <Robot>[];
      for (var doc in snapshot.docs) {
        final robot = _robotFromFirestore(doc);
        if (robot != null) {
          // Get online status from RTDB
          final onlineStatus = await _getRobotOnlineStatus(deviceId, robot.robotId);
          robots.add(robot.copyWith(isOnline: onlineStatus));
        }
      }

      return robots;
    } catch (e) {
      throw Exception('Failed to load robots: $e');
    }
  }

  /// Stream robots for a device
  Stream<List<Robot>> streamRobotsForDevice(String deviceId) {
    return _firestore.streamCollectionQuery(
      'robots',
      queryBuilder: (query) => query.where('deviceId', isEqualTo: deviceId),
    ).asyncMap((snapshot) async {
      final robots = <Robot>[];
      for (var doc in snapshot.docs) {
        final robot = _robotFromFirestore(doc);
        if (robot != null) {
          final onlineStatus = await _getRobotOnlineStatus(deviceId, robot.robotId);
          robots.add(robot.copyWith(isOnline: onlineStatus));
        }
      }
      return robots;
    });
  }

  /// Get a single robot by ID
  Future<Robot?> getRobot(String robotId) async {
    try {
      final doc = await _firestore.getDocument('robots/$robotId');
      if (!doc.exists) return null;

      final robot = _robotFromFirestore(doc);
      if (robot != null) {
        final onlineStatus = await _getRobotOnlineStatus(robot.deviceId, robotId);
        return robot.copyWith(isOnline: onlineStatus);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load robot: $e');
    }
  }

  /// Stream a single robot
  Stream<Robot?> streamRobot(String robotId) {
    return _firestore.streamDocument('robots/$robotId').asyncMap((doc) async {
      if (!doc.exists) return null;

      final robot = _robotFromFirestore(doc);
      if (robot != null) {
        final onlineStatus = await _getRobotOnlineStatus(robot.deviceId, robotId);
        return robot.copyWith(isOnline: onlineStatus);
      }
      return null;
    });
  }

  /// Set selected robot for a device (in RTDB)
  Future<void> setSelectedRobot(String deviceId, String? robotId) async {
    await _rtdb.setValue('devices/$deviceId/selectedRobotId', robotId);
  }

  /// Get selected robot for a device (from RTDB)
  Future<String?> getSelectedRobot(String deviceId) async {
    try {
      final snapshot = await _rtdb.getValue('devices/$deviceId/selectedRobotId');
      return snapshot.value as String?;
    } catch (e) {
      return null;
    }
  }

  /// Stream selected robot for a device
  Stream<String?> streamSelectedRobot(String deviceId) {
    return _rtdb.streamValue('devices/$deviceId/selectedRobotId').map((event) {
      return event.snapshot.value as String?;
    });
  }

  /// Get robot online status from RTDB
  Future<bool> _getRobotOnlineStatus(String deviceId, String robotId) async {
    try {
      final snapshot = await _rtdb.getValue(
        'devices/$deviceId/robots/$robotId/status/online',
      );
      return snapshot.value as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stream robot online status from RTDB
  Stream<bool> streamRobotOnlineStatus(String deviceId, String robotId) {
    return _rtdb
        .streamValue('devices/$deviceId/robots/$robotId/status/online')
        .map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Convert Firestore document to Robot model
  Robot? _robotFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      if (data == null) return null;

      DateTime? parseTimestamp(dynamic value) {
        if (value == null) return null;
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        if (value is String) return DateTime.tryParse(value);
        return null;
      }

      return Robot(
        robotId: doc.id,
        deviceId: data['deviceId'] as String? ?? '',
        name: data['name'] as String? ?? 'Unknown Robot',
        series: data['series'] as String?,
        model: data['model'] as String?,
        controller: data['controller'] as String?,
        ipAddress: data['ipAddress'] as String? ?? '',
        tcpPort: (data['tcpPort'] as num?)?.toInt() ?? 18735,
        ftpUser: data['ftpUser'] as String?,
        ftpPassword: data['ftpPassword'] as String?,
        simulation: data['simulation'] as bool? ?? false,
        isOnline: data['isOnline'] as bool? ?? false,
        lastSeen: parseTimestamp(data['lastSeen'] ?? data['lastTimeSeen']),
        createdAt: parseTimestamp(data['createdAt']),
      );
    } catch (e) {
      return null;
    }
  }
}

