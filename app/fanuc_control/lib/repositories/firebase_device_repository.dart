import '../models/device.dart';

/// Abstract device repository interface for Firebase operations
/// TODO: Implement Firebase Firestore integration
abstract class DeviceRepository {
  /// Get all devices for a user (where user is in members list)
  Future<List<Device>> getDevicesForUser(String userId);

  /// Get device by ID
  Future<Device?> getDevice(String deviceId);

  /// Create new device
  Future<Device> createDevice(Device device);

  /// Update device
  Future<Device> updateDevice(Device device);

  /// Delete device
  Future<void> deleteDevice(String deviceId);

  /// Stream device online status from RTDB
  Stream<bool> watchDeviceOnlineStatus(String deviceId);
}

