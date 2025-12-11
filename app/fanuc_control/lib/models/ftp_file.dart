/// FTP file system item model
class FtpFile {
  final String name;
  final FtpFileType type;
  final String? size;
  final String? modified;
  final String? content;

  const FtpFile({
    required this.name,
    required this.type,
    this.size,
    this.modified,
    this.content,
  });

  factory FtpFile.fromJson(Map<String, dynamic> json) {
    return FtpFile(
      name: json['name'] as String,
      type: json['type'] == 'folder'
          ? FtpFileType.folder
          : FtpFileType.file,
      size: json['size'] as String?,
      modified: json['modified'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type == FtpFileType.folder ? 'folder' : 'file',
      if (size != null) 'size': size,
      if (modified != null) 'modified': modified,
      if (content != null) 'content': content,
    };
  }
}

enum FtpFileType {
  file,
  folder,
}

