import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyUserType = 'userType'; // 'employee' or 'admin'
  static const _keyEmpId = 'empId';
  static const _keyEmpName = 'empName';
  static const _keyEmpMobile = 'empMobile';
  static const _keyEmpDept = 'empDept';
  static const _keyEmpDesignation = 'empDesignation';
  static const _keyAdminUsername = 'adminUsername';

  static Future<void> saveEmployeeSession({
    required String empId,
    required String name,
    required String mobile,
    required String department,
    required String designation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserType, 'employee');
    await prefs.setString(_keyEmpId, empId);
    await prefs.setString(_keyEmpName, name);
    await prefs.setString(_keyEmpMobile, mobile);
    await prefs.setString(_keyEmpDept, department);
    await prefs.setString(_keyEmpDesignation, designation);
  }

  static Future<void> saveAdminSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserType, 'admin');
    await prefs.setString(_keyAdminUsername, username);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);
  }

  static Future<Map<String, String>> getEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'empId': prefs.getString(_keyEmpId) ?? '',
      'name': prefs.getString(_keyEmpName) ?? '',
      'mobile': prefs.getString(_keyEmpMobile) ?? '',
      'department': prefs.getString(_keyEmpDept) ?? '',
      'designation': prefs.getString(_keyEmpDesignation) ?? '',
    };
  }

  static Future<String?> getAdminUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAdminUsername);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
