class ManpowerResponse {
  final int status;
  final String message;
  final List<Manpower> data;

  ManpowerResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ManpowerResponse.fromJson(Map<String, dynamic> json) {
    return ManpowerResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => Manpower.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class Manpower {
  final int id;
  final int siteId;
  final String date;
  final int skillWorker;
  final int unskillWorker;
  final String shift;
  final String skillPayPerHead;
  final String unskillPayPerHead;
  final String totalAmount;
  final int contractorId;
  final String createdAt;
  final String updatedAt;
  final Contractor contractor;

  Manpower({
    required this.id,
    required this.siteId,
    required this.date,
    required this.skillWorker,
    required this.unskillWorker,
    required this.shift,
    required this.skillPayPerHead,
    required this.unskillPayPerHead,
    required this.totalAmount,
    required this.contractorId,
    required this.createdAt,
    required this.updatedAt,
    required this.contractor,
  });

  factory Manpower.fromJson(Map<String, dynamic> json) {
    return Manpower(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      date: json['date'] ?? '',
      skillWorker: json['skill_worker'] ?? 0,
      unskillWorker: json['unskill_worker'] ?? 0,
      shift: json['shift'] ?? '',
      skillPayPerHead: json['skill_pay_per_head'] ?? '0',
      unskillPayPerHead: json['unskill_pay_per_head'] ?? '0',
      totalAmount: json['total_amount'] ?? '0',
      contractorId: json['contractor_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      contractor: Contractor.fromJson(json['contractor'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'date': date,
      'skill_worker': skillWorker,
      'unskill_worker': unskillWorker,
      'shift': shift,
      'skill_pay_per_head': skillPayPerHead,
      'unskill_pay_per_head': unskillPayPerHead,
      'total_amount': totalAmount,
      'contractor_id': contractorId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'contractor': contractor.toJson(),
    };
  }
}

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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      siteId: json['site_id'] ?? 0,
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
