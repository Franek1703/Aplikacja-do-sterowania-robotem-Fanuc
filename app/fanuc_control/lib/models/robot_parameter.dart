/// Robot parameter model
class RobotParameter {
  final String id;
  final String name;
  final dynamic value; // Can be String, int, double, or bool
  final ParameterType type;
  final String? unit;
  final String category;
  final bool isLocked;
  final String? description;

  const RobotParameter({
    required this.id,
    required this.name,
    required this.value,
    required this.type,
    this.unit,
    required this.category,
    this.isLocked = false,
    this.description,
  });

  factory RobotParameter.fromJson(Map<String, dynamic> json) {
    return RobotParameter(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'],
      type: ParameterType.fromString(json['type'] as String? ?? 'string'),
      unit: json['unit'] as String?,
      category: json['category'] as String,
      isLocked: json['isLocked'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'type': type.toString(),
      if (unit != null) 'unit': unit,
      'category': category,
      'isLocked': isLocked,
      if (description != null) 'description': description,
    };
  }

  RobotParameter copyWith({
    String? id,
    String? name,
    dynamic value,
    ParameterType? type,
    String? unit,
    String? category,
    bool? isLocked,
    String? description,
  }) {
    return RobotParameter(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isLocked: isLocked ?? this.isLocked,
      description: description ?? this.description,
    );
  }
}

enum ParameterType {
  number,
  boolean,
  string;

  static ParameterType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'number':
        return ParameterType.number;
      case 'boolean':
        return ParameterType.boolean;
      case 'string':
        return ParameterType.string;
      default:
        return ParameterType.string;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ParameterType.number:
        return 'number';
      case ParameterType.boolean:
        return 'boolean';
      case ParameterType.string:
        return 'string';
    }
  }
}

