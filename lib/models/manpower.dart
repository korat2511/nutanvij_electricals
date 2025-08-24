import 'contractor.dart';

class Manpower {
  final int? id;
  final int siteId;
  final String date;
  final int skillWorker;
  final int unskillWorker;
  final int shift;
  final double skillPayPerHead;
  final double unskillPayPerHead;
  final double totalAmount;
  final String? createdAt;
  final String? updatedAt;
  Contractor? contractor;

  Manpower({
    this.id,
    required this.siteId,
    required this.date,
    required this.skillWorker,
    required this.unskillWorker,
    required this.shift,
    required this.skillPayPerHead,
    required this.unskillPayPerHead,
    required this.totalAmount,
    this.createdAt,
    this.updatedAt,
    this.contractor
  });

  factory Manpower.fromJson(Map<String, dynamic> json) {
    return Manpower(
      id: _parseInt(json['id']),
      siteId: _parseInt(json['site_id']) ?? 0,
      date: json['date']?.toString() ?? '',
      skillWorker: _parseInt(json['skill_worker']) ?? 0,
      unskillWorker: _parseInt(json['unskill_worker']) ?? 0,
      shift: _parseInt(json['shift']) ?? 1,
      skillPayPerHead: _parseDouble(json['skill_pay_per_head']) ?? 0.0,
      unskillPayPerHead: _parseDouble(json['unskill_pay_per_head']) ?? 0.0,
      totalAmount: _parseDouble(json['total_amount']) ?? 0.0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      contractor: json['contractor'] != null
          ? Contractor.fromJson(json['contractor'])
          : null, // ✅ Parse contractor

    );
  }

  // Helper methods for safe type conversion
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
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
      'created_at': createdAt,
      'updated_at': updatedAt,
      'contractor': contractor?.toJson(), // ✅ Serialize contractor

    };
  }

  Manpower copyWith({
    int? id,
    int? siteId,
    String? date,
    int? skillWorker,
    int? unskillWorker,
    int? shift,
    double? skillPayPerHead,
    double? unskillPayPerHead,
    double? totalAmount,
    String? createdAt,
    String? updatedAt,
    Contractor? contractor,

  }) {
    return Manpower(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      date: date ?? this.date,
      skillWorker: skillWorker ?? this.skillWorker,
      unskillWorker: unskillWorker ?? this.unskillWorker,
      shift: shift ?? this.shift,
      skillPayPerHead: skillPayPerHead ?? this.skillPayPerHead,
      unskillPayPerHead: unskillPayPerHead ?? this.unskillPayPerHead,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contractor: contractor ?? this.contractor,

    );
  }

  String get shiftName {
    switch (shift) {
      case 1:
        return 'Day';
      case 2:
        return 'Night';
      case 3:
        return 'Day & Night';
      default:
        return 'Day';
    }
  }

  int get totalWorkers => skillWorker + unskillWorker;
}

/*
class Contractor {
  final int? id;
  final String? name;
  final String? mobile;
  final String? email;
  final int? siteId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  Contractor({
    this.id,
    this.name,
    this.mobile,
    this.email,
    this.siteId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      email: json['email'],
      siteId: json['site_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'site_id': siteId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}
*/

class ManpowerReport {
  final List<Manpower> data;
  final String message;

  ManpowerReport({
    required this.data,
    required this.message,
  });

  factory ManpowerReport.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] ?? [];
    return ManpowerReport(
      data: dataList.map((item) => Manpower.fromJson(item)).toList(),
      message: json['message'] ?? '',
    );
  }
}
