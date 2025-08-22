class FairReportResponse {
  final int status;
  final String message;
  final TransporterData? data;
  final String total;
  final String excelUrl;

  FairReportResponse({
    required this.status,
    required this.message,
    this.data,
    required this.total,
    required this.excelUrl,
  });

  factory FairReportResponse.fromJson(Map<String, dynamic> json) {
    return FairReportResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? "",
      data: json['data'] != null ? TransporterData.fromJson(json['data']) : null,
      total: json['total']?.toString() ?? "0.0",
      excelUrl: json['excel_url'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "message": message,
      "data": data?.toJson(),
      "total": total,
      "excel_url": excelUrl,
    };
  }
}

class TransporterData {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String pancard;
  final List<Fair> fair;
  final String vehicleType;
  final String company;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final int userId;

  TransporterData({
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

  factory TransporterData.fromJson(Map<String, dynamic> json) {
    return TransporterData(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      address: json['address'] ?? "",
      pancard: json['pancard'] ?? "",
      fair: (json['fair'] as List<dynamic>?)
          ?.map((e) => Fair.fromJson(e))
          .toList() ??
          [],
      vehicleType: json['vehicle_type']?.toString() ?? "",
      company: json['company'] ?? "",
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
      deletedAt: json['deleted_at'],
      userId: json['user_id'] ?? 0,
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
      "fair": fair.map((e) => e.toJson()).toList(),
      "vehicle_type": vehicleType,
      "company": company,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "deleted_at": deletedAt,
      "user_id": userId,
    };
  }
}

class Fair {
  final int id;
  final int transporterId;
  final String? vehicleType;
  final String? company;
  final String toLocation;
  final String fromLocation;
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
    required this.toLocation,
    required this.fromLocation,
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
      id: json['id'] ?? 0,
      transporterId: json['transporter_id'] ?? 0,
      vehicleType: json['vehicle_type'],
      company: json['company'],
      toLocation: json['to_location'] ?? "",
      fromLocation: json['from_location'] ?? "",
      fair: json['fair']?.toString() ?? "0.0",
      date: json['date'] ?? "",
      paymentStatus: json['payment_status'] ?? 0,
      paymentDate: json['payment_date'],
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "transporter_id": transporterId,
      "vehicle_type": vehicleType,
      "company": company,
      "to_location": toLocation,
      "from_location": fromLocation,
      "fair": fair,
      "date": date,
      "payment_status": paymentStatus,
      "payment_date": paymentDate,
      "user_id": userId,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "deleted_at": deletedAt,
    };
  }
}
