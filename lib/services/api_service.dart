import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/designation.dart';
import '../models/department.dart';
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

  ApiException(this.message, {this.statusCode});

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

  Future<UserModel> login(String mobile, String password) async {
    try {
      if (mobile.isEmpty) {
        throw ApiException('Mobile number is required');
      }
      if (password.isEmpty) {
        throw ApiException('Password is required');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {
          'mobile': mobile,
          'password': password,
        },
      );

      final Map<String, dynamic> data = json.decode(response.body);

      // Check for API error response
      if (data['status'] == 0) {
        throw ApiException(data['message'] ?? 'Login failed');
      }

      if (response.statusCode == 200) {
        return UserModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw ApiException('Invalid credentials');
      } else if (response.statusCode == 403) {
        throw ApiException('Account is locked. Please contact support.');
      } else if (response.statusCode == 429) {
        throw ApiException('Too many login attempts. Please try again later.');
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
      throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  Future<List<Designation>> getDesignations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getDesignations'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 1 && data['message'] == 'success') {
          final List<dynamic> designationsJson = data['data'] ?? [];
          return designationsJson
              .where((json) => json['status'] == 'Active')
              .map((json) => Designation.fromJson(json))
              .toList();
        } else {
          throw ApiException('Failed to load designations');
        }
      } else {
        throw ApiException('Failed to load designations', 
          statusCode: response.statusCode);
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred. Please try again.');
    }
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

    try {
      // Input validation
      if (name.isEmpty) throw ApiException('Name is required');
      if (email.isEmpty) throw ApiException('Email is required');
      if (mobile.isEmpty) throw ApiException('Mobile number is required');
      if (password.isEmpty) throw ApiException('Password is required');
      if (designation == 0) throw ApiException('Designation is required');
      if (subDepartmentId == 0) throw ApiException('Department is required');
      if (address.isEmpty) throw ApiException('Address is required');
      if (dateOfBirth.isEmpty) throw ApiException('Date of birth is required');
      if (gender.isEmpty) throw ApiException('Gender is required');
      if (emergencyContact.isEmpty) throw ApiException('Emergency contact is required');

      // Email format validation
      if (!email.contains('@') || !email.contains('.')) {
        throw ApiException('Please enter a valid email address');
      }

      // Mobile number validation
      if (mobile.length != 10) {
        throw ApiException('Mobile number must be 10 digits');
      }

      // Emergency contact validation
      if (emergencyContact.length != 10) {
        throw ApiException('Emergency contact must be 10 digits');
      }

      // Password length validation
      if (password.length < 6) {
        throw ApiException('Password must be at least 6 characters');
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
      if (salary != null) request.fields['salary'] = salary;
      if (dateOfJoining != null) request.fields['date_of_joining'] = dateOfJoining;
      if (bankAccountNo != null && bankAccountNo.isNotEmpty) request.fields['bank_account_no'] = bankAccountNo;
      if (bankName != null && bankName.isNotEmpty) request.fields['bank_name'] = bankName;
      if (ifscCode != null && ifscCode.isNotEmpty) request.fields['ifsc_code'] = ifscCode;
      if (panCardNo != null && panCardNo.isNotEmpty) request.fields['pan_card_no'] = panCardNo;
      if (aadharCardNo != null && aadharCardNo.isNotEmpty) request.fields['aadhar_card_no'] = aadharCardNo;

      // Print all request parameters for debugging
      log('===== SIGNUP REQUEST PARAMETERS =====');
      request.fields.forEach((key, value) {
        log('$key: $value');
      });
      log('===================================');

      // Add profile image if provided
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


      log("RES == ${response.body}");

      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }

      final Map<String, dynamic> data = json.decode(response.body);
      
      // Check for API error response
      if (data['status'] == 0) {
        throw ApiException(data['message'] ?? 'Failed to sign up');
      }

      if (response.statusCode == 200) {
        return UserModel.fromJson(data);
      } else if (response.statusCode == 409) {
        throw ApiException('Mobile number or email already exists');
      } else {
        throw ApiException('Failed to sign up. Please try again.', 
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

  Future<Map<String, dynamic>?> attendanceCheck(BuildContext context, String apiToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceCheck'),
        body: {'api_token': apiToken},
      );


      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1) {
          return data;
        } else {
          throw ApiException('Attendance check failed');
        }
      } else {
        throw ApiException('Attendance check failed', statusCode: response.statusCode);
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred during attendance check.');
    }
  }

  Future<void> saveAttendance({
    required BuildContext context,
    required String apiToken,
    required String type, // 'check_in' or 'check_out'
    required String latitude,
    required String longitude,
    required String address,
    String? checkInDescription,
    String? imagePath,
  }) async {
    try {
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
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] != 1) {
          throw ApiException(data['message'] ?? 'Attendance failed');
        }
      } else {
        throw ApiException('Attendance failed', statusCode: response.statusCode);
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred during attendance save.');
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceList({
    required BuildContext context,
    required String apiToken,
    required String startDate,
    required String endDate,
    required String userId,
  }) async
  {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceList'),
        body: {
          'api_token': apiToken,
          'start_date': startDate,
          'end_date': endDate,
          'user_id' : userId,
        },
      );
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1 && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw ApiException('Failed to fetch attendance list');
        }
      } else {
        throw ApiException('Failed to fetch attendance list', statusCode: response.statusCode);
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while fetching attendance list.');
    }
  }

  Future<Map<String, dynamic>> requestForChangeTime({
    required BuildContext context,
    required String apiToken,
    required String attendanceId,
    required String type, // 'check_in' or 'check_out'
    required String time, // e.g. '10:00:00'
    required String reason,
  }) async
  {
    try {
      final body = {
        'api_token': apiToken,
        'attendance_id': attendanceId,
        'type': type,
        'time': time,
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/requestForChangeTime'),
        body: body,
      );
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return data;
      } else {
        throw ApiException(data['message'] ?? 'Failed to request change time');
      }
    }on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while requesting change time.');
    }
  }

  Future<List<Map<String, dynamic>>> getEditAttendanceRequestList({
    required BuildContext context,
    required String apiToken,
    required String startDate,
    required String endDate,
    required String status, // e.g. 'Pending, Approved'
    required String userId,
  }) async
  {
    try {
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
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1 && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Failed to fetch edit attendance requests');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    }catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while fetching edit attendance requests.');
    }
  }

  Future<void> attendanceChangeTimeAction({
    required BuildContext context,
    required String apiToken,
    required String attendanceUpdateRequestId,
    required String status,
    String? reason,
  }) async
  {
    try {
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
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to update request');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while updating request.');
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceRequestList({
    required BuildContext context,
    required String apiToken,
    required String startDate,
    required String endDate,
    required String userId,
  }) async
  {
    try {


      final body = {
        'api_token': apiToken,
        'start_date': startDate,
        'end_date': endDate,
        'user_id': userId,
      };



          final response = await http.post(
        Uri.parse('$baseUrl/attendanceRequestList'),
        body: body,
      );
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1 && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Failed to fetch attendance change requests');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while fetching attendance change requests.');
    }
  }

  Future<void> attendanceRequestAction({
    required BuildContext context,
    required String apiToken,
    required String attendanceId,
    required String status,
    String? reason,
  }) async
  {
    try {
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
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to update attendance request');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while updating attendance request.');
    }
  }

  Future<List<Map<String, dynamic>>> getUserList({
    required BuildContext context,
    required String apiToken,
    String search = '',
  }) async
  {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/userlist'),
        body: {
          'api_token': apiToken,
          'search': search,
        },
      );
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1 && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Failed to fetch user list');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while fetching user list.');
    }
  }

  Future<List<Department>> getDepartments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getDepartment'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 1 && data['message'] == 'success') {
          final List<dynamic> departmentsJson = data['data'] ?? [];
          return departmentsJson
              .map((json) => Department.fromJson(json))
              .toList();
        } else {
          throw ApiException('Failed to load departments');
        }
      } else {
        throw ApiException('Failed to load departments', 
          statusCode: response.statusCode);
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> cancelChangeTimeRequest({
    required BuildContext context,
    required String apiToken,
    required String attendanceUpdateRequestId,
  }) async {
    try {
      final body = {
        'api_token': apiToken,
        'attendance_update_request_id': attendanceUpdateRequestId,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/cancelChangeTimeRequest'),
        body: body,
      );
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to cancel request');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while cancelling request.');
    }
  }

  Future<void> changePassword({
    required BuildContext context,
    required String apiToken,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final body = {
        'api_token': apiToken,
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/changePassword'),
        body: body,
      );
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to change password');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while changing password.');
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveList({
    required BuildContext context,
    required String apiToken,
    String? userId, // null for admin (all users)
  }) async {
    final body = {
      'api_token': apiToken,
    };
    if (userId != null) body['user_id'] = userId;
    final response = await http.post(
      Uri.parse('$baseUrl/leaveList'),
      body: body,
    );
    if (response.statusCode == 401) {
      _handleSessionExpired(context);
      throw ApiException('Session expired');
    }
    final Map<String, dynamic> data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 1 && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw ApiException(data['message'] ?? 'Failed to fetch leave list');
    }
  }

  Future<void> leaveRequestAction({
    required BuildContext context,
    required String apiToken,
    required String leaveId,
    required String status,
    String? reason,
  }) async {
    try {
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
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to update leave request');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while updating leave request.');
    }
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
    try {
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
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to apply for leave');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while applying for leave.');
    }
  }

  Future<void> cancelLeaveRequest({
    required BuildContext context,
    required String apiToken,
    required String leaveId,
  }) async {
    try {
      final body = {
        'api_token': apiToken,
        'leave_id': leaveId,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/cancelLeave'),
        body: body,
      );
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to cancel request');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while cancelling request.');
    }
  }

  Future<void> applyForEmployeeExpense({
    required BuildContext context,
    required String apiToken,
    required String title,
    required String amount,
    required String description,
    required String expenseDate,
    required List<dynamic> images, // List<XFile>
  }) async {
    try {
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
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to apply for expense');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while applying for expense.');
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeeExpenseList({
    required BuildContext context,
    required String apiToken,
    String? userId, // null for admin (all users)
  }) async {
    final body = {
      'api_token': apiToken,
    };
    if (userId != null) body['user_id'] = userId;
    final response = await http.post(
      Uri.parse('$baseUrl/employeeExpenseList'),
      body: body,
    );
    if (response.statusCode == 401) {
      _handleSessionExpired(context);
      throw ApiException('Session expired');
    }
    final Map<String, dynamic> data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 1 && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw ApiException(data['message'] ?? 'Failed to fetch expense list');
    }
  }

  Future<void> employeeExpenseRequestAction({
    required BuildContext context,
    required String apiToken,
    required String expenseId,
    required String status,
    String? reason,
  }) async {
    try {
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
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to update expense request');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while updating expense request.');
    }
  }

  Future<void> employeeExpenseCancel({
    required BuildContext context,
    required String apiToken,
    required String expenseId,
  }) async {
    try {
      final body = {
        'api_token': apiToken,
        'employee_expense_id': expenseId,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/employeeExpenseCancel'),
        body: body,
      );
      if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return;
      } else {
        throw ApiException(data['message'] ?? 'Failed to cancel expense request');
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while cancelling expense request.');
    }
  }

} 