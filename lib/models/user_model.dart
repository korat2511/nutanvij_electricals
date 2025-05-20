import 'package:nutanvij_electricals/models/designation.dart';

class UserModel {
  final int status;
  final String message;
  final String token;
  final UserData data;

  UserModel({
    required this.status,
    required this.message,
    required this.token,
    required this.data,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      data: UserData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'token': token,
      'data': data.toJson(),
    };
  }
}

class UserData {
  final int id;
  final String name;
  final String email;
  final String apiToken;
  final int designationId;
  final String? deviceId;
  final String mobile;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? imagePath;
  final Designation designation;
  final int? salaryAccountId;
  final String? employeeId;
  final int? subDepartmentId;
  final String? salary;
  final String? dob;
  final String? dateOfJoining;
  final String? bankAccountNo;
  final String? bankName;
  final String? ifscCode;
  final String? panCardNo;
  final String? aadharCardNo;
  final String? addharCardFront;
  final String? addharCardBack;
  final String? panCardImage;
  final String? passbookImage;
  final String? addharCardFrontPath;
  final String? addharCardBackPath;
  final String? panCardImagePath;
  final String? passbookImagePath;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.apiToken,
    required this.designationId,
    this.deviceId,
    this.imagePath,
    required this.mobile,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.designation,
    this.salaryAccountId,
    this.employeeId,
    this.subDepartmentId,
    this.salary,
    this.dob,
    this.dateOfJoining,
    this.bankAccountNo,
    this.bankName,
    this.ifscCode,
    this.panCardNo,
    this.aadharCardNo,
    this.addharCardFront,
    this.addharCardBack,
    this.panCardImage,
    this.passbookImage,
    this.addharCardFrontPath,
    this.addharCardBackPath,
    this.panCardImagePath,
    this.passbookImagePath,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      apiToken: json['api_token'] ?? '',
      designationId: json['designation_id'] is int
          ? json['designation_id']
          : int.tryParse(json['designation_id']?.toString() ?? '0') ?? 0,
      deviceId: json['device_id'],
      imagePath: json['image_path'],
      mobile: json['mobile'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      designation: json['designation'] != null 
          ? Designation.fromJson(json['designation'])
          : Designation(id: 0, name: '', status: ''),
      salaryAccountId: json['salary_account_id'],
      employeeId: json['employee_id'],
      subDepartmentId: json['sub_department_id'] is int
          ? json['sub_department_id']
          : int.tryParse(json['sub_department_id']?.toString() ?? '0'),
      salary: json['salary'],
      dob: json['dob'],
      dateOfJoining: json['date_of_joining'],
      bankAccountNo: json['bank_account_no'],
      bankName: json['bank_name'],
      ifscCode: json['ifsc_code'],
      panCardNo: json['pan_card_no'],
      aadharCardNo: json['aadhar_card_no'],
      addharCardFront: json['addhar_card_front'],
      addharCardBack: json['addhar_card_back'],
      panCardImage: json['pan_card_image'],
      passbookImage: json['passbook_image'],
      addharCardFrontPath: json['addhar_card_front_path'],
      addharCardBackPath: json['addhar_card_back_path'],
      panCardImagePath: json['pan_card_image_path'],
      passbookImagePath: json['passbook_image_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'api_token': apiToken,
      'designation_id': designationId,
      'device_id': deviceId,
      'image_path': imagePath,
      'mobile': mobile,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'designation': designation.toJson(),
      'salary_account_id': salaryAccountId,
      'employee_id': employeeId,
      'sub_department_id': subDepartmentId,
      'salary': salary,
      'dob': dob,
      'date_of_joining': dateOfJoining,
      'bank_account_no': bankAccountNo,
      'bank_name': bankName,
      'ifsc_code': ifscCode,
      'pan_card_no': panCardNo,
      'aadhar_card_no': aadharCardNo,
      'addhar_card_front': addharCardFront,
      'addhar_card_back': addharCardBack,
      'pan_card_image': panCardImage,
      'passbook_image': passbookImage,
      'addhar_card_front_path': addharCardFrontPath,
      'addhar_card_back_path': addharCardBackPath,
      'pan_card_image_path': panCardImagePath,
      'passbook_image_path': passbookImagePath,
    };
  }
} 