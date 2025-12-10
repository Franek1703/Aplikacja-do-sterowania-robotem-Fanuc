import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/robot.dart';
import '../../robots/data/robot_repository.dart';

part 'robot_info_state.dart';

/// Cubit for robot info (used in dashboard header)
class RobotInfoCubit extends Cubit<RobotInfoState> {
  final RobotRepository _robotRepository;
  final String robotId;

  StreamSubscription<Robot?>? _robotSubscription;

  RobotInfoCubit({
    required this.robotId,
    RobotRepository? robotRepository,
  })  : _robotRepository = robotRepository ?? RobotRepository(),
        super(const RobotInfoState.initial()) {
    _loadRobot();
  }

  void _loadRobot() {
    emit(const RobotInfoState.loading());

    _robotSubscription?.cancel();
    _robotSubscription = _robotRepository.streamRobot(robotId).listen(
          (robot) {
            if (robot != null) {
              emit(RobotInfoState.loaded(robot));
            } else {
              emit(const RobotInfoState.error('Robot not found'));
            }
          },
          onError: (error) {
            emit(RobotInfoState.error(error.toString()));
          },
        );
  }

  Future<void> refreshRobot() async {
    emit(const RobotInfoState.loading());
    try {
      final robot = await _robotRepository.getRobot(robotId);
      if (robot != null) {
        emit(RobotInfoState.loaded(robot));
      } else {
        emit(const RobotInfoState.error('Robot not found'));
      }
    } catch (e) {
      emit(RobotInfoState.error(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _robotSubscription?.cancel();
    return super.close();
  }
}

