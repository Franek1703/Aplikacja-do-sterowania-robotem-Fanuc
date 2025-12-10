import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/dashboard/cubit/robot_parameters_cubit.dart';
import '../../features/dashboard/cubit/robot_control_cubit.dart';
import '../../features/dashboard/widgets/parameter_card.dart';
import '../../features/dashboard/widgets/robot_io_card.dart';
import '../../features/dashboard/widgets/system_variables_card.dart';
import '../../features/dashboard/widgets/diagnostics_card.dart';
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
        name: 'FTP Password',
        value: '',
        type: ParameterType.string,
        category: 'Network',
        isLocked: false,
        description: 'FTP access password for robot file system',
      ),
      RobotParameter(
        id: '2',
        name: 'Override Speed',
        value: 100,
        type: ParameterType.number,
        unit: '%',
        category: 'Motion',
        isLocked: false,
        description: 'Global speed override percentage',
      ),
      RobotParameter(
        id: '3',
        name: 'Auto Backup',
        value: true,
        type: ParameterType.boolean,
        category: 'System',
        isLocked: false,
        description: 'Automatic backup of programs',
      ),
      RobotParameter(
        id: '4',
        name: 'Controller IP',
        value: '192.168.1.100',
        type: ParameterType.string,
        category: 'Network',
        isLocked: false,
        description: 'Controller network IP address',
      ),
    ];

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RobotParametersCubit(
            deviceId: widget.deviceId,
            robotId: widget.robotId,
            userId: userId,
            initialParameters: defaultParameters,
          ),
        ),
        BlocProvider(
          create: (context) => RobotControlCubit(
            deviceId: widget.deviceId,
            robotId: widget.robotId,
            userId: userId,
          ),
        ),
      ],
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
                  const Expanded(
                    child: Column(
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
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () {
                      _showSetupGuide(context);
                    },
                    color: AppColors.textSecondary,
                    tooltip: 'Setup Guide',
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
              const SizedBox(height: AppSpacing.lg),
              // Robot I/O Section
              RobotIOCard(
                onGetRDO: (index) async {
                  final cubit = context.read<RobotControlCubit>();
                  return await cubit.getRDO(index);
                },
                onSetRDO: (index, value) async {
                  final cubit = context.read<RobotControlCubit>();
                  await cubit.setRDO(index, value);
                },
                onGetDOUT: (index) async {
                  final cubit = context.read<RobotControlCubit>();
                  return await cubit.getDOUT(index);
                },
                onSetDOUT: (index, value) async {
                  final cubit = context.read<RobotControlCubit>();
                  await cubit.setDOUT(index, value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              // System Variables Section
              SystemVariablesCard(
                onGetSystemVar: (name) async {
                  final cubit = context.read<RobotControlCubit>();
                  return await cubit.getSystemVar(name);
                },
                onSetSystemVar: (name, value) async {
                  final cubit = context.read<RobotControlCubit>();
                  await cubit.setSystemVar(name, value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              // Diagnostics Section
              DiagnosticsCard(
                onGetPowerConsumption: () async {
                  final cubit = context.read<RobotControlCubit>();
                  return await cubit.getPowerConsumption();
                },
                onGetRobotInfo: () async {
                  final cubit = context.read<RobotControlCubit>();
                  return await cubit.getRobotInfo();
                },
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  void _showSetupGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryYellow),
            SizedBox(width: 8),
            Text(
              'Firebase Setup Guide',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To configure parameters in Firebase:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '1. Firestore: Create parameter definitions at',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              SelectableText(
                '/robots/{robotId}/parameters/{parameterId}',
                style: const TextStyle(
                  color: AppColors.primaryYellow,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '2. Realtime Database: Parameter values at',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              SelectableText(
                '/devices/{deviceId}/robots/{robotId}/parameters',
                style: const TextStyle(
                  color: AppColors.primaryYellow,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'See docs/firebase_parameters_setup.md for detailed instructions.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
