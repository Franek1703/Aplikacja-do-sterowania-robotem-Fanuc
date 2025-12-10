import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import 'config_dropdown.dart';

class ConfigCard extends StatefulWidget {
  final int userFrame;
  final int toolNumber;
  final String coordSystem;
  final ValueChanged<int> onUserFrameChanged;
  final ValueChanged<int> onToolNumberChanged;
  final ValueChanged<String> onCoordSystemChanged;

  const ConfigCard({
    super.key,
    required this.userFrame,
    required this.toolNumber,
    required this.coordSystem,
    required this.onUserFrameChanged,
    required this.onToolNumberChanged,
    required this.onCoordSystemChanged,
  });

  @override
  State<ConfigCard> createState() => _ConfigCardState();
}

class _ConfigCardState extends State<ConfigCard> {
  late final TextEditingController _userFrameController;
  late final TextEditingController _toolNumberController;

  @override
  void initState() {
    super.initState();
    _userFrameController = TextEditingController(text: widget.userFrame.toString());
    _toolNumberController = TextEditingController(text: widget.toolNumber.toString());
  }

  @override
  void didUpdateWidget(ConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userFrame != widget.userFrame) {
      _userFrameController.text = widget.userFrame.toString();
    }
    if (oldWidget.toolNumber != widget.toolNumber) {
      _toolNumberController.text = widget.toolNumber.toString();
    }
  }

  @override
  void dispose() {
    _userFrameController.dispose();
    _toolNumberController.dispose();
    super.dispose();
  }

  int? _parseInt(String value, int current, int min, int max) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < min || parsed > max) {
      return null;
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'User Frame (0-99)',
            controller: _userFrameController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final frame = _parseInt(value, widget.userFrame, 0, 99);
              if (frame != null) {
                widget.onUserFrameChanged(frame);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Tool Number (0-99)',
            controller: _toolNumberController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final tool = _parseInt(value, widget.toolNumber, 0, 99);
              if (tool != null) {
                widget.onToolNumberChanged(tool);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ConfigDropdown(
            label: 'Coordinate System',
            value: widget.coordSystem,
            items: const ['WORLD', 'USER', 'TOOL'],
            labels: const ['WORLD', 'USER', 'TOOL'],
            onChanged: widget.onCoordSystemChanged,
          ),
        ],
      ),
    );
  }
}

