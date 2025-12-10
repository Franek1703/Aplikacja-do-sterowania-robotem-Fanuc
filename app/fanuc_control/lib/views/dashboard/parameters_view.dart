import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/dashboard/cubit/robot_parameters_cubit.dart';
import '../../features/dashboard/widgets/parameter_card.dart';
import '../../models/robot_parameter.dart';

class ParametersView extends StatefulWidget {
  final String robotId;
  final String deviceId;

  const ParametersView({
    super.key,
    required this.robotId,
    required this.deviceId,
  });

  @override
  State<ParametersView> createState() => _ParametersViewState();
}

class _ParametersViewState extends State<ParametersView> {
  String? _editingId;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.uid ?? '';
    
    // Use default parameters for now - in a real app these would come from Firestore
    final defaultParameters = [
      RobotParameter(
        id: '1',
        name: 'Override Speed',
        value: 100,
        type: ParameterType.number,
        unit: '%',
        category: 'Motion',
        isLocked: false,
        description: 'Global speed override percentage',
      ),
      RobotParameter(
        id: '2',
        name: 'Joint Speed Limit',
        value: 250,
        type: ParameterType.number,
        unit: 'deg/sec',
        category: 'Motion',
        isLocked: false,
        description: 'Maximum angular velocity for joints',
      ),
      RobotParameter(
        id: '3',
        name: 'Collision Detection',
        value: true,
        type: ParameterType.boolean,
        category: 'Safety',
        isLocked: true,
        description: 'Enable/disable collision detection system',
      ),
      RobotParameter(
        id: '4',
        name: 'Emergency Stop Enabled',
        value: true,
        type: ParameterType.boolean,
        category: 'Safety',
        isLocked: true,
        description: 'Emergency stop circuit status',
      ),
      RobotParameter(
        id: '5',
        name: 'Payload Weight',
        value: 25.5,
        type: ParameterType.number,
        unit: 'kg',
        category: 'Configuration',
        isLocked: false,
        description: 'Current tool and payload weight',
      ),
      RobotParameter(
        id: '6',
        name: 'TCP Offset X',
        value: 0.0,
        type: ParameterType.number,
        unit: 'mm',
        category: 'Configuration',
        isLocked: false,
        description: 'Tool center point X offset',
      ),
      RobotParameter(
        id: '7',
        name: 'Auto Backup',
        value: true,
        type: ParameterType.boolean,
        category: 'System',
        isLocked: false,
        description: 'Automatic backup of programs',
      ),
      RobotParameter(
        id: '8',
        name: 'Controller IP',
        value: '192.168.1.100',
        type: ParameterType.string,
        category: 'Network',
        isLocked: false,
        description: 'Controller network IP address',
      ),
    ];

    return BlocProvider(
      create: (context) => RobotParametersCubit(
        deviceId: widget.deviceId,
        robotId: widget.robotId,
        userId: userId,
        initialParameters: defaultParameters,
      ),
      child: BlocBuilder<RobotParametersCubit, RobotParametersState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final parameters = state.parameters;
        final categories = parameters.map((p) => p.category).toSet().toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.yellowOverlay,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: AppColors.primaryYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Robot Parameters',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Configure robot settings',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Parameters by category
              ...categories.map((category) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...parameters
                          .where((p) => p.category == category)
                          .map((param) => ParameterCard(
                                parameter: param,
                                isEditing: _editingId == param.id,
                                editValue: _editController.text,
                                onEdit: () {
                                  setState(() {
                                    _editingId = param.id;
                                    _editController.text = param.value.toString();
                                  });
                                },
                                onSave: () {
                                  final value = param.type == ParameterType.number
                                      ? double.tryParse(_editController.text)
                                      : _editController.text;
                                  if (value != null) {
                                    context
                                        .read<RobotParametersCubit>()
                                        .updateParameter(param.id, value);
                                  }
                                  setState(() {
                                    _editingId = null;
                                    _editController.clear();
                                  });
                                },
                                onCancel: () {
                                  setState(() {
                                    _editingId = null;
                                    _editController.clear();
                                  });
                                },
                                onToggle: (value) {
                                  context
                                      .read<RobotParametersCubit>()
                                      .updateParameter(param.id, value);
                                },
                                onEditValueChanged: (value) {
                                  _editController.text = value;
                                },
                              )),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  )),
            ],
          ),
        );
        },
      ),
    );
  }
}
