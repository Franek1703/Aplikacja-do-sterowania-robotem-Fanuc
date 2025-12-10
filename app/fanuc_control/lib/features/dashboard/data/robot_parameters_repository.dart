import '../../../config/repositories/realtime_database_repository.dart';
import '../../../config/repositories/firestore_repository.dart';
import '../../../models/robot_parameter.dart';

/// Repository for robot parameters
/// Note: Parameters might be stored in RTDB or could be static configuration
class RobotParametersRepository {
  final RealtimeDatabaseRepository _rtdb;
  final FirestoreRepository _firestore;

  RobotParametersRepository({
    RealtimeDatabaseRepository? rtdb,
    FirestoreRepository? firestore,
  })  : _rtdb = rtdb ?? RealtimeDatabaseRepository(),
        _firestore = firestore ?? FirestoreRepository();

  /// Get robot parameters from Firestore definitions and RTDB current values
  /// 1. Always add FTP Password (ID '1') from robot document
  /// 2. Load other parameter definitions from Firestore /robots/{robotId}/parameters
  /// 3. Load current values from RTDB /devices/{deviceId}/robots/{robotId}/parameters
  /// 4. Merge them together
  Future<List<RobotParameter>> getParameters(
    String deviceId,
    String robotId,
  ) async {
    try {
      final parameters = <RobotParameter>[];

      // 1. Get FTP password from Firestore robot document (always included, ID '1')
      String? ftpPassword;
      try {
        final robotDoc = await _firestore.getDocument('robots/$robotId');
        if (robotDoc.exists && robotDoc.data() != null) {
          ftpPassword = robotDoc.data()!['ftpPassword'] as String?;
        }
      } catch (e) {
        // Robot document might not have ftpPassword yet
      }

      // Always add FTP Password parameter (ID '1')
      parameters.add(RobotParameter(
        id: '1',
        name: 'FTP Password',
        value: ftpPassword ?? '',
        type: ParameterType.string,
        category: 'Network',
        isLocked: false,
        description: 'FTP access password for robot file system',
      ));

      // 2. Get current parameter values from RTDB
      Map<String, dynamic> rtdbValues = {};
      try {
        final rtdbSnapshot = await _rtdb.getValue(
          'devices/$deviceId/robots/$robotId/parameters',
        );
        if (rtdbSnapshot.value != null && rtdbSnapshot.value is Map) {
          rtdbValues = Map<String, dynamic>.from(rtdbSnapshot.value as Map);
        }
      } catch (e) {
        // RTDB values might not exist yet, that's okay
      }

      // 3. Get parameter definitions from Firestore (excluding ID '1' since we already added it)
      try {
        final parametersSnapshot = await _firestore.getCollection(
          'robots/$robotId/parameters',
        );

        // 4. Build parameters list from Firestore definitions
        for (var doc in parametersSnapshot.docs) {
          final parameterId = doc.id;
          
          // Skip ID '1' since we already added FTP Password
          if (parameterId == '1') continue;

          final data = doc.data();
          if (data.isEmpty) continue;

          dynamic defaultValue = data['defaultValue'];
          final type = ParameterType.fromString(data['type'] as String? ?? 'string');

          // Convert default value to correct type
          if (type == ParameterType.number) {
            defaultValue = (defaultValue is num) ? defaultValue.toDouble() : 0.0;
          } else if (type == ParameterType.boolean) {
            defaultValue = defaultValue is bool ? defaultValue : false;
          } else {
            defaultValue = defaultValue?.toString() ?? '';
          }

          // Get current value from RTDB, or use default
          dynamic currentValue = defaultValue;
          if (rtdbValues.containsKey(parameterId)) {
            final rtdbParam = rtdbValues[parameterId];
            if (rtdbParam is Map && rtdbParam.containsKey('value')) {
              currentValue = rtdbParam['value'];
            } else if (rtdbParam != null) {
              currentValue = rtdbParam;
            }
          }

          // Convert current value to correct type
          if (type == ParameterType.number) {
            if (currentValue is num) {
              currentValue = currentValue.toDouble();
            } else if (currentValue is String) {
              currentValue = double.tryParse(currentValue) ?? defaultValue;
            } else {
              currentValue = defaultValue;
            }
          } else if (type == ParameterType.boolean) {
            if (currentValue is bool) {
              currentValue = currentValue;
            } else if (currentValue is String) {
              currentValue = currentValue.toLowerCase() == 'true';
            } else {
              currentValue = defaultValue;
            }
          } else {
            currentValue = currentValue?.toString() ?? defaultValue.toString();
          }

          parameters.add(RobotParameter(
            id: parameterId,
            name: data['name'] as String? ?? 'Unknown',
            value: currentValue,
            type: type,
            unit: data['unit'] as String?,
            category: data['category'] as String? ?? 'General',
            isLocked: data['isLocked'] as bool? ?? false,
            description: data['description'] as String?,
          ));
        }
      } catch (e) {
        // Parameters subcollection might not exist yet, that's okay
        // We still have FTP Password
      }

      return parameters;
    } catch (e) {
      throw Exception('Failed to load parameters: $e');
    }
  }

  /// Update a parameter value (send command to robot)
  /// Special case: FTP Password (parameterId='1') is stored in Firestore robot document
  Future<void> updateParameter(
    String deviceId,
    String robotId,
    String userId,
    String parameterId,
    dynamic value,
  ) async {
    // Special handling for FTP Password - update Firestore robot document
    if (parameterId == '1') {
      await _firestore.updateDocument(
        'robots/$robotId',
        {'ftpPassword': value.toString()},
      );
      return;
    }

    // For other parameters, send command to robot and update RTDB
    final commandId = DateTime.now().millisecondsSinceEpoch.toString();
    final commandPath =
        'devices/$deviceId/robots/$robotId/commands/$commandId';

    await _rtdb.setValue(commandPath, {
      'type': 'updateParameter',
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'createdBy': userId,
      'payload': {
        'parameterId': parameterId,
        'value': value,
      },
      'result': {
        'code': null,
        'message': null,
        'data': null,
        'completedAt': null,
      },
    });

    // Also update RTDB parameter value
    await _rtdb.setValue(
      'devices/$deviceId/robots/$robotId/parameters/$parameterId',
      {
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedBy': userId,
      },
    );
  }
}

