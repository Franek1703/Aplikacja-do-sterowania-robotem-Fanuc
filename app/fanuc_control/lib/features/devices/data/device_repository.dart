import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/repositories/firestore_repository.dart';
import '../../../config/repositories/realtime_database_repository.dart';
import '../../../models/device.dart';

/// Repository for device operations
class DeviceRepository {
  final FirestoreRepository _firestore;
  final RealtimeDatabaseRepository _rtdb;

  DeviceRepository({
    FirestoreRepository? firestore,
    RealtimeDatabaseRepository? rtdb,
  })  : _firestore = firestore ?? FirestoreRepository(),
        _rtdb = rtdb ?? RealtimeDatabaseRepository();

  /// Get all devices where user is a member
  Future<List<Device>> getDevicesForUser(String userId) async {
    try {
      final snapshot = await _firestore.queryCollection(
        'devices',
        queryBuilder: (query) => query.where('members', arrayContains: userId),
      );

      final devices = <Device>[];
      for (var doc in snapshot.docs) {
        final device = _deviceFromFirestore(doc);
        if (device != null) {
          // Get online status from RTDB
          final onlineStatus = await _getDeviceOnlineStatus(device.deviceId);
          devices.add(device.copyWith(online: onlineStatus));
        }
      }

      return devices;
    } catch (e) {
      throw Exception('Failed to load devices: $e');
    }
  }

  /// Stream devices for a user
  Stream<List<Device>> streamDevicesForUser(String userId) {
    return _firestore.streamCollectionQuery(
      'devices',
      queryBuilder: (query) => query.where('members', arrayContains: userId),
    ).asyncMap((snapshot) async {
      final devices = <Device>[];
      for (var doc in snapshot.docs) {
        final device = _deviceFromFirestore(doc);
        if (device != null) {
          // Get online status from RTDB
          final onlineStatus = await _getDeviceOnlineStatus(device.deviceId);
          devices.add(device.copyWith(online: onlineStatus));
        }
      }
      return devices;
    });
  }

  /// Get a single device by ID
  Future<Device?> getDevice(String deviceId) async {
    try {
      final doc = await _firestore.getDocument('devices/$deviceId');
      if (!doc.exists) return null;

      final device = _deviceFromFirestore(doc);
      if (device != null) {
        final onlineStatus = await _getDeviceOnlineStatus(deviceId);
        return device.copyWith(online: onlineStatus);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load device: $e');
    }
  }

  /// Stream a single device
  Stream<Device?> streamDevice(String deviceId) {
    return _firestore.streamDocument('devices/$deviceId').asyncMap((doc) async {
      if (!doc.exists) return null;

      final device = _deviceFromFirestore(doc);
      if (device != null) {
        final onlineStatus = await _getDeviceOnlineStatus(deviceId);
        return device.copyWith(online: onlineStatus);
      }
      return null;
    });
  }

  /// Get device online status from RTDB
  Future<bool> _getDeviceOnlineStatus(String deviceId) async {
    try {
      final snapshot = await _rtdb.getValue('devices/$deviceId/status/online');
      return snapshot.value as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stream device online status from RTDB
  Stream<bool> streamDeviceOnlineStatus(String deviceId) {
    return _rtdb.streamValue('devices/$deviceId/status/online').map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Add a user as a member to a device
  /// Updates the device's members array in Firestore
  Future<void> addMemberToDevice(String deviceId, String userId) async {
    try {
      // Check if device exists
      final deviceDoc = await _firestore.getDocument('devices/$deviceId');
      if (!deviceDoc.exists) {
        throw Exception('Device not found');
      }

      // Get current members list
      final data = deviceDoc.data();
      if (data == null) {
        throw Exception('Device data not found');
      }

      final currentMembers = (data['members'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Check if user is already a member
      if (currentMembers.contains(userId)) {
        throw Exception('User is already a member of this device');
      }

      // Add user to members array
      currentMembers.add(userId);

      // Update device document
      await _firestore.updateDocument(
        'devices/$deviceId',
        {'members': currentMembers},
      );
    } catch (e) {
      throw Exception('Failed to add member to device: $e');
    }
  }

  /// Convert Firestore document to Device model
  Device? _deviceFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
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

      return Device(
        deviceId: doc.id,
        name: data['name'] as String? ?? 'Unknown Device',
        description: data['description'] as String?,
        ownerUid: data['ownerUid'] as String?,
        members: (data['members'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        online: data['online'] as bool? ?? false,
        lastSeen: parseTimestamp(data['lastSeen'] ?? data['lastTimeSeen']),
        robotCount: data['robotCount'] as int? ?? 0,
        createdAt: parseTimestamp(data['createdAt']),
        imageUrl: data['imageUrl'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}

