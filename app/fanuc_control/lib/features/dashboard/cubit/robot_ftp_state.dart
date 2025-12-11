part of 'robot_ftp_cubit.dart';

/// Robot FTP state
class RobotFtpState extends Equatable {
  final String currentPath;
  final List<FtpFile> files;
  final String? loadedFilePath;
  final String? loadedFileContent;
  final bool isLoading;
  final bool isLoadingFile;
  final String? error;

  const RobotFtpState({
    this.currentPath = '/',
    this.files = const [],
    this.loadedFilePath,
    this.loadedFileContent,
    this.isLoading = false,
    this.isLoadingFile = false,
    this.error,
  });

  const RobotFtpState.initial()
      : currentPath = '/',
        files = const [],
        loadedFilePath = null,
        loadedFileContent = null,
        isLoading = false,
        isLoadingFile = false,
        error = null;

  const RobotFtpState.loading(String this.currentPath)
      : files = const [],
        loadedFilePath = null,
        loadedFileContent = null,
        isLoading = true,
        isLoadingFile = false,
        error = null;

  const RobotFtpState.loaded(String this.currentPath, List<FtpFile> this.files)
      : loadedFilePath = null,
        loadedFileContent = null,
        isLoading = false,
        isLoadingFile = false,
        error = null;

  const RobotFtpState.loadingFile(String this.loadedFilePath)
      : currentPath = '/',
        files = const [],
        loadedFileContent = null,
        isLoading = false,
        isLoadingFile = true,
        error = null;

  const RobotFtpState.fileLoaded(String this.loadedFilePath, String this.loadedFileContent)
      : currentPath = '/',
        files = const [],
        isLoading = false,
        isLoadingFile = false,
        error = null;

  const RobotFtpState.error(String this.currentPath, String this.error)
      : files = const [],
        loadedFilePath = null,
        loadedFileContent = null,
        isLoading = false,
        isLoadingFile = false;

  @override
  List<Object?> get props => [
        currentPath,
        files,
        loadedFilePath,
        loadedFileContent,
        isLoading,
        isLoadingFile,
        error,
      ];
}

