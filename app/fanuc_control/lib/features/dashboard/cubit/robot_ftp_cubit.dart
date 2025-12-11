import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/ftp_file.dart';
import '../data/robot_ftp_repository.dart';

part 'robot_ftp_state.dart';

/// Cubit for robot FTP operations
class RobotFtpCubit extends Cubit<RobotFtpState> {
  final RobotFtpRepository _ftpRepository;
  final String deviceId;
  final String robotId;
  final String userId;

  String _currentPath = '/';
  Map<String, List<FtpFile>> _filesCache = {};

  RobotFtpCubit({
    required this.deviceId,
    required this.robotId,
    required this.userId,
    RobotFtpRepository? ftpRepository,
  })  : _ftpRepository = ftpRepository ?? RobotFtpRepository(),
        super(const RobotFtpState.initial()) {
    _loadFiles(_currentPath);
  }

  Future<void> _loadFiles(String path) async {
    emit(RobotFtpState.loading(path));

    try {
      final requestId = await _ftpRepository.requestFileList(
        deviceId,
        robotId,
        userId,
        device: 'MD',
      );

      // Listen for response
      _ftpRepository
          .streamFtpResponse(deviceId, robotId, requestId)
          .timeout(const Duration(seconds: 30))
          .listen(
            (response) {
              if (response != null && response['status'] == 'success') {
                final files = _ftpRepository.parseFileListResponse(response);
                _filesCache[path] = files;
                emit(RobotFtpState.loaded(path, files));
              } else if (response != null && response['status'] == 'error') {
                emit(RobotFtpState.error(
                  path,
                  response['error']?.toString() ?? 'FTP operation failed',
                ));
              }
            },
            onError: (error) {
              emit(RobotFtpState.error(path, error.toString()));
            },
          );
    } catch (e) {
      emit(RobotFtpState.error(path, e.toString()));
    }
  }

  Future<void> loadFiles(String path) async {
    _currentPath = path;
    if (_filesCache.containsKey(path)) {
      emit(RobotFtpState.loaded(path, _filesCache[path]!));
    } else {
      await _loadFiles(path);
    }
  }

  Future<void> readFile(String filePath) async {
    emit(RobotFtpState.loadingFile(filePath));

    try {
      final requestId = await _ftpRepository.requestFileRead(
        deviceId,
        robotId,
        userId,
        filePath,
      );

      // Listen for response
      _ftpRepository
          .streamFtpResponse(deviceId, robotId, requestId)
          .timeout(const Duration(seconds: 30))
          .listen(
            (response) {
              if (response != null && response['status'] == 'success') {
                final content = _ftpRepository.parseFileContentResponse(response);
                emit(RobotFtpState.fileLoaded(filePath, content ?? ''));
              } else if (response != null && response['status'] == 'error') {
                emit(RobotFtpState.error(
                  _currentPath,
                  response['error']?.toString() ?? 'Failed to read file',
                ));
              }
            },
            onError: (error) {
              emit(RobotFtpState.error(_currentPath, error.toString()));
            },
          );
    } catch (e) {
      emit(RobotFtpState.error(_currentPath, e.toString()));
    }
  }

  String get currentPath => _currentPath;
}

