import 'dart:convert';
import 'dart:developer';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../models/contractor.dart';
import '../models/designation.dart';
import '../models/department.dart';
import '../models/fair_report_response.dart';
import '../models/site.dart';
import '../models/transporter.dart';
import '../models/transporter_fair.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';
import '../core/utils/snackbar_utils.dart';
import '../screens/auth/login_screen.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/task.dart' hide Tag;
import '../models/payment_data.dart';
import 'package:file_picker/file_picker.dart';
import '../models/tag.dart';
import '../models/reimbursement_data.dart';
import '../models/manpower.dart';

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
  Map<String, dynamic> _handleResponse(
      http.Response response, BuildContext? context) {
    if (response.statusCode == 401) {
      if (context != null) {
        _handleSessionExpired(context);
      }
      throw ApiException('Session expired. Please login again.',
          statusCode: 401);
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
      log("E == $e");

      // Provide more specific error messages
      if (e.toString().contains('PathNotFoundException')) {
        throw ApiException(
          'File path error. Please try again.',
          statusCode: 0,
        );
      } else if (e.toString().contains('FileSystemException')) {
        throw ApiException(
          'File system error. Please try again.',
          statusCode: 0,
        );
      } else {
        throw ApiException(
          'An unexpected error occurred. Please try again.',
          statusCode: 0,
        );
      }
    }
  }

  Future<UserModel> login(String mobile, String password) async {
    // Get device ID
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    // Get FCM token
    String? fcmToken;
    // if (Platform.isIOS) {
    //   String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    //
    //   log("apnsToken == $apnsToken");
    //   if (apnsToken != null) {
    //     fcmToken = await FirebaseMessaging.instance.getToken();
    //   }
    // } else {
    //   fcmToken = await FirebaseMessaging.instance.getToken();
    // }

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
          'fcm_token': "fcmToken",
          'device_id': deviceId,
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
      if (email.isEmpty)
        throw ApiException('Email is required', statusCode: 400);
      if (mobile.isEmpty)
        throw ApiException('Mobile number is required', statusCode: 400);
      if (password.isEmpty)
        throw ApiException('Password is required', statusCode: 400);
      if (designation == 0)
        throw ApiException('Designation is required', statusCode: 400);
      if (subDepartmentId == 0)
        throw ApiException('Department is required', statusCode: 400);
      if (address.isEmpty)
        throw ApiException('Address is required', statusCode: 400);
      if (dateOfBirth.isEmpty)
        throw ApiException('Date of birth is required', statusCode: 400);
      if (gender.isEmpty)
        throw ApiException('Gender is required', statusCode: 400);
      if (emergencyContact.isEmpty)
        throw ApiException('Emergency contact is required', statusCode: 400);

      // Email format validation
      if (!email.contains('@') || !email.contains('.')) {
        throw ApiException('Please enter a valid email address',
            statusCode: 400);
      }

      // Mobile number validation
      if (mobile.length != 10) {
        throw ApiException('Mobile number must be 10 digits', statusCode: 400);
      }

      // Emergency contact validation
      if (emergencyContact.length != 10) {
        throw ApiException('Emergency contact must be 10 digits',
            statusCode: 400);
      }

      // Password length validation
      if (password.length < 6) {
        throw ApiException('Password must be at least 6 characters',
            statusCode: 400);
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
      if (dateOfJoining != null)
        request.fields['date_of_joining'] = dateOfJoining;
      if (bankAccountNo != null && bankAccountNo.isNotEmpty)
        request.fields['bank_account_no'] = bankAccountNo;
      if (bankName != null && bankName.isNotEmpty)
        request.fields['bank_name'] = bankName;
      if (ifscCode != null && ifscCode.isNotEmpty)
        request.fields['ifsc_code'] = ifscCode;
      if (panCardNo != null && panCardNo.isNotEmpty)
        request.fields['pan_card_no'] = panCardNo;
      if (aadharCardNo != null && aadharCardNo.isNotEmpty)
        request.fields['aadhar_card_no'] = aadharCardNo;

      // Add files
      if (profileImagePath != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profile_image', profileImagePath.path));
      }
      if (aadharCardFront != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'addhar_card_front', aadharCardFront.path));
      }
      if (aadharCardBack != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'addhar_card_back', aadharCardBack.path));
      }
      if (panCardImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'pan_card_image', panCardImage.path));
      }
      if (passbookImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'passbook_image', passbookImage.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = _handleResponse(response, context);
      return UserModel.fromJson(data);
    });
  }

  Future<Map<String, dynamic>?> attendanceCheck(
      BuildContext context, String apiToken) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceCheck'),
        body: {'api_token': apiToken},
      );

      log("Attendance response body == ${response.body}");
      log("Attendance response body == ${response.statusCode}");

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
    int? siteId,
  }) async {
    return _handleNetworkCall(() async {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/saveAttendance'));
      request.fields['api_token'] = apiToken;
      request.fields['type'] = type;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      request.fields['address'] = address;
      if (siteId != null) request.fields['site_id'] = siteId.toString();
      if (checkInDescription != null)
        request.fields['check_in_description'] = checkInDescription;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            request.files
                .add(await http.MultipartFile.fromPath('image', imagePath));
          }
        } catch (e) {
          print('Error adding image file: $e');
          // Continue without image if file doesn't exist
        }
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
    int page = 1,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceList'),
        body: {
          'api_token': apiToken,
          'start_date': startDate,
          'end_date': endDate,
          'user_id': userId,
          'page': page.toString(),
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
        throw ApiException('New password and confirm password do not match',
            statusCode: 400);
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
      if (earlyOffStartTime != null)
        body['early_off_start_time'] = earlyOffStartTime;
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
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/applyForEmployeeExpense'));
      request.fields['api_token'] = apiToken;
      request.fields['title'] = title;
      request.fields['amount'] = amount;
      request.fields['description'] = description;
      request.fields['expense_date'] = expenseDate;
      for (var img in images) {
        request.files
            .add(await http.MultipartFile.fromPath('images[]', img.path));
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

  Future<dynamic> employeeExpenseRequestAction({
    required BuildContext context,
    required String apiToken,
    required String expenseId,
    required int approvedAmount,
    required String status,
    String? reason,
  }) async {
    return _handleNetworkCall(() async {
      final body = {
        'api_token': apiToken,
        'approved_amount': approvedAmount.toString(),
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

      log("RES == ${response.body}");

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
    int page = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getMySite'),
        body: {
          'api_token': apiToken,
          'page': page.toString(),
        },
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
      throw ApiException(
          'Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred. Please try again. $e');
    }
  }

  Future<Map<String, dynamic>?> getAllSites({
    required BuildContext context,
    required String apiToken,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/getAllSite'),
        body: {
          'api_token': apiToken,
        },
      );
      return _handleResponse(response, context);
    });
  }

  Future<Map<String, dynamic>?> editOtherUserProfile({
    required BuildContext context,
    required String apiToken,
    required String userId,
    String? siteIds,
    String? detachSiteIds,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/editOtherUserProfile'),
        body: {
          'api_token': apiToken,
          'user_id': userId,
          if (siteIds != null) 'site_ids': siteIds,
          if (detachSiteIds != null) 'detach_site_ids': detachSiteIds,
        },
      );
      return _handleResponse(response, context);
    });
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
    required int minRange,
    required int maxRange,
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
      request.fields['min_range'] = minRange.toString();
      request.fields['max_range'] = maxRange.toString();
      for (var img in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('images[]', img));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log("Create site response == ${response.body}");

      _handleResponse(response, context);
    });
  }

  Future<void> updateSite({
    required BuildContext context,
    required String apiToken,
    required int siteId,
    required String name,
    required String latitude,
    required String longitude,
    required String address,
    required String company,
    required String startDate,
    required String endDate,
    required int minRange,
    required int maxRange,
    required List<String> newImagePaths,
    required List<int> existingImageIds,
  }) async {
    return _handleNetworkCall(() async {
      var uri = Uri.parse('$baseUrl/updateSite');
      var request = http.MultipartRequest('POST', uri);
      request.fields['api_token'] = apiToken;
      request.fields['id'] = siteId.toString();
      request.fields['name'] = name;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      request.fields['address'] = address;
      request.fields['company'] = company;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['min_range'] = minRange.toString();
      request.fields['max_range'] = maxRange.toString();

      for (var img in newImagePaths) {
        request.files.add(await http.MultipartFile.fromPath('images[]', img));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log("Update site response == ${response.body}");

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

  Future<UserModel> createUser({
    required BuildContext context,
    required String name,
    required String mobile,
    required String email,
    required String password,
    required int designationId,
    required int subDepartmentId,
    required int createdBy,
    required int hasKeypadMobile,
    String? address,
    String? dateOfBirth,
    String? gender,
    String? emergencyContact,
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
      // Input validation (only required fields)
      if (name.isEmpty) throw ApiException('Name is required', statusCode: 400);
      if (mobile.isEmpty)
        throw ApiException('Mobile number is required', statusCode: 400);
      if (email.isEmpty)
        throw ApiException('Email is required', statusCode: 400);
      if (password.isEmpty)
        throw ApiException('Password is required', statusCode: 400);
      if (designationId == 0)
        throw ApiException('Designation is required', statusCode: 400);
      if (subDepartmentId == 0)
        throw ApiException('Sub Department is required', statusCode: 400);

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/create-user'));
      request.fields.addAll({
        'name': name,
        'mobile': mobile,
        'email': email,
        'password': password,
        'designation_id': designationId.toString(),
        'sub_department_id': subDepartmentId.toString(),
        'created_by': createdBy.toString(),
        'has_keypad_mobile': hasKeypadMobile.toString(),
      });
      // Add optional fields
      if (address != null && address.isNotEmpty)
        request.fields['address'] = address;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        request.fields['dob'] = dateOfBirth;
      if (gender != null && gender.isNotEmpty)
        request.fields['gender'] = gender;
      if (emergencyContact != null && emergencyContact.isNotEmpty)
        request.fields['emergency_contact'] = emergencyContact;
      if (salary != null) request.fields['salary'] = salary;
      if (dateOfJoining != null)
        request.fields['date_of_joining'] = dateOfJoining;
      if (bankAccountNo != null && bankAccountNo.isNotEmpty)
        request.fields['bank_account_no'] = bankAccountNo;
      if (bankName != null && bankName.isNotEmpty)
        request.fields['bank_name'] = bankName;
      if (ifscCode != null && ifscCode.isNotEmpty)
        request.fields['ifsc_code'] = ifscCode;
      if (panCardNo != null && panCardNo.isNotEmpty)
        request.fields['pan_card_no'] = panCardNo;
      if (aadharCardNo != null && aadharCardNo.isNotEmpty)
        request.fields['aadhar_card_no'] = aadharCardNo;
      // Add files
      if (profileImagePath != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profile_image', profileImagePath.path));
      }
      if (aadharCardFront != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'addhar_card_front', aadharCardFront.path));
      }
      if (aadharCardBack != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'addhar_card_back', aadharCardBack.path));
      }
      if (panCardImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'pan_card_image', panCardImage.path));
      }
      if (passbookImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'passbook_image', passbookImage.path));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = _handleResponse(response, context);
      return UserModel.fromJson(data);
    });
  }

  Future<Site> getUserBySite({
    required BuildContext context,
    required String apiToken,
    required int siteId,
    int? designationId,
    int? hasKeypadMobile,
  }) async {
    final body = {
      'api_token': apiToken,
      'site_id': siteId.toString(),
    };
    if (designationId != null)
      body['designation_id'] = designationId.toString();
    if (hasKeypadMobile != null)
      body['has_keypad_mobile'] = hasKeypadMobile.toString();

    final response = await http.post(
      Uri.parse('$baseUrl/getUserBySite'),
      body: body,
    );
    final data = _handleResponse(response, context);
    return Site.fromJson(data['data']);
  }

  Future<dynamic> attendanceForOtherUser({
    required BuildContext context,
    required String apiToken,
    required String type, // 'check_in' or 'check_out'
    required List<int> userIds,
    required String latitude,
    required String longitude,
    required String address,
    String? checkInDescription,
    int? siteId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/attendanceForOtherUser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'api_token': apiToken,
          'type': type,
          'user_id': userIds,
          'site_id': siteId.toString(),
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'check_in_description': checkInDescription,
        }),
      );

      log("R == ${response.body}");

      _handleResponse(response, context);
    });
  }

  Future<void> deleteSiteImage({
    required BuildContext context,
    required String apiToken,
    required int imageId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/deleteSiteImage'),
        body: {
          'api_token': apiToken,
          'image_id': imageId.toString(),
        },
      );
      _handleResponse(response, context);
    });
  }

  Future<void> pinSite({
    required BuildContext context,
    required String apiToken,
    required int siteId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/pinSite'),
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
        },
      );
      _handleResponse(response, context);
    });
  }

  Future<List<Task>> getTaskList({
    required BuildContext context,
    required String apiToken,
    int page = 1,
    required int siteId,
    int? userId,
    String? status,
    String? tags,
    String? search,
  }) async {
    return _handleNetworkCall(() async {
      log("status = $status");

      final response = await http.post(
        Uri.parse('$baseUrl/getTask'),
        body: {
          'api_token': apiToken,
          'page': page.toString(),
          'site_id': siteId.toString(),
          if (userId != null) 'user_id': userId.toString(),
          if (status != null) 'status': status,
          if (tags != null) 'tags_id': tags,
          if (search != null) 'search': search,
        },
      );
      final data = _handleResponse(response, context);
      final List<dynamic> tasksJson = data['data'] ?? [];
      return tasksJson.map((json) => Task.fromJson(json)).toList();
    });
  }

  Future<Task> getTaskDetail({
    required BuildContext context,
    required String apiToken,
    required int taskId,
  }) async {
    log("Task ID == $taskId");
    log("Task ID == $apiToken");
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/getTaskDetail'),
        body: {
          'api_token': apiToken,
          'task_id': taskId.toString(),
        },
      );
      final data = _handleResponse(response, context);

      return Task.fromJson(data['data']);
    });
  }

  Future<dynamic> createTask({
    required String apiToken,
    required int siteId,
    required String name,
    required String startDate,
    required String endDate,
    required String assignTo,
    required String tags,
    required List<File> taskImages,
    required List<File> taskAttachments,
  }) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/createTask'));
    request.fields['api_token'] = apiToken;
    request.fields['site_id'] = siteId.toString();
    request.fields['name'] = name;
    request.fields['start_date'] = startDate;
    request.fields['end_date'] = endDate;
    request.fields['assign_to'] = assignTo;
    request.fields['tags'] = tags;

    for (var imageFile in taskImages) {
      var file =
          await http.MultipartFile.fromPath("task_images[]", imageFile.path);
      request.files.add(file);
    }
    for (var att in taskAttachments) {
      var file =
          await http.MultipartFile.fromPath("task_attachments[]", att.path);
      request.files.add(file);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _handleResponse(response, null);
    return data;
  }

  Future<List<Tag>> getTags({required String apiToken}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/getTag'),
      body: {'api_token': apiToken},
    );
    final data = _handleResponse(response, null);
    final List<dynamic> tagsJson = data['data'] ?? [];
    return tagsJson.map((json) => Tag.fromJson(json)).toList();
  }

  Future<Tag> addTag({required String apiToken, required String name}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addTag'),
      body: {'api_token': apiToken, 'name': name},
    );
    final data = _handleResponse(response, null);
    return Tag.fromJson(data['data']);
  }

  Future<dynamic> editTask({
    required String apiToken,
    required int siteId,
    required int taskId,
    required String name,
    required String startDate,
    required String endDate,
    required String assignTo,
    required String tags,
    required List<File> taskImages,
    required List<File> taskAttachments,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/editTask'));
    request.fields['api_token'] = apiToken;
    request.fields['site_id'] = siteId.toString();
    request.fields['task_id'] = taskId.toString();
    request.fields['name'] = name;
    request.fields['start_date'] = startDate;
    request.fields['end_date'] = endDate;
    request.fields['assign_to'] = assignTo;
    request.fields['tags'] = tags;

    log("TSK IMAGES == $taskImages");

    for (var imageFile in taskImages) {
      var file =
          await http.MultipartFile.fromPath("task_images[]", imageFile.path);
      request.files.add(file);
    }
    for (var att in taskAttachments) {
      var file =
          await http.MultipartFile.fromPath("task_attachments[]", att.path);
      request.files.add(file);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    log("Response == ${response.body}");

    final data = _handleResponse(response, null);
    return data;
  }

  Future<dynamic> updateTaskProgress({
    required String apiToken,
    required int taskId,
    required String workDone,
    required String workLeft,
    required String unit,
    String? remark,
    List<File>? images,
    List<File>? attachments,
  }) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/updateProgress'));
    request.fields['api_token'] = apiToken;
    request.fields['task_id'] = taskId.toString();
    request.fields['work_done'] = workDone;
    request.fields['unit'] = unit;
    if (remark != null && remark.isNotEmpty) {
      request.fields['remark'] = remark;
    }

    if (images != null) {
      for (var imageFile in images) {
        var file =
            await http.MultipartFile.fromPath("images[]", imageFile.path);
        request.files.add(file);
      }
    }

    if (attachments != null) {
      for (var attachmentFile in attachments) {
        var file = await http.MultipartFile.fromPath(
            "attachments[]", attachmentFile.path);
        request.files.add(file);
      }
    }

    log("Request == ${request.fields}");

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    log("Request == ${response.statusCode}");
    final data = _handleResponse(response, null);
    return data;
  }

  Future<dynamic> approveTaskProgress({
    required String apiToken,
    required int progressId,
    required String action, // 'approve' or 'reject'
    String? remark,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/approveTaskProgress'),
        body: {
          'api_token': apiToken,
          'task_progress_id': progressId.toString(),
          'action': action,
          if (remark != null && remark.isNotEmpty) 'remark': remark,
        },
      );
      return _handleResponse(response, null);
    });
  }

  Future<dynamic> editTaskProgress({
    required String apiToken,
    required int progressId,
    required String workDone,
    String? remark,
    List<File>? images,
    List<File>? attachments,
  }) async {
    return _handleNetworkCall(() async {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/editProgress'));

      request.fields['api_token'] = apiToken;
      request.fields['task_progress_id'] = progressId.toString();
      request.fields['work_done'] = workDone;
      if (remark != null && remark.isNotEmpty) {
        request.fields['remark'] = remark;
      }

      if (images != null) {
        for (var imageFile in images) {
          var file =
              await http.MultipartFile.fromPath("images[]", imageFile.path);
          request.files.add(file);
        }
      }

      if (attachments != null) {
        for (var attachmentFile in attachments) {
          var file = await http.MultipartFile.fromPath(
              "attachments[]", attachmentFile.path);
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, null);
    });
  }

  Future<List<PaymentData>> getPaymentData({
    required BuildContext context,
    required String apiToken,
    required int month,
    required int year,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/mySalaryList'),
        body: {
          'api_token': apiToken,
          'month': month.toString(),
          'year': year.toString(),
        },
      );
      final data = _handleResponse(response, context);
      final List<dynamic> paymentJson = data['data'] ?? [];
      return paymentJson.map((json) => PaymentData.fromJson(json)).toList();
    });
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/forgotPassword'),
        body: {
          'email': email,
        },
      );
      return _handleResponse(response, null);
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String apiToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/resetPassword'),
        body: {
          'api_token': apiToken,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      return _handleResponse(response, null);
    });
  }

  Future<Map<String, dynamic>> getProfile({
    required BuildContext context,
    required String apiToken,
    required String userId,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/getProfile'),
        body: {
          'api_token': apiToken,
          'user_id': userId,
        },
      );
      return _handleResponse(response, context);
    });
  }

  Future<Map<String, dynamic>> editProfile({
    required BuildContext context,
    required String apiToken,
    required int userId,
    required String name,
    required String email,
    required String mobile,
    required String dob,
    required String bankName,
    required String bankAccountNo,
    required String ifscCode,
    required String panCardNo,
    required String aadharCardNo,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/editProfile'),
        body: {
          'api_token': apiToken,
          'user_id': userId.toString(),
          'name': name,
          'email': email,
          'mobile': mobile,
          'dob': dob,
          'bank_name': bankName,
          'bank_account_no': bankAccountNo,
          'ifsc_code': ifscCode,
          'pan_card_no': panCardNo,
          'aadhar_card_no': aadharCardNo,
        },
      );
      return _handleResponse(response, context);
    });
  }

  Future<ReimbursementResponse> getMyReimbursement({
    required BuildContext context,
    required String apiToken,
    required int month,
    required int year,
  }) async {
    return _handleNetworkCall(() async {
      try {
        // Try the primary endpoint first
        final response = await http.post(
          Uri.parse('$baseUrl/getMyReimbursement'),
          body: {
            'api_token': apiToken,
            'month': month.toString(),
            'year': year.toString(),
          },
        );

        // Parse the response directly since this endpoint returns data without wrapper
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return ReimbursementResponse.fromJson(data);
        } else {
          final data = _handleResponse(response, context);
          final reimbursementData = data['data'] ?? data;
          return ReimbursementResponse.fromJson(reimbursementData);
        }
      } catch (e) {
        // Re-throw the actual error for proper debugging
        rethrow;
      }
    });
  }

  // Manpower Management APIs
  Future<Manpower?> getManPower({
    required BuildContext context,
    required String apiToken,
    required int siteId,
    required String date,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/getManPower'),
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'date': date,
        },
      );
      final data = _handleResponse(response, context);

      // Check if data exists, return null if no data found
      if (data['data'] == null || data['data'] == '') {
        return null;
      }

      try {
        return Manpower.fromJson(data['data']);
      } catch (e) {
        log('Error parsing manpower data: $e');
        log('Data received: ${data['data']}');
        throw ApiException('Invalid data format received from server',
            statusCode: 500);
      }
    });
  }

  Future<ManpowerReport> getManPowerReport({
    required BuildContext context,
    required String apiToken,
    required int siteId,
    required String startDate,
    required String endDate,
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/manpowerReport'),
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'start_date': startDate,
          'end_date': endDate,
        },
      );
      final data = _handleResponse(response, context);

      // Handle case where data might be null or empty
      if (data['data'] == null ||
          data['data'] == '' ||
          (data['data'] is List && (data['data'] as List).isEmpty)) {
        return ManpowerReport(
            data: [], message: data['message'] ?? 'No data found');
      }

      try {
        return ManpowerReport.fromJson(data);
      } catch (e) {
        log('Error parsing manpower report data: $e');
        log('Data received: ${data['data']}');
        throw ApiException('Invalid data format received from server',
            statusCode: 500);
      }
    });
  }

  Future<Manpower> storeManPower({
    required BuildContext context,
    required String apiToken,
    required int siteId,
    required String date,
    required int skillWorker,
    required int unskillWorker,
    required int shift,
    required double skillPayPerHead,
    required double unskillPayPerHead,
    required int contactorId
  }) async {
    return _handleNetworkCall(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/storeManPower'),
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'date': date,
          'skill_worker': skillWorker.toString(),
          'unskill_worker': unskillWorker.toString(),
          'shift': shift.toString(),
          'skill_pay_per_head': skillPayPerHead.toString(),
          'unskill_pay_per_head': unskillPayPerHead.toString(),
          'contractor_id' : contactorId.toString()
        },
      );
      final data = _handleResponse(response, context);

      try {
        return Manpower.fromJson(data['data']);
      } catch (e) {
        log('Error parsing stored manpower data: $e');
        log('Data received: ${data['data']}');
        throw ApiException('Invalid data format received from server',
            statusCode: 500);
      }
    });
  }

  Future<List<Transporter>> getTransporterList({
    required BuildContext context,
    required String apiToken,
    int page = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getTransporter'),
        body: {
          'api_token': apiToken,
          'page': page.toString(),
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == 1) {
          final List list = data['data'];
          return list.map((e) => Transporter.fromJson(e)).toList();
        } else {
          throw ApiException(data['message'] ?? 'Transporter loading failed');
        }
      } else if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      } else {
        throw ApiException(
          'Server error occurred. Please try again later.',
          statusCode: response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException(
          'Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred. Please try again. $e');
    }
  }

  Future<void> createTransporter({
    required BuildContext context,
    required String apiToken,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String pancard,
    required String fair,
    required String vehicleType,
    required String company,
  }) async {
    return _handleNetworkCall(() async {
      var uri = Uri.parse('$baseUrl/createTransporter');
      var request = http.MultipartRequest('POST', uri);

      // required fields
      request.fields['api_token'] = apiToken;
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['address'] = address;
      request.fields['pancard'] = pancard;
      request.fields['fair'] = fair;
      request.fields['vehicle_type'] = vehicleType;
      request.fields['company'] = company;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log("Create transporter response == ${response.body}");

      _handleResponse(response, context);
    });
  }

  Future<void> updateTransporter({
    required BuildContext context,
    required String apiToken,
    required int transporterId,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String pancard,
    required String fair,
    required String vehicleType,
    required String company,
  }) async {
    return _handleNetworkCall(() async {
      var uri = Uri.parse('$baseUrl/updateTransporter');
      var request = http.MultipartRequest('POST', uri);

      // Required fields
      request.fields['api_token'] = apiToken;
      request.fields['id'] = transporterId.toString();
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['address'] = address;
      request.fields['pancard'] = pancard;
      request.fields['fair'] = fair;
      request.fields['vehicle_type'] = vehicleType;
      request.fields['company'] = company;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log("Update transporter response == ${response.body}");

      _handleResponse(response, context);
    });
  }

  Future<List<TransporterFair>> getTransporterFairList({
    required BuildContext context,
    required String apiToken,
    required int transporterId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getTransporterFair'),
        body: {
          "api_token": apiToken,
          "transporter_id": transporterId.toString(),
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data["status"] == 1) {
          final List list = data["data"];
          return list.map((e) => TransporterFair.fromJson(e)).toList();
        } else {
          throw ApiException(
              data["message"] ?? "Failed to load transporter fair");
        }
      } else if (response.statusCode == 401) {
        // TODO: handle session expired UI
        throw ApiException("Session expired");
      } else {
        throw ApiException(
          "Server error occurred. Please try again later.",
          statusCode: response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException("Invalid response from server");
    } on http.ClientException {
      throw ApiException(
          "Network error. Please check your internet connection.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("An unexpected error occurred. $e");
    }
  }

  Future<void> storeTransporterFair({
    required BuildContext context,
    required String apiToken,
    required int transporterId,
    required String fair,
    required String date,
    required String toLocation,
    required String fromLocation,
  }) async {
    return _handleNetworkCall(() async {
      var uri = Uri.parse('$baseUrl/storeTransporterFair');
      var request = http.MultipartRequest('POST', uri);

      request.fields['api_token'] = apiToken;
      request.fields['transporter_id'] = transporterId.toString();
      request.fields['fair'] = fair;
      request.fields['date'] = date;
      request.fields['to_location'] = toLocation;
      request.fields['from_location'] = fromLocation;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log("Store Transporter Fair response == ${response.body}");

      _handleResponse(response, context);
    });
  }

  Future<FairReportResponse> getFairReport({
    required BuildContext context,
    required String apiToken,
    required String transporterId,
    required String startDate,
    required String endDate,
  }) async {
    try {

      print('transporter id ::: $transporterId');
      final response = await http.post(
        Uri.parse('$baseUrl/getFairReport'),
        body: {
          "api_token": apiToken,
          "transporter_id": transporterId.toString(),
          "start_date": startDate,
          "end_date": endDate,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data["status"] == 1) {
          return FairReportResponse.fromJson(data);
        } else {
          throw ApiException(data["message"] ?? "Failed to fetch report");
        }
      } else if (response.statusCode == 401) {
        throw ApiException("Session expired");
      } else {
        throw ApiException(
          "Server error occurred. Please try again later.",
          statusCode: response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException("Invalid response from server");
    } on http.ClientException {
      throw ApiException(
          "Network error. Please check your internet connection.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("An unexpected error occurred. $e");
    }
  }

  Future<List<Contractor>> getContractorList({
    required BuildContext context,
    required String apiToken,
    required String siteId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getContractor'),
        body: {
          'api_token': apiToken,
          'site_id': siteId,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == 1) {
          final List list = data['data'];
          return list.map((e) => Contractor.fromJson(e)).toList();
        } else {
          throw ApiException(data['message'] ?? 'Contractor loading failed');
        }
      } else if (response.statusCode == 401) {
        _handleSessionExpired(context);
        throw ApiException('Session expired');
      } else {
        throw ApiException(
          'Server error occurred. Please try again later.',
          statusCode: response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('Invalid response from server');
    } on http.ClientException {
      throw ApiException(
          'Network error. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred. Please try again. $e');
    }
  }



}
