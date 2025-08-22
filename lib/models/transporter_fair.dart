class TransporterFair {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String pancard;
  final String? vehicleType;
  final String? company;
  final String? createdAt;
  final String? updatedAt;
  final int userId;
  final List<Fair> fairs;

  TransporterFair({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.pancard,
    this.vehicleType,
    this.company,
    this.createdAt,
    this.updatedAt,
    required this.userId,
    required this.fairs,
  });

  factory TransporterFair.fromJson(Map<String, dynamic> json) {
    return TransporterFair(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      phone: json["phone"],
      address: json["address"],
      pancard: json["pancard"],
      vehicleType: json["vehicle_type"],
      company: json["company"],
      createdAt: json["created_at"],
      updatedAt: json["updated_at"],
      userId: json["user_id"],
      fairs: (json["fair"] as List)
          .map((e) => Fair.fromJson(e))
          .toList(),
    );
  }
}

class Fair {
  final int id;
  final int transporterId;
  final String? vehicleType;
  final String? company;
  final String? toLocation;
  final String? fromLocation;
  final String fair;
  final String date;
  final int paymentStatus;
  final String? paymentDate;
  final int userId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  Fair({
    required this.id,
    required this.transporterId,
    this.vehicleType,
    this.company,
    this.toLocation,
    this.fromLocation,
    required this.fair,
    required this.date,
    required this.paymentStatus,
    this.paymentDate,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Fair.fromJson(Map<String, dynamic> json) {
    return Fair(
      id: json["id"],
      transporterId: json["transporter_id"],
      vehicleType: json["vehicle_type"],
      company: json["company"],
      toLocation: json["to_location"],
      fromLocation: json["from_location"],
      fair: json["fair"],
      date: json["date"],
      paymentStatus: json["payment_status"],
      paymentDate: json["payment_date"],
      userId: json["user_id"],
      createdAt: json["created_at"],
      updatedAt: json["updated_at"],
      deletedAt: json["deleted_at"],
    );
  }
}
