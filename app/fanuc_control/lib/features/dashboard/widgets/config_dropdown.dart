import 'package:flutter/material.dart';
import '../../../config/constants/app_colors.dart';

class ConfigDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final List<String> labels;
  final ValueChanged<String> onChanged;

  const ConfigDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the value exists in items, otherwise use null or first item
    final validValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          items: List.generate(
            items.length,
            (index) => DropdownMenuItem(
              value: items[index],
              child: Text(labels[index]),
            ),
          ),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

