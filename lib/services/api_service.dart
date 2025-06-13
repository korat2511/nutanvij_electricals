import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/designation.dart';
import '../models/department.dart';
import '../models/site.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';
import '../core/utils/snackbar_utils.dart';
import '../screens/auth/login_screen.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'https://nutanvij.com/api';

  void _handleSessionExpired(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false).logout();
    SnackBarUtils.showError(context, 'Session expired. Please login again.');
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  // Helper method to handle common API response parsing and error handling
  Map<String, dynamic> _handleResponse(http.Response response, BuildContext? context) {
    if (response.statusCode == 401) {
      if (context != null) {
        _handleSessionExpired(context);
      }
      throw ApiException('Session expired. Please login again.', statusCode: 401);
    }

    try {
      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == 1) {
          return data;
        } else {
          throw ApiException(
            data['message'] ?? 'Operation failed',
            statusCode: response.statusCode,
            errorCode: data['error_code'],
          );
        }
      } else if (response.statusCode == 400) {
        throw ApiException(
          data['message'] ?? 'Invalid request',
          statusCode: 400,
          errorCode: data['error_code'],
        );
      } else if (response.statusCode == 403) {
        throw ApiException(
          data['message'] ?? 'Access denied',
          statusCode: 403,
          errorCode: data['error_code'],
        );
      } else if (response.statusCode == 404) {
        throw ApiException(
          data['message'] ?? 'Resource not found',
          statusCode: 404,
          errorCode: data['error_code'],
        );
      } else if (response.statusCode == 409) {
        throw ApiException(
          data['message'] ?? 'Conflict occurred',
          statusCode: 409,
          errorCode: data['error_code'],
        );
      } else if (response.statusCode == 422) {
        throw ApiException(
          data['message'] ?? 'Validation failed',
          statusCode: 422,
          errorCode: data['error_code'],
        );
      } else if (response.statusCode == 429) {
        throw ApiException(
          data['message'] ?? 'Too many requests',
          statusCode: 429,
          errorCode: data['error_code'],
        );
      } else if (response.statusCode >= 500) {
        throw ApiException(
          data['message'] ?? 'Server error occurred',
          statusCode: response.statusCode,
          errorCode: data['error_code'],
        );
      } else {
        throw ApiException(
          data['message'] ?? 'Unknown error occurred',
          statusCode: response.statusCode,
          errorCode: data['error_code'],
        );
      }
    } on FormatException {
      throw ApiException(
        'Invalid response format from server',
        statusCode: response.statusCode,
      );
    }
  }

  // Helper method to handle network errors
  Future<T> _handleNetworkCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on http.ClientException {
      throw ApiException(
        'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'An unexpected error occurred. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<UserModel> login(String mobile, String password) async {
    return _handleNetworkCall(() async {
      if (mobile.isEmpty) {
        throw ApiException('Mobile number is required', statusCode: 400);
      }
      if (password.isEmpty) {
        throw ApiException('Password is required', statusCode: 400);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {
          'mobile': mobile,
          'password': password,
        },
      );

      final data = _handleResponse(response, null);
      return UserModel.fromJson(data);
    });
  }

  Future<List<Designation>> getDesignations() async {
    return _handleNetworkCall(() async {
      final response = await http.get(Uri.parse('$baseUrl/getDesignations'));
      final data = _handleResponse(response, null);

          final List<dynamic> designationsJson = data['data'] ?? [];
          return designationsJson
              .where((json) => json['status'] == 'Active')
              .map((json) => Designation.fromJson(json))
              .toList();
    });
    }

  Future<UserModel> signup({
    required BuildContext context,
    required String name,
    required String email,
    required String mobile,
    required String password,
    required int designation,
    // required int department,
    required int subDepartmentId,
    required String address,
    required String dateOfBirth,
    required String gender,
    required String emergencyContact,
    File? profileImagePath,
    String? bankAccountNo,
    String? bankName,
    String? ifscCode,
    String? panCardNo,
    String? aadharCardNo,
    File? aadharCardFront,
    File? aadharCardBack,
    File? panCardImage,
    File? passbookImage,
    String? salary,
    String? dateOfJoining,
  }) async {
    return _handleNetworkCall(() async {
      // Input validation
      if (name.isEmpty) throw ApiException('Name is required', statusCode: 400);
      if (email.isEmpty) throw ApiException('Email is required', statusCode: 400);
      if (mobile.isEmpty) throw ApiException('Mobile number is required', statusCode: 400);
      if (password.isEmpty) throw ApiException('Password is required', statusCode: 400);
      if (designation == 0) throw ApiException('Designation is required', statusCode: 400);
      if (subDepartmentId == 0) throw ApiException('Department is required', statusCode: 400);
      if (address.isEmpty) throw ApiException('Address is required', statusCode: 400);
      if (dateOfBirth.isEmpty) throw ApiException('Date of birth is required', statusCode: 400);
      if (gender.isEmpty) throw ApiException('Gender is required', statusCode: 400);
      if (emergencyContact.isEmpty) throw ApiException('Emergency contact is required', statusCode: 400);

      // Email format validation
      if (!email.contains('@') || !email.contains('.')) {
        throw ApiException('Please enter a valid email address', statusCode: 400);
      }

      // Mobile number validation
      if (mobile.length != 10) {
        throw ApiException('Mobile number must be 10 digits', statusCode: 400);
      }

      // Emergency contact validation
      if (emergencyContact.length != 10) {
        throw ApiException('Emergency contact must be 10 digits', statusCode: 400);
      }

      // Password length validation
      if (password.length < 6) {
        throw ApiException('Password must be at least 6 characters', statusCode: 400);
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/signUp'));
      
      // Add text fields
      request.fields.addAll({
        'name': name,
        'mobile': mobile,
        'email': email,
        'password': password,
        'designation_id': designation.toString(),
        'sub_department_id': subDepartmentId.toString(),
        'address': address,
        'dob': dateOfBirth,
        'gender': gender,
        'emergency_contact': emergencyContact,
      });

      // Add optional fields
      if (salary != null) request.fields['salary'] = salary;
      if (dateOfJoining != null) request.fields['date_of_joining'] = dateOfJoining;
      if (bankAccountNo != null && bankAccountNo.isNotEmpty) request.fields['bank_account_no'] = bankAccountNo;
      if (bankName != null && bankName.isNotEmpty) request.fields['bank_name'] = bankName;
      if (ifscCode != null && ifscCode.isNotEmpty) request.fields['ifsc_code'] = ifscCode;
      if (panCardNo != null && panCardNo.isNotEmpty) request.fields['pan_card_no'] = panCardNo;
      if (aadharCardNo != null && aadharCardNo.isNotEmpty) request.fields['aadhar_card_no'] = aadharCardNo;

      // Add files
      if (profileImagePath != null) {
        request.files.add(await http.MultipartFile.fromPath('profile_image', profileImagePath.path));
      }
      if (aadharCardFront != null) {
        request.files.add(await http.MultipartFile.fromPath('addhar_card_front', aadharCardFront.path));
      }
      if (aadharCardBack != null) {
        request.files.add(await http.MultipartFile.fromPath('addhar_card_back', aadharCardBack.path));
      }
      if (panCardImage != null) {
        request.files.add(await http.MultipartFile.fromPath('pan_card_image', panCardImage.path));
      }
      if (passbookImage != null) {
        request.files.add(await http.MultipartFile.fromPath('passbook_image', passbookImage.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = _handleResponse(response, context);
        return UserModel.fromJson(data);
    });
  }

  Future<Map<String, dynamic>?> attendanceCheck(BuildContext context, String apiToken) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceCheck'),
        body: {'api_token': apiToken},
      );
      return _handleResponse(response, context);
    });
  }

  Future<void> saveAttendance({
    required BuildContext context,
    required String apiToken,
    required String type,
    required String latitude,
    required String longitude,
    required String address,
    String? checkInDescription,
    String? imagePath,
  }) async {
    return _handleNetworkCall(() async {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/saveAttendance'));
      request.fields['api_token'] = apiToken;
      request.fields['type'] = type;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      request.fields['address'] = address;
      if (checkInDescription != null) request.fields['check_in_description'] = checkInDescription;
      if (imagePath != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      _handleResponse(response, context);
    });
  }

  Future<List<Map<String, dynamic>>> getAttendanceList({
    required BuildContext context,
    required String apiToken,
    required String startDate,
    required String endDate,
    required String userId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceList'),
        body: {
          'api_token': apiToken,
          'start_date': startDate,
          'end_date': endDate,
          'user_id': userId,
        },
      );
      final data = _handleResponse(response, context);
          return List<Map<String, dynamic>>.from(data['data']);
    });
  }

  Future<Map<String, dynamic>> requestForChangeTime({
    required BuildContext context,
    required String apiToken,
    required String attendanceId,
    required String type,
    required String time,
    required String reason,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/requestForChangeTime'),
        body: {
        'api_token': apiToken,
        'attendance_id': attendanceId,
        'type': type,
        'time': time,
        'reason': reason,
        },
      );
      return _handleResponse(response, context);
    });
  }

  Future<List<Map<String, dynamic>>> getEditAttendanceRequestList({
    required BuildContext context,
    required String apiToken,
    required String startDate,
    required String endDate,
    required String status,
    required String userId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/requestForChangeTimeList'),
        body: {
          'api_token': apiToken,
          'start_date': startDate,
          'end_date': endDate,
          'status': status,
          'user_id': userId,
        },
      );
      final data = _handleResponse(response, context);
        return List<Map<String, dynamic>>.from(data['data']);
    });
  }

  Future<void> attendanceChangeTimeAction({
    required BuildContext context,
    required String apiToken,
    required String attendanceUpdateRequestId,
    required String status,
    String? reason,
  }) async {
    return _handleNetworkCall(() async {
      final body = {
        'api_token': apiToken,
        'attendance_update_request_id': attendanceUpdateRequestId,
        'status': status,
      };
      if (reason != null && reason.isNotEmpty) {
        body['admin_reason'] = reason;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceChangeTimeAction'),
        body: body,
      );
      _handleResponse(response, context);
    });
  }

  Future<List<Map<String, dynamic>>> getAttendanceRequestList({
    required BuildContext context,
    required String apiToken,
    required String startDate,
    required String endDate,
    required String userId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceRequestList'),
        body: {
        'api_token': apiToken,
        'start_date': startDate,
        'end_date': endDate,
        'user_id': userId,
        },
      );
      final data = _handleResponse(response, context);
        return List<Map<String, dynamic>>.from(data['data']);
    });
  }

  Future<void> attendanceRequestAction({
    required BuildContext context,
    required String apiToken,
    required String attendanceId,
    required String status,
    String? reason,
  }) async {
    return _handleNetworkCall(() async {
      final body = {
        'api_token': apiToken,
        'attendance_id': attendanceId,
        'status': status,
      };
      if (reason != null && reason.isNotEmpty) {
        body['admin_reason'] = reason;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceRequestAction'),
        body: body,
      );
      _handleResponse(response, context);
    });
  }

  Future<List<Map<String, dynamic>>> getUserList({
    required BuildContext context,
    required String apiToken,
    String search = '',
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/userlist'),
        body: {
          'api_token': apiToken,
          'search': search,
        },
      );
      final data = _handleResponse(response, context);
        return List<Map<String, dynamic>>.from(data['data']);
    });
  }

  Future<List<Department>> getDepartments() async {
    return _handleNetworkCall(() async {
      final response = await http.get(Uri.parse('$baseUrl/getDepartment'));
      final data = _handleResponse(response, null);
          final List<dynamic> departmentsJson = data['data'] ?? [];
      return departmentsJson.map((json) => Department.fromJson(json)).toList();
    });
  }

  Future<void> cancelChangeTimeRequest({
    required BuildContext context,
    required String apiToken,
    required String attendanceUpdateRequestId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/cancelChangeTimeRequest'),
        body: {
          'api_token': apiToken,
          'attendance_update_request_id': attendanceUpdateRequestId,
        },
      );
      _handleResponse(response, context);
    });
  }

  Future<void> changePassword({
    required BuildContext context,
    required String apiToken,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _handleNetworkCall(() async {
      if (newPassword != confirmPassword) {
        throw ApiException('New password and confirm password do not match', statusCode: 400);
      }
      final response = await http.post(
        Uri.parse('$baseUrl/changePassword'),
        body: {
        'api_token': apiToken,
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
        },
      );
      _handleResponse(response, context);
    });
  }

  Future<List<Map<String, dynamic>>> getLeaveList({
    required BuildContext context,
    required String apiToken,
    String? userId,
  }) async {
    return _handleNetworkCall(() async {
    final body = {
      'api_token': apiToken,
    };
    if (userId != null) body['user_id'] = userId;
    final response = await http.post(
      Uri.parse('$baseUrl/leaveList'),
      body: body,
    );
      final data = _handleResponse(response, context);
      return List<Map<String, dynamic>>.from(data['data']);
    });
  }

  Future<void> leaveRequestAction({
    required BuildContext context,
    required String apiToken,
    required String leaveId,
    required String status,
    String? reason,
  }) async {
    return _handleNetworkCall(() async {
      final body = {
        'api_token': apiToken,
        'leave_id': leaveId,
        'status': status,
      };
      if (reason != null && reason.isNotEmpty) {
        body['admin_reason'] = reason;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/leaveRequestAction'),
        body: body,
      );
      _handleResponse(response, context);
    });
  }

  Future<void> applyForLeave({
    required BuildContext context,
    required String apiToken,
    required String leaveType,
    required String duration,
    required String startDate,
    required String endDate,
    required String reason,
    String? earlyOffStartTime,
    String? earlyOffEndTime,
    String? halfDaySession,
  }) async {
    return _handleNetworkCall(() async {
      final body = {
        'api_token': apiToken,
        'leave_type': leaveType,
        'duration': duration,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      };
      if (earlyOffStartTime != null) body['early_off_start_time'] = earlyOffStartTime;
      if (earlyOffEndTime != null) body['early_off_end_time'] = earlyOffEndTime;
      if (halfDaySession != null) body['half_day_session'] = halfDaySession;
      final response = await http.post(
        Uri.parse('$baseUrl/applyForLeave'),
        body: body,
      );
      _handleResponse(response, context);
    });
  }

  Future<void> cancelLeaveRequest({
    required BuildContext context,
    required String apiToken,
    required String leaveId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/cancelLeave'),
        body: {
          'api_token': apiToken,
          'leave_id': leaveId,
        },
      );
      _handleResponse(response, context);
    });
  }

  Future<void> applyForEmployeeExpense({
    required BuildContext context,
    required String apiToken,
    required String title,
    required String amount,
    required String description,
    required String expenseDate,
    required List<dynamic> images,
  }) async {
    return _handleNetworkCall(() async {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/applyForEmployeeExpense'));
      request.fields['api_token'] = apiToken;
      request.fields['title'] = title;
      request.fields['amount'] = amount;
      request.fields['description'] = description;
      request.fields['expense_date'] = expenseDate;
      for (var img in images) {
        request.files.add(await http.MultipartFile.fromPath('images[]', img.path));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      _handleResponse(response, context);
    });
  }

  Future<List<Map<String, dynamic>>> getEmployeeExpenseList({
    required BuildContext context,
    required String apiToken,
    String? userId,
  }) async {
    return _handleNetworkCall(() async {
    final body = {
      'api_token': apiToken,
    };
    if (userId != null) body['user_id'] = userId;
    final response = await http.post(
      Uri.parse('$baseUrl/employeeExpenseList'),
      body: body,
    );
      final data = _handleResponse(response, context);
      return List<Map<String, dynamic>>.from(data['data']);
    });
  }

  Future<void> employeeExpenseRequestAction({
    required BuildContext context,
    required String apiToken,
    required String expenseId,
    required String status,
    String? reason,
  }) async {
    return _handleNetworkCall(() async {
      final body = {
        'api_token': apiToken,
        'employee_expense_id': expenseId,
        'status': status,
      };
      if (reason != null && reason.isNotEmpty) {
        body['admin_reason'] = reason;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/employeeExpenseRequestAction'),
        body: body,
      );
      _handleResponse(response, context);
    });
  }

  Future<void> employeeExpenseCancel({
    required BuildContext context,
    required String apiToken,
    required String expenseId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/employeeExpenseCancel'),
        body: {
        'api_token': apiToken,
        'employee_expense_id': expenseId,
        },
      );
      _handleResponse(response, context);
    });
  }

  Future<List<Site>> getSiteList({
    required BuildContext context,
    required String apiToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getMySite'),
        body: {'api_token': apiToken},
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == 1) {
          final List sites = data['data'];
          return sites.map((e) => Site.fromJson(e)).toList();
        } else {
          throw ApiException(data['message'] ?? 'Site loading failed');
        }
      } else if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      } else {
        throw ApiException('Server error occurred. Please try again later.',
            statusCode: response.statusCode);
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred. Please try again. $e');
    }
  }

  Future<void> createSite({
    required BuildContext context,
    required String apiToken,
    required String name,
    required String latitude,
    required String longitude,
    required String address,
    required String company,
    required String startDate,
    required String endDate,
    required List<String> imagePaths,
  }) async {
    return _handleNetworkCall(() async {
      var uri = Uri.parse('$baseUrl/createSite');
      var request = http.MultipartRequest('POST', uri);
      request.fields['api_token'] = apiToken;
      request.fields['name'] = name;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      request.fields['address'] = address;
      request.fields['company'] = company;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      for (var img in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('images[]', img));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);


      log("Create site response == ${response.body}");

      _handleResponse(response, context);
    });
  }

  Future<void> assignUserToSite({
    required BuildContext context,
    required String apiToken,
    required int siteId,
    required int userId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/assignUser'),
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'user_id': userId.toString(),
        },
      );
      _handleResponse(response, context);
    });
  }

  Future<void> removeUserFromSite({
    required BuildContext context,
    required String apiToken,
    required int siteId,
    required int userId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/removeUserFromSite'),
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'user_id': userId.toString(),
        },
      );
      _handleResponse(response, context);
    });
  }

} 