/// Robot pose data (position and orientation)
class RobotPose {
  final double x;
  final double y;
  final double z;
  final double w;
  final double p;
  final double r;
  final DateTime updatedAt;

  const RobotPose({
    required this.x,
    required this.y,
    required this.z,
    required this.w,
    required this.p,
    required this.r,
    required this.updatedAt,
  });

  factory RobotPose.fromJson(Map<String, dynamic> json) {
    return RobotPose(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      p: (json['p'] as num).toDouble(),
      r: (json['r'] as num).toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['updatedAt'] is int
                  ? json['updatedAt'] as int
                  : DateTime.parse(json['updatedAt'] as String).millisecondsSinceEpoch)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'w': w,
      'p': p,
      'r': r,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  RobotPose copyWith({
    double? x,
    double? y,
    double? z,
    double? w,
    double? p,
    double? r,
    DateTime? updatedAt,
  }) {
    return RobotPose(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      w: w ?? this.w,
      p: p ?? this.p,
      r: r ?? this.r,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Robot joint values
class RobotJoints {
  final double j1;
  final double j2;
  final double j3;
  final double j4;
  final double j5;
  final double j6;
  final DateTime updatedAt;

  const RobotJoints({
    required this.j1,
    required this.j2,
    required this.j3,
    required this.j4,
    required this.j5,
    required this.j6,
    required this.updatedAt,
  });

  factory RobotJoints.fromJson(Map<String, dynamic> json) {
    return RobotJoints(
      j1: (json['j1'] as num).toDouble(),
      j2: (json['j2'] as num).toDouble(),
      j3: (json['j3'] as num).toDouble(),
      j4: (json['j4'] as num).toDouble(),
      j5: (json['j5'] as num).toDouble(),
      j6: (json['j6'] as num).toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['updatedAt'] is int
                  ? json['updatedAt'] as int
                  : DateTime.parse(json['updatedAt'] as String).millisecondsSinceEpoch)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'j1': j1,
      'j2': j2,
      'j3': j3,
      'j4': j4,
      'j5': j5,
      'j6': j6,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  RobotJoints copyWith({
    double? j1,
    double? j2,
    double? j3,
    double? j4,
    double? j5,
    double? j6,
    DateTime? updatedAt,
  }) {
    return RobotJoints(
      j1: j1 ?? this.j1,
      j2: j2 ?? this.j2,
      j3: j3 ?? this.j3,
      j4: j4 ?? this.j4,
      j5: j5 ?? this.j5,
      j6: j6 ?? this.j6,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

