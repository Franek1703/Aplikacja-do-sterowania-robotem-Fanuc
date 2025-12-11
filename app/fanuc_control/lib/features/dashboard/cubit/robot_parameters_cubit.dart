import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/robot_parameter.dart';
import '../data/robot_parameters_repository.dart';

part 'robot_parameters_state.dart';

/// Cubit for robot parameters
class RobotParametersCubit extends Cubit<RobotParametersState> {
  final RobotParametersRepository _parametersRepository;
  final String deviceId;
  final String robotId;
  final String userId;

  RobotParametersCubit({
    required this.deviceId,
    required this.robotId,
    required this.userId,
    RobotParametersRepository? parametersRepository,
    List<RobotParameter>? initialParameters,
  })  : _parametersRepository = parametersRepository ?? RobotParametersRepository(),
        super(RobotParametersState.loaded(initialParameters ?? [])) {
    _loadParameters();
  }

  Future<void> _loadParameters() async {
    emit(const RobotParametersState.loading());
    try {
      // Parameters might be static or loaded from repository
      // For now, we'll use the initial parameters if provided
      // In a real implementation, these would be loaded from Firestore/RTDB
      final parameters = await _parametersRepository.getParameters(deviceId, robotId);
      if (parameters.isEmpty && state.parameters.isNotEmpty) {
        // Keep initial parameters if repository returns empty
        emit(RobotParametersState.loaded(state.parameters));
      } else {
        emit(RobotParametersState.loaded(parameters));
      }
    } catch (e) {
      emit(RobotParametersState.error(e.toString()));
    }
  }

  Future<void> updateParameter(String parameterId, dynamic value) async {
    try {
      await _parametersRepository.updateParameter(
        deviceId,
        robotId,
        userId,
        parameterId,
        value,
      );

      // Update local state
      final updatedParameters = state.parameters.map((p) {
        if (p.id == parameterId) {
          return p.copyWith(value: value);
        }
        return p;
      }).toList();

      emit(RobotParametersState.loaded(updatedParameters));
    } catch (e) {
      emit(RobotParametersState.error(e.toString()));
    }
  }
}

