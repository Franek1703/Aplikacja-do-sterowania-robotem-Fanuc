import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/device.dart';
import '../data/device_repository.dart';

part 'devices_state.dart';

/// Devices cubit managing device list
class DevicesCubit extends Cubit<DevicesState> {
  final DeviceRepository _deviceRepository;
  StreamSubscription<List<Device>>? _devicesSubscription;

  DevicesCubit({DeviceRepository? deviceRepository, required String userId})
      : _deviceRepository = deviceRepository ?? DeviceRepository(),
        super(const DevicesState.initial()) {
    _loadDevices(userId);
  }

  void _loadDevices(String userId) {
    emit(const DevicesState.loading());

    _devicesSubscription?.cancel();
    _devicesSubscription = _deviceRepository
        .streamDevicesForUser(userId)
        .listen(
          (devices) {
            emit(DevicesState.loaded(devices));
          },
          onError: (error) {
            emit(DevicesState.error(error.toString()));
          },
        );
  }

  Future<void> refreshDevices(String userId) async {
    emit(const DevicesState.loading());
    try {
      final devices = await _deviceRepository.getDevicesForUser(userId);
      emit(DevicesState.loaded(devices));
    } catch (e) {
      emit(DevicesState.error(e.toString()));
    }
  }

  /// Connect to a device by adding current user as a member
  Future<void> connectToDevice(String deviceId, String userId) async {
    try {
      await _deviceRepository.addMemberToDevice(deviceId, userId);
      // Refresh devices list to show the newly connected device
      await refreshDevices(userId);
    } catch (e) {
      emit(DevicesState.error(e.toString()));
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    return super.close();
  }
}

