import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../common/widgets/primary_button.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../features/dashboard/widgets/ftp_file_item.dart';
import '../../models/ftp_file.dart';

class FtpView extends StatefulWidget {
  final String robotId;
  final String deviceId;

  const FtpView({
    super.key,
    required this.robotId,
    required this.deviceId,
  });

  @override
  State<FtpView> createState() => _FtpViewState();
}

class _FtpViewState extends State<FtpView> {
  String _currentPath = '/';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final files = state.ftpFiles[_currentPath] ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  if (_currentPath != '/')
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
                        parts.removeLast();
                        setState(() {
                          _currentPath = parts.isEmpty ? '/' : '/${parts.join('/')}';
                        });
                      },
                      color: AppColors.textSecondary,
                    ),
                  Expanded(
                    child: Text(
                      _currentPath,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  PrimaryButton(
                    text: 'New File',
                    icon: Icons.add,
                    onPressed: () {
                      // TODO: Implement new file creation
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // File list
              ...files.map((file) => FtpFileItem(
                    file: file,
                    onTap: () {
                      if (file.type == FtpFileType.folder) {
                        setState(() {
                          _currentPath = _currentPath == '/'
                              ? '/${file.name}'
                              : '$_currentPath/${file.name}';
                        });
                      } else {
                        _showFileContent(context, file);
                      }
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showFileContent(BuildContext context, FtpFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            const Icon(Icons.code, color: AppColors.primaryYellow),
            const SizedBox(width: 8),
            Expanded(child: Text(file.name)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            child: Text(
              file.content ?? 'No content available',
              style: const TextStyle(
                color: Colors.green,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
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
