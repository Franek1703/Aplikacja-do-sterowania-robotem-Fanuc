import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';

class DiagnosticsCard extends StatefulWidget {
  final Future<Map<String, double>?> Function() onGetPowerConsumption;
  final Future<Map<String, dynamic>?> Function() onGetRobotInfo;

  const DiagnosticsCard({
    super.key,
    required this.onGetPowerConsumption,
    required this.onGetRobotInfo,
  });

  @override
  State<DiagnosticsCard> createState() => _DiagnosticsCardState();
}

class _DiagnosticsCardState extends State<DiagnosticsCard> {
  Map<String, double>? _powerData;
  Map<String, dynamic>? _robotInfo;
  bool _isLoading = false;

  Future<void> _loadPowerConsumption() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.onGetPowerConsumption();
      setState(() => _powerData = data);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRobotInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await widget.onGetRobotInfo();
      setState(() => _robotInfo = info);
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
            'Diagnostics & Telemetry',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Power Consumption
          const Text(
            'Power Consumption',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            text: 'Get Power Consumption',
            icon: Icons.battery_charging_full,
            onPressed: _isLoading ? null : _loadPowerConsumption,
            isLoading: _isLoading,
          ),
          if (_powerData != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow('Voltage', '${_powerData!['voltage']?.toStringAsFixed(2)} V'),
            _buildInfoRow('Current', '${_powerData!['current']?.toStringAsFixed(2)} A'),
            _buildInfoRow('Power', '${_powerData!['power']?.toStringAsFixed(2)} W'),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          // Robot Info
          const Text(
            'Robot Information',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            text: 'Get Robot Info',
            icon: Icons.info,
            onPressed: _isLoading ? null : _loadRobotInfo,
            isLoading: _isLoading,
          ),
          if (_robotInfo != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ..._robotInfo!.entries.map((entry) => _buildInfoRow(
                  entry.key,
                  entry.value.toString(),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

