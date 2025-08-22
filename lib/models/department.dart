class SubDepartment {
  final int id;
  final int departmentId;
  final String name;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  SubDepartment({
    required this.id,
    required this.departmentId,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory SubDepartment.fromJson(Map<String, dynamic> json) {
    return SubDepartment(
      id: json['id'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_id': departmentId,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}

class Department {
  final int id;
  final String name;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final List<SubDepartment> subDepartments;

  Department({
    required this.id,
    required this.name,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.subDepartments = const [],
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      subDepartments: (json['sub_department'] as List<dynamic>? ?? [])
          .map((e) => SubDepartment.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sub_department': subDepartments.map((e) => e.toJson()).toList(),
    };
  }
} 