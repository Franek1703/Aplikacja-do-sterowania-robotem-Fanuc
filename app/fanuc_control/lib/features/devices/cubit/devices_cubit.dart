import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/device.dart';

part 'devices_state.dart';

/// Devices cubit managing device list with fake data
class DevicesCubit extends Cubit<DevicesState> {
  DevicesCubit() : super(const DevicesState.initial()) {
    _loadDevices();
  }

  void _loadDevices() {
    // Fake devices data matching the TypeScript mock
    final devices = [
      Device(
        deviceId: '1',
        name: 'Production Line A',
        imageUrl: 'https://images.unsplash.com/photo-1716191299980-a6e8827ba10b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmR1c3RyaWFsJTIwcm9ib3QlMjBmYWN0b3J5fGVufDF8fHx8MTc2MjE1Njc2NXww&ixlib=rb-4.1.0&q=80&w=1080',
        online: true,
        lastSeen: DateTime.now(),
        robotCount: 4,
        members: ['uid123'],
      ),
      Device(
        deviceId: '2',
        name: 'Assembly Station 3',
        imageUrl: 'https://images.unsplash.com/photo-1715059250871-08786b8a884a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyb2JvdGljJTIwYXJtJTIwbWFudWZhY3R1cmluZ3xlbnwxfHx8fDE3NjIxNTY3NjV8MA&ixlib=rb-4.1.0&q=80&w=1080',
        online: true,
        lastSeen: DateTime.now(),
        robotCount: 2,
        members: ['uid123'],
      ),
      Device(
        deviceId: '3',
        name: 'Welding Cell B2',
        imageUrl: 'https://images.unsplash.com/photo-1647427060118-4911c9821b82?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmYWN0b3J5JTIwYXV0b21hdGlvbnxlbnwxfHx8fDE3NjIxNjI1MjZ8MA&ixlib=rb-4.1.0&q=80&w=1080',
        online: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
        robotCount: 1,
        members: ['uid123'],
      ),
      Device(
        deviceId: '4',
        name: 'Packaging Unit 5',
        imageUrl: 'https://images.unsplash.com/photo-1716191299980-a6e8827ba10b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmR1c3RyaWFsJTIwcm9ib3QlMjBmYWN0b3J5fGVufDF8fHx8MTc2MjE1Njc2NXww&ixlib=rb-4.1.0&q=80&w=1080',
        online: true,
        lastSeen: DateTime.now(),
        robotCount: 3,
        members: ['uid123'],
      ),
    ];

    emit(DevicesState.loaded(devices));
  }

  Future<void> refreshDevices() async {
    emit(const DevicesState.loading());
    await Future.delayed(const Duration(milliseconds: 500));
    _loadDevices();
  }
}

