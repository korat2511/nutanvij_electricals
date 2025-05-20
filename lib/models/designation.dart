class Designation {
  final int id;
  final String name;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  Designation({
    required this.id,
    required this.name,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
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
    };
  }
}