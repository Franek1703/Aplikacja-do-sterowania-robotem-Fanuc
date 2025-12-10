import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/robot.dart';

part 'robots_state.dart';

/// Robots cubit managing robot list for a device with fake data
class RobotsCubit extends Cubit<RobotsState> {
  RobotsCubit({required String deviceId}) : super(const RobotsState.initial()) {
    _loadRobots(deviceId);
  }

  void _loadRobots(String deviceId) {
    // Fake robots data matching the TypeScript mock
    final robots = [
      Robot(
        robotId: '1',
        deviceId: deviceId,
        name: 'FANUC R-2000iC/165F',
        model: 'R-2000iC Series',
        series: 'R-2000iC Series',
        controller: 'R-30iB',
        ipAddress: '192.168.0.20',
        tcpPort: 18735,
        isOnline: true,
        lastSeen: DateTime.now(),
      ),
      Robot(
        robotId: '2',
        deviceId: deviceId,
        name: 'FANUC M-20iD/25',
        model: 'M-20iD Series',
        series: 'M-20iD Series',
        controller: 'R-30iB Plus',
        ipAddress: '192.168.0.21',
        tcpPort: 18735,
        isOnline: true,
        lastSeen: DateTime.now(),
      ),
      Robot(
        robotId: '3',
        deviceId: deviceId,
        name: 'FANUC LR Mate 200iD',
        model: 'LR Mate Series',
        series: 'LR Mate Series',
        controller: 'R-30iB Mini',
        ipAddress: '192.168.0.22',
        tcpPort: 18735,
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Robot(
        robotId: '4',
        deviceId: deviceId,
        name: 'FANUC ARC Mate 120iC',
        model: 'ARC Mate Series',
        series: 'ARC Mate Series',
        controller: 'R-30iB',
        ipAddress: '192.168.0.23',
        tcpPort: 18735,
        isOnline: true,
        lastSeen: DateTime.now(),
      ),
    ];

    emit(RobotsState.loaded(robots));
  }

  Future<void> refreshRobots(String deviceId) async {
    emit(const RobotsState.loading());
    await Future.delayed(const Duration(milliseconds: 500));
    _loadRobots(deviceId);
  }
}

