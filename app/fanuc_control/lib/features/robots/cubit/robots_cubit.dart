import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/robot.dart';
import '../data/robot_repository.dart';

part 'robots_state.dart';

/// Robots cubit managing robot list for a device
class RobotsCubit extends Cubit<RobotsState> {
  final RobotRepository _robotRepository;
  StreamSubscription<List<Robot>>? _robotsSubscription;

  RobotsCubit({
    required String deviceId,
    RobotRepository? robotRepository,
  })  : _robotRepository = robotRepository ?? RobotRepository(),
        super(const RobotsState.initial()) {
    _loadRobots(deviceId);
  }

  void _loadRobots(String deviceId) {
    emit(const RobotsState.loading());

    _robotsSubscription?.cancel();
    _robotsSubscription = _robotRepository
        .streamRobotsForDevice(deviceId)
        .listen(
          (robots) {
            emit(RobotsState.loaded(robots));
          },
          onError: (error) {
            emit(RobotsState.error(error.toString()));
          },
        );
  }

  Future<void> refreshRobots(String deviceId) async {
    emit(const RobotsState.loading());
    try {
      final robots = await _robotRepository.getRobotsForDevice(deviceId);
      emit(RobotsState.loaded(robots));
    } catch (e) {
      emit(RobotsState.error(e.toString()));
    }
  }

  /// Set selected robot for the device
  Future<void> setSelectedRobot(String deviceId, String? robotId) async {
    try {
      await _robotRepository.setSelectedRobot(deviceId, robotId);
    } catch (e) {
      emit(RobotsState.error(e.toString()));
    }
  }

  /// Create a new robot
  Future<void> createRobot({
    required String deviceId,
    required String name,
    required String ipAddress,
    required String ftpUser,
    required String ftpPassword,
    String? controller,
    String? model,
    int tcpPort = 18735,
  }) async {
    try {
      await _robotRepository.createRobot(
        deviceId: deviceId,
        name: name,
        ipAddress: ipAddress,
        ftpUser: ftpUser,
        ftpPassword: ftpPassword,
        controller: controller,
        model: model,
        tcpPort: tcpPort,
      );
      // Refresh robots list to show the newly created robot
      await refreshRobots(deviceId);
    } catch (e) {
      emit(RobotsState.error(e.toString()));
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _robotsSubscription?.cancel();
    return super.close();
  }
}

