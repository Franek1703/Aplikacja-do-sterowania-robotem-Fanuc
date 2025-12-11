import '../../../config/repositories/realtime_database_repository.dart';
import '../../../models/ftp_file.dart';

/// Repository for robot FTP operations via RTDB
class RobotFtpRepository {
  final RealtimeDatabaseRepository _rtdb;

  RobotFtpRepository({RealtimeDatabaseRepository? rtdb})
      : _rtdb = rtdb ?? RealtimeDatabaseRepository();

  /// Request FTP file list
  Future<String> requestFileList(
    String deviceId,
    String robotId,
    String userId, {
    String device = 'MD',
    String? pattern,
    String? types,
  }) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final requestPath =
        'devices/$deviceId/robots/$robotId/ftp/requests/$requestId';

    await _rtdb.setValue(requestPath, {
      'type': 'listFiles',
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'createdBy': userId,
      'payload': {
        'device': device,
        if (pattern != null) 'pattern': pattern,
        if (types != null) 'types': types,
      },
    });

    return requestId;
  }

  /// Request FTP file read
  Future<String> requestFileRead(
    String deviceId,
    String robotId,
    String userId,
    String filePath,
  ) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final requestPath =
        'devices/$deviceId/robots/$robotId/ftp/requests/$requestId';

    await _rtdb.setValue(requestPath, {
      'type': 'readFile',
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'createdBy': userId,
      'payload': {
        'filePath': filePath,
      },
    });

    return requestId;
  }

  /// Stream FTP response
  Stream<Map<String, dynamic>?> streamFtpResponse(
    String deviceId,
    String robotId,
    String requestId,
  ) {
    return _rtdb
        .streamValue(
            'devices/$deviceId/robots/$robotId/ftp/responses/$requestId')
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      return Map<String, dynamic>.from(data);
    });
  }

  /// Parse FTP response to FtpFile list
  List<FtpFile> parseFileListResponse(Map<String, dynamic> response) {
    final files = <FtpFile>[];
    final filesList = response['files'] as List<dynamic>?;

    if (filesList != null) {
      for (var fileData in filesList) {
        if (fileData is Map) {
          try {
            final fileMap = Map<String, dynamic>.from(fileData);
            files.add(FtpFile.fromJson(fileMap));
          } catch (e) {
            // Skip invalid file entries
          }
        }
      }
    }

    return files;
  }

  /// Parse FTP file content response
  String? parseFileContentResponse(Map<String, dynamic> response) {
    return response['content'] as String?;
  }
}

