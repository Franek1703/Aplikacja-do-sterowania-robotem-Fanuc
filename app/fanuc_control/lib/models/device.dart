/// Device model based on Firestore /devices/{deviceId} collection
class Device {
  final String deviceId;
  final String name;
  final String? description;
  final String? ownerUid;
  final List<String> members;
  final bool online;
  final DateTime? lastSeen;
  final int robotCount;
  final DateTime? createdAt;
  final String? imageUrl;

  const Device({
    required this.deviceId,
    required this.name,
    this.description,
    this.ownerUid,
    this.members = const [],
    this.online = false,
    this.lastSeen,
    this.robotCount = 0,
    this.createdAt,
    this.imageUrl,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerUid: json['ownerUid'] as String?,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      online: json['online'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      robotCount: json['robotCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'name': name,
      if (description != null) 'description': description,
      if (ownerUid != null) 'ownerUid': ownerUid,
      'members': members,
      'online': online,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
      'robotCount': robotCount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  Device copyWith({
    String? deviceId,
    String? name,
    String? description,
    String? ownerUid,
    List<String>? members,
    bool? online,
    DateTime? lastSeen,
    int? robotCount,
    DateTime? createdAt,
    String? imageUrl,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerUid: ownerUid ?? this.ownerUid,
      members: members ?? this.members,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
      robotCount: robotCount ?? this.robotCount,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

