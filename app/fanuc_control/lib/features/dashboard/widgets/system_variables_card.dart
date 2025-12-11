import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/secondary_button.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';

class SystemVariablesCard extends StatefulWidget {
  final Future<dynamic> Function(String) onGetSystemVar;
  final Future<void> Function(String, dynamic) onSetSystemVar;

  const SystemVariablesCard({
    super.key,
    required this.onGetSystemVar,
    required this.onSetSystemVar,
  });

  @override
  State<SystemVariablesCard> createState() => _SystemVariablesCardState();
}

class _SystemVariablesCardState extends State<SystemVariablesCard> {
  final _varNameController = TextEditingController();
  final _varValueController = TextEditingController();
  dynamic _varValue;
  bool _isLoading = false;

  @override
  void dispose() {
    _varNameController.dispose();
    _varValueController.dispose();
    super.dispose();
  }

  Future<void> _getSystemVar() async {
    final name = _varNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final value = await widget.onGetSystemVar(name);
      setState(() {
        _varValue = value;
        _varValueController.text = value?.toString() ?? '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setSystemVar() async {
    final name = _varNameController.text.trim();
    final valueStr = _varValueController.text.trim();
    if (name.isEmpty || valueStr.isEmpty) return;

    // Try to parse as number first, then use as string
    dynamic value = double.tryParse(valueStr) ?? int.tryParse(valueStr) ?? valueStr;

    setState(() => _isLoading = true);
    try {
      await widget.onSetSystemVar(name, value);
      setState(() => _varValue = value);
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
            'System Variables',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Variable Name (e.g., \$SCR.\$CYCLETIME)',
            controller: _varNameController,
            hint: '\$SCR.\$CYCLETIME',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Value',
                  controller: _varValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SecondaryButton(
                text: 'Get',
                icon: Icons.search,
                onPressed: _isLoading ? null : _getSystemVar,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            text: 'Set Variable',
            icon: Icons.save,
            onPressed: _isLoading ? null : _setSystemVar,
            isLoading: _isLoading,
          ),
          if (_varValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Current Value: $_varValue',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

