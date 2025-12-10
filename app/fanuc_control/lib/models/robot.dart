/// Robot model based on Firestore /robots/{robotId} collection
class Robot {
  final String robotId;
  final String deviceId;
  final String name;
  final String? series;
  final String? model;
  final String? controller;
  final String ipAddress;
  final int tcpPort;
  final String? ftpUser;
  final String? ftpPassword;
  final bool simulation;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  const Robot({
    required this.robotId,
    required this.deviceId,
    required this.name,
    this.series,
    this.model,
    this.controller,
    required this.ipAddress,
    this.tcpPort = 18735,
    this.ftpUser,
    this.ftpPassword,
    this.simulation = false,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
  });

  factory Robot.fromJson(Map<String, dynamic> json) {
    return Robot(
      robotId: json['robotId'] as String,
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      series: json['series'] as String?,
      model: json['model'] as String?,
      controller: json['controller'] as String?,
      ipAddress: json['ipAddress'] as String,
      tcpPort: json['tcpPort'] as int? ?? 18735,
      ftpUser: json['ftpUser'] as String?,
      ftpPassword: json['ftpPassword'] as String?,
      simulation: json['simulation'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'robotId': robotId,
      'deviceId': deviceId,
      'name': name,
      if (series != null) 'series': series,
      if (model != null) 'model': model,
      if (controller != null) 'controller': controller,
      'ipAddress': ipAddress,
      'tcpPort': tcpPort,
      if (ftpUser != null) 'ftpUser': ftpUser,
      if (ftpPassword != null) 'ftpPassword': ftpPassword,
      'simulation': simulation,
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  Robot copyWith({
    String? robotId,
    String? deviceId,
    String? name,
    String? series,
    String? model,
    String? controller,
    String? ipAddress,
    int? tcpPort,
    String? ftpUser,
    String? ftpPassword,
    bool? simulation,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return Robot(
      robotId: robotId ?? this.robotId,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      series: series ?? this.series,
      model: model ?? this.model,
      controller: controller ?? this.controller,
      ipAddress: ipAddress ?? this.ipAddress,
      tcpPort: tcpPort ?? this.tcpPort,
      ftpUser: ftpUser ?? this.ftpUser,
      ftpPassword: ftpPassword ?? this.ftpPassword,
      simulation: simulation ?? this.simulation,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

