import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      body['key'] = AppConfig.apiKey;

      var url = Uri.parse(AppConfig.apiUrl);
      var response = await _postRaw(url, body);

      // Follow redirects manually up to 5 times (Google Apps Script redirects via 302/307/308)
      int redirectCount = 0;
      while ((response.statusCode == 302 || response.statusCode == 307 || response.statusCode == 308) && redirectCount < 5) {
        final location = response.headers['location'];
        if (location == null || location.isEmpty) break;
        url = Uri.parse(location);
        response = await _postRaw(url, body);
        redirectCount++;
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'status': 'error', 'message': 'Invalid response format'};
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed. Check internet.\n${e.toString()}'};
    }
  }

  static Future<http.Response> _postRaw(Uri url, Map<String, dynamic> body) async {
    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'text/plain'
      ..body = jsonEncode(body)
      ..followRedirects = false; // Handle redirects manually
    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    return await http.Response.fromStream(streamedResponse);
  }

  // ---- AUTH ----
  static Future<Map<String, dynamic>> adminLogin(String username, String password) {
    return _post({'action': 'adminLogin', 'username': username, 'password': password});
  }

  static Future<Map<String, dynamic>> employeeLogin(String empId, String password) {
    return _post({'action': 'employeeLogin', 'empId': empId, 'password': password});
  }

  // ---- EMPLOYEE MANAGEMENT ----
  static Future<Map<String, dynamic>> getProfile(String empId) {
    return _post({'action': 'getProfile', 'empId': empId});
  }

  static Future<Map<String, dynamic>> getAllEmployees() {
    return _post({'action': 'getAllEmployees'});
  }

  static Future<Map<String, dynamic>> addEmployee(Map<String, dynamic> empData) {
    return _post({'action': 'addEmployee', ...empData});
  }

  static Future<Map<String, dynamic>> updateEmployee(Map<String, dynamic> empData) {
    return _post({'action': 'updateEmployee', ...empData});
  }

  static Future<Map<String, dynamic>> deleteEmployee(String empId) {
    return _post({'action': 'deleteEmployee', 'empId': empId});
  }

  static Future<Map<String, dynamic>> toggleEmployee(String empId, String status) {
    return _post({'action': 'toggleEmployee', 'empId': empId, 'status': status});
  }

  static Future<Map<String, dynamic>> resetPassword(String empId, String newPassword) {
    return _post({'action': 'resetPassword', 'empId': empId, 'newPassword': newPassword});
  }

  // ---- ATTENDANCE ----
  static Future<Map<String, dynamic>> uploadSelfie(String empId, String base64Image, String type) {
    return _post({
      'action': 'uploadSelfie',
      'empId': empId,
      'imageBase64': base64Image,
      'type': type,
    });
  }

  static Future<Map<String, dynamic>> checkIn(String empId, String photoUrl) {
    return _post({'action': 'checkIn', 'empId': empId, 'photoUrl': photoUrl});
  }

  static Future<Map<String, dynamic>> checkOut(String empId, String photoUrl) {
    return _post({'action': 'checkOut', 'empId': empId, 'photoUrl': photoUrl});
  }

  static Future<Map<String, dynamic>> getHistory(String empId, {String? fromDate, String? toDate}) {
    return _post({
      'action': 'getHistory',
      'empId': empId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
  }

  // ---- ADMIN ----
  static Future<Map<String, dynamic>> getDashboard() {
    return _post({'action': 'getDashboard'});
  }

  static Future<Map<String, dynamic>> getAllAttendance({String? date, String? empId, String? name}) {
    return _post({
      'action': 'getAllAttendance',
      if (date != null) 'date': date,
      if (empId != null) 'empId': empId,
      if (name != null) 'name': name,
    });
  }

  static Future<Map<String, dynamic>> exportReport(String month) {
    return _post({'action': 'exportReport', 'month': month});
  }

  static Future<Map<String, dynamic>> updateAttendance(
    String attId, {
    String? date,
    String? checkInTime,
    String? checkOutTime,
    String? workingHours,
    String? status,
  }) {
    return _post({
      'action': 'updateAttendance',
      'attId': attId,
      if (date != null) 'date': date,
      if (checkInTime != null) 'checkInTime': checkInTime,
      if (checkOutTime != null) 'checkOutTime': checkOutTime,
      if (workingHours != null) 'workingHours': workingHours,
      if (status != null) 'status': status,
    });
  }

  static Future<Map<String, dynamic>> deleteAttendance(String attId) {
    return _post({
      'action': 'deleteAttendance',
      'attId': attId,
    });
  }
}
