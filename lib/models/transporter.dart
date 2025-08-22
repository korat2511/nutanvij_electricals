class Transporter {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String pancard;
  final String fair;
  final String vehicleType;
  final String company;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final int userId;

  Transporter({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.pancard,
    required this.fair,
    required this.vehicleType,
    required this.company,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.userId,
  });

  /// ✅ copyWith method
  Transporter copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? pancard,
    String? fair,
    String? vehicleType,
    String? company,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    int? userId,
  }) {
    return Transporter(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      pancard: pancard ?? this.pancard,
      fair: fair ?? this.fair,
      vehicleType: vehicleType ?? this.vehicleType,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
    );
  }

  factory Transporter.fromJson(Map<String, dynamic> json) {
    return Transporter(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      pancard: json['pancard'] ?? '',
      fair: json['fair'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      company: json['company'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "address": address,
      "pancard": pancard,
      "fair": fair,
      "vehicle_type": vehicleType,
      "company": company,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "deleted_at": deletedAt,
      "user_id": userId,
    };
  }
}
