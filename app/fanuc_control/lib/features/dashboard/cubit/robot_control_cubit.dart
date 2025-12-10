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
              coordSystem: config['coordSystem'] as String? ?? 'WORLD',
              isLoading: !hasPose || !hasJoints,
            ));
            checkAndEmitLoaded();
          },
          onError: (error) {
            emit(RobotControlState.error(error.toString()));
          },
        );
  }

  /// Send jog start command
  Future<void> sendJogStart({
    required String axis,
    required String direction,
    double speed = 25.0,
    double step = 0.25,
  }) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'jogStart',
        {
          'axis': axis,
          'direction': direction,
          'speed': speed,
          'step': step,
        },
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Send jog stop command
  Future<void> sendJogStop(String axis) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'jogStop',
        {'axis': axis},
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Send jog stop all command
  Future<void> sendJogStopAll() async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'jogStopAll',
        {},
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Send move command
  Future<void> sendMoveCommand({
    required String mode, // 'pose' or 'joint'
    required List<double> vals,
    double velocity = 20.0,
    double acceleration = 100.0,
    int cnt = 0,
    bool linear = true,
  }) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'move',
        {
          'mode': mode,
          'vals': vals,
          'velocity': velocity,
          'acceleration': acceleration,
          'cnt': cnt,
          'linear': linear,
        },
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Set tool number
  Future<void> setTool(int toolNumber) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'setTool',
        {'toolNumber': toolNumber},
      );
      // Update local state optimistically
      emit(state.copyWith(toolNumber: toolNumber));
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Set user frame
  Future<void> setUserFrame(int userFrame) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'setUserFrame',
        {'userFrame': userFrame},
      );
      // Update local state optimistically
      emit(state.copyWith(userFrame: userFrame));
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Set coordinate system
  Future<void> setCoordSystem(String coordSystem) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'setCoord',
        {'coordSystem': coordSystem},
      );
      // Update local state optimistically
      emit(state.copyWith(coordSystem: coordSystem));
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Set gripper state
  Future<void> setGripper(String state) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'setGripper',
        {'state': state}, // 'open' | 'close' | 'toggle'
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Set Robot Digital Output
  Future<void> setRDO(int index, bool value) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'setRDO',
        {
          'index': index,
          'value': value,
        },
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Get Robot Digital Output
  Future<bool?> getRDO(int index) async {
    try {
      final commandId = await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'getRDO',
        {'index': index},
      );

      // Wait for command result
      final result = await _statusRepository
          .streamCommandResult(deviceId, robotId, commandId)
          .firstWhere(
            (result) =>
                result != null &&
                (result['status'] == 'success' || result['status'] == 'error'),
            orElse: () => null,
          );

      if (result != null &&
          result['status'] == 'success' &&
          result['result'] != null &&
          result['result']['data'] != null) {
        return result['result']['data'] as bool?;
      }
      return null;
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
      return null;
    }
  }

  /// Set Digital Output (controller-level)
  Future<void> setDOUT(int index, bool value) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'setDOUT',
        {
          'index': index,
          'value': value,
        },
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Get Digital Output (controller-level)
  Future<bool?> getDOUT(int index) async {
    try {
      final commandId = await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'getDOUT',
        {'index': index},
      );

      // Wait for command result
      final result = await _statusRepository
          .streamCommandResult(deviceId, robotId, commandId)
          .firstWhere(
            (result) =>
                result != null &&
                (result['status'] == 'success' || result['status'] == 'error'),
            orElse: () => null,
          );

      if (result != null &&
          result['status'] == 'success' &&
          result['result'] != null &&
          result['result']['data'] != null) {
        return result['result']['data'] as bool?;
      }
      return null;
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
      return null;
    }
  }

  /// Get system variable
  Future<dynamic> getSystemVar(String name) async {
    try {
      final commandId = await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'getSystemVar',
        {'name': name},
      );

      // Wait for command result
      final result = await _statusRepository
          .streamCommandResult(deviceId, robotId, commandId)
          .firstWhere(
            (result) =>
                result != null &&
                (result['status'] == 'success' || result['status'] == 'error'),
            orElse: () => null,
          );

      if (result != null &&
          result['status'] == 'success' &&
          result['result'] != null &&
          result['result']['data'] != null) {
        return result['result']['data'];
      }
      return null;
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
      return null;
    }
  }

  /// Set system variable
  Future<void> setSystemVar(String name, dynamic value) async {
    try {
      await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'setSystemVar',
        {
          'name': name,
          'value': value,
        },
      );
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
    }
  }

  /// Get power consumption
  Future<Map<String, double>?> getPowerConsumption() async {
    try {
      final commandId = await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'getPowerConsumption',
        {},
      );

      // Wait for command result
      final result = await _statusRepository
          .streamCommandResult(deviceId, robotId, commandId)
          .firstWhere(
            (result) =>
                result != null &&
                (result['status'] == 'success' || result['status'] == 'error'),
            orElse: () => null,
          );

      if (result != null &&
          result['status'] == 'success' &&
          result['result'] != null &&
          result['result']['data'] != null) {
        final data = result['result']['data'] as Map?;
        if (data != null) {
          return {
            'voltage': (data['voltage'] as num?)?.toDouble() ?? 0.0,
            'current': (data['current'] as num?)?.toDouble() ?? 0.0,
            'power': (data['power'] as num?)?.toDouble() ?? 0.0,
          };
        }
      }
      return null;
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
      return null;
    }
  }

  /// Get robot info
  Future<Map<String, dynamic>?> getRobotInfo() async {
    try {
      final commandId = await _statusRepository.sendCommand(
        deviceId,
        robotId,
        userId,
        'getRobotInfo',
        {},
      );

      // Wait for command result
      final result = await _statusRepository
          .streamCommandResult(deviceId, robotId, commandId)
          .firstWhere(
            (result) =>
                result != null &&
                (result['status'] == 'success' || result['status'] == 'error'),
            orElse: () => null,
          );

      if (result != null &&
          result['status'] == 'success' &&
          result['result'] != null &&
          result['result']['data'] != null) {
        return Map<String, dynamic>.from(result['result']['data'] as Map);
      }
      return null;
    } catch (e) {
      emit(RobotControlState.error(e.toString()));
      return null;
    }
  }

  @override
  Future<void> close() {
    _poseSubscription?.cancel();
    _jointsSubscription?.cancel();
    _configSubscription?.cancel();
    return super.close();
  }
}

