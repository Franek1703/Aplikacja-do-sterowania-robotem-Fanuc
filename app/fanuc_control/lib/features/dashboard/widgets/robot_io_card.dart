import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/secondary_button.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';

class RobotIOCard extends StatefulWidget {
  final Future<bool?> Function(int) onGetRDO;
  final Future<void> Function(int, bool) onSetRDO;
  final Future<bool?> Function(int) onGetDOUT;
  final Future<void> Function(int, bool) onSetDOUT;

  const RobotIOCard({
    super.key,
    required this.onGetRDO,
    required this.onSetRDO,
    required this.onGetDOUT,
    required this.onSetDOUT,
  });

  @override
  State<RobotIOCard> createState() => _RobotIOCardState();
}

class _RobotIOCardState extends State<RobotIOCard> {
  final _rdoIndexController = TextEditingController();
  final _doutIndexController = TextEditingController();
  bool? _rdoValue;
  bool? _doutValue;
  bool _isLoading = false;

  @override
  void dispose() {
    _rdoIndexController.dispose();
    _doutIndexController.dispose();
    super.dispose();
  }

  Future<void> _getRDO() async {
    final index = int.tryParse(_rdoIndexController.text);
    if (index == null) return;

    setState(() => _isLoading = true);
    try {
      final value = await widget.onGetRDO(index);
      setState(() => _rdoValue = value);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setRDO(bool value) async {
    final index = int.tryParse(_rdoIndexController.text);
    if (index == null) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSetRDO(index, value);
      setState(() => _rdoValue = value);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getDOUT() async {
    final index = int.tryParse(_doutIndexController.text);
    if (index == null) return;

    setState(() => _isLoading = true);
    try {
      final value = await widget.onGetDOUT(index);
      setState(() => _doutValue = value);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDOUT(bool value) async {
    final index = int.tryParse(_doutIndexController.text);
    if (index == null) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSetDOUT(index, value);
      setState(() => _doutValue = value);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Robot I/O',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // RDO Section
          const Text(
            'Robot Digital Output (RDO)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Index',
                  controller: _rdoIndexController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  text: 'Get',
                  icon: Icons.search,
                  onPressed: _isLoading ? null : _getRDO,
                ),
              ),
            ],
          ),
          if (_rdoValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Value: ${_rdoValue! ? "ON" : "OFF"}',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Set ON',
                  icon: Icons.power,
                  onPressed: _isLoading ? null : () => _setRDO(true),
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  text: 'Set OFF',
                  icon: Icons.power_off,
                  onPressed: _isLoading ? null : () => _setRDO(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          // DOUT Section
          const Text(
            'Digital Output (DOUT)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Index',
                  controller: _doutIndexController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  text: 'Get',
                  icon: Icons.search,
                  onPressed: _isLoading ? null : _getDOUT,
                ),
              ),
            ],
          ),
          if (_doutValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Value: ${_doutValue! ? "ON" : "OFF"}',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Set ON',
                  icon: Icons.power,
                  onPressed: _isLoading ? null : () => _setDOUT(true),
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  text: 'Set OFF',
                  icon: Icons.power_off,
                  onPressed: _isLoading ? null : () => _setDOUT(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

