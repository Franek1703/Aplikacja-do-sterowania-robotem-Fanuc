/// Alarm model based on RTDB /devices/{deviceId}/robots/{robotId}/alarms/active/{alarmId}
class Alarm {
  final String alarmId;
  final String robotId;
  final String? deviceId;
  final String code;
  final AlarmSeverity severity;
  final String title;
  final String? description;
  final DateTime timestamp;
  final DateTime? clearedAt;
  final String? source;

  const Alarm({
    required this.alarmId,
    required this.robotId,
    this.deviceId,
    required this.code,
    required this.severity,
    required this.title,
    this.description,
    required this.timestamp,
    this.clearedAt,
    this.source,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      alarmId: json['alarmId'] as String,
      robotId: json['robotId'] as String,
      deviceId: json['deviceId'] as String?,
      code: json['code'] as String,
      severity: AlarmSeverity.fromString(json['severity'] as String? ?? 'ERROR'),
      title: json['title'] as String? ?? json['message'] as String? ?? '',
      description: json['description'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['timestamp'] is int
                  ? json['timestamp'] as int
                  : DateTime.parse(json['timestamp'] as String).millisecondsSinceEpoch)
          : DateTime.now(),
      clearedAt: json['clearedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['clearedAt'] is int
                  ? json['clearedAt'] as int
                  : DateTime.parse(json['clearedAt'] as String).millisecondsSinceEpoch)
          : null,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alarmId': alarmId,
      'robotId': robotId,
      if (deviceId != null) 'deviceId': deviceId,
      'code': code,
      'severity': severity.toString(),
      'title': title,
      if (description != null) 'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (clearedAt != null) 'clearedAt': clearedAt!.millisecondsSinceEpoch,
      if (source != null) 'source': source,
    };
  }
}

enum AlarmSeverity {
  error,
  warning,
  info;

  static AlarmSeverity fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ERROR':
        return AlarmSeverity.error;
      case 'WARNING':
        return AlarmSeverity.warning;
      case 'INFO':
        return AlarmSeverity.info;
      default:
        return AlarmSeverity.error;
    }
  }

  @override
  String toString() {
    switch (this) {
      case AlarmSeverity.error:
        return 'ERROR';
      case AlarmSeverity.warning:
        return 'WARNING';
      case AlarmSeverity.info:
        return 'INFO';
    }
  }
}

