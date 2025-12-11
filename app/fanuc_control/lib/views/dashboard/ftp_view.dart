import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../common/widgets/primary_button.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/dashboard/cubit/robot_ftp_cubit.dart';
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
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.uid ?? '';

    return BlocProvider(
      create: (context) => RobotFtpCubit(
        deviceId: widget.deviceId,
        robotId: widget.robotId,
        userId: userId,
      ),
      child: BlocBuilder<RobotFtpCubit, RobotFtpState>(
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

          final files = state.files;
          final currentPath = state.currentPath;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  if (currentPath != '/')
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        final parts = currentPath.split('/').where((p) => p.isNotEmpty).toList();
                        parts.removeLast();
                        final newPath = parts.isEmpty ? '/' : '/${parts.join('/')}';
                        context.read<RobotFtpCubit>().loadFiles(newPath);
                      },
                      color: AppColors.textSecondary,
                    ),
                  Expanded(
                    child: Text(
                      currentPath,
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
                        final newPath = currentPath == '/'
                            ? '/${file.name}'
                            : '$currentPath/${file.name}';
                        context.read<RobotFtpCubit>().loadFiles(newPath);
                      } else {
                        context.read<RobotFtpCubit>().readFile('$currentPath/${file.name}');
                        _showFileContent(context, file);
                      }
                    },
                  )),
            ],
          ),
        );
        },
      ),
    );
  }

  void _showFileContent(BuildContext context, FtpFile file) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<RobotFtpCubit, RobotFtpState>(
        builder: (context, state) {
          final content = state.loadedFilePath == file.name
              ? state.loadedFileContent
              : file.content;

          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Row(
              children: [
                const Icon(Icons.code, color: AppColors.primaryYellow),
                const SizedBox(width: 8),
                Expanded(child: Text(file.name)),
              ],
            ),
            content: state.isLoadingFile
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        content ?? 'No content available',
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
          );
        },
      ),
    );
  }
}
