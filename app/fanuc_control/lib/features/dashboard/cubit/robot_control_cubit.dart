import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/robot_pose.dart';
import '../data/robot_status_repository.dart';

part 'robot_control_state.dart';

/// Cubit for robot control (pose, joints, config)
class RobotControlCubit extends Cubit<RobotControlState> {
  final RobotStatusRepository _statusRepository;
  final String deviceId;
  final String robotId;
  final String userId;

  StreamSubscription<RobotPose?>? _poseSubscription;
  StreamSubscription<RobotJoints?>? _jointsSubscription;
  StreamSubscription<Map<String, dynamic>>? _configSubscription;

  RobotControlCubit({
    required this.deviceId,
    required this.robotId,
    required this.userId,
    RobotStatusRepository? statusRepository,
  })  : _statusRepository = statusRepository ?? RobotStatusRepository(),
        super(const RobotControlState.initial()) {
    _loadData();
  }

  void _loadData() {
    emit(const RobotControlState.loading());

    _poseSubscription?.cancel();
    _jointsSubscription?.cancel();
    _configSubscription?.cancel();

    bool hasPose = false;
    bool hasJoints = false;
    bool hasConfig = false;

    void checkAndEmitLoaded() {
      if (hasPose && hasJoints && hasConfig && state.isLoading) {
        emit(state.copyWith(isLoading: false));
      }
    }

    _poseSubscription = _statusRepository
        .streamPose(deviceId, robotId)
        .listen(
          (pose) {
            print('pose: $pose');
            if (pose != null) {
              hasPose = true;
              emit(state.copyWith(pose: pose, isLoading: !hasJoints || !hasConfig));
              checkAndEmitLoaded();
            }
          },
          onError: (error) {
            emit(RobotControlState.error(error.toString()));
          },
        );

    _jointsSubscription = _statusRepository
        .streamJoints(deviceId, robotId)
        .listen(
          (joints) {
            if (joints != null) {
              hasJoints = true;
              emit(state.copyWith(joints: joints, isLoading: !hasPose || !hasConfig));
              checkAndEmitLoaded();
            }
          },
          onError: (error) {
            emit(RobotControlState.error(error.toString()));
          },
        );

    _configSubscription = _statusRepository
        .streamConfig(deviceId, robotId)
        .listen(
          (config) {
            hasConfig = true;
            emit(state.copyWith(
              userFrame: config['userFrame'] as int? ?? 0,
              toolNumber: config['toolNumber'] as int? ?? 1,
              activeProgram: config['activeProgram'] as String? ?? '',
              isLoading: !hasPose || !hasJoints,
            ));
            checkAndEmitLoaded();
          },
          onError: (error) {
            emit(RobotControlState.error(error.toString()));
          },
        );
  }

  /// Send move command
  Future<void> sendMoveCommand(Map<String, dynamic> payload) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'move',
        payload,
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Update config values
  Future<void> updateConfig({
    int? userFrame,
    int? toolNumber,
    String? activeProgram,
  }) async {
    // This would typically send a command to update config
    // For now, we just update local state
    emit(state.copyWith(
      userFrame: userFrame ?? state.userFrame,
      toolNumber: toolNumber ?? state.toolNumber,
      activeProgram: activeProgram ?? state.activeProgram,
    ));
  }

  @override
  Future<void> close() {
    _poseSubscription?.cancel();
    _jointsSubscription?.cancel();
    _configSubscription?.cancel();
    return super.close();
  }
}

