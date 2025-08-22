class Contractor {
  final int id;
  final String name;
  final String mobile;
  final String email;
  final int siteId;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  Contractor({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.siteId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      email: json['email'],
      siteId: json['site_id'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'site_id': siteId,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
