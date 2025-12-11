import 'package:flutter/material.dart';
import '../../../common/widgets/app_card.dart';
import '../../../config/constants/app_colors.dart';
import '../../../config/constants/app_spacing.dart';
import '../../../models/ftp_file.dart';

class FtpFileItem extends StatelessWidget {
  final FtpFile file;
  final VoidCallback onTap;

  const FtpFileItem({
    super.key,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: file.type == FtpFileType.folder
                  ? AppColors.yellowOverlay
                  : AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              file.type == FtpFileType.folder
                  ? Icons.folder
                  : file.name.endsWith('.TP')
                      ? Icons.code
                      : Icons.insert_drive_file,
              color: file.type == FtpFileType.folder
                  ? AppColors.primaryYellow
                  : AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (file.type == FtpFileType.file && file.size != null)
                  Text(
                    '${file.size} • ${file.modified ?? ''}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (file.type == FtpFileType.folder)
            const Icon(Icons.chevron_right, color: AppColors.textTertiary)
          else
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: onTap,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

