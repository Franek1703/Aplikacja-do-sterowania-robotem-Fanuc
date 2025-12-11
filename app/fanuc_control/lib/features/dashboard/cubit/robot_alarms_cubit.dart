import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/alarm.dart';
import '../data/robot_alarms_repository.dart';

part 'robot_alarms_state.dart';

/// Cubit for robot alarms
class RobotAlarmsCubit extends Cubit<RobotAlarmsState> {
  final RobotAlarmsRepository _alarmsRepository;
  final String deviceId;
  final String robotId;

  StreamSubscription<List<Alarm>>? _alarmsSubscription;

  RobotAlarmsCubit({
    required this.deviceId,
    required this.robotId,
    RobotAlarmsRepository? alarmsRepository,
  })  : _alarmsRepository = alarmsRepository ?? RobotAlarmsRepository(),
        super(const RobotAlarmsState.initial()) {
    _loadAlarms();
  }

  void _loadAlarms() {
    emit(const RobotAlarmsState.loading());

    _alarmsSubscription?.cancel();
    _alarmsSubscription = _alarmsRepository
        .streamActiveAlarms(deviceId, robotId)
        .listen(
          (alarms) {
            emit(RobotAlarmsState.loaded(alarms));
          },
          onError: (error) {
            emit(RobotAlarmsState.error(error.toString()));
          },
        );
  }

  Future<void> refreshAlarms() async {
    emit(const RobotAlarmsState.loading());
    try {
      final alarms = await _alarmsRepository.getActiveAlarms(deviceId, robotId);
      emit(RobotAlarmsState.loaded(alarms));
    } catch (e) {
      emit(RobotAlarmsState.error(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _alarmsSubscription?.cancel();
    return super.close();
  }
}

