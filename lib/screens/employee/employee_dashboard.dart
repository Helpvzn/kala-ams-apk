import 'package:flutter/material.dart';
import '../../models/attendance.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../login_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  Map<String, String> _employee = {};
  AttendanceModel? _todayRecord;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _employee = await SessionService.getEmployeeData();
    await _fetchTodayRecord();
    setState(() => _loading = false);
  }

  Future<void> _fetchTodayRecord() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      final res = await ApiService.getHistory(_employee['empId'] ?? '', fromDate: dateStr, toDate: dateStr);
      if (res['status'] == 'success') {
        final records = res['records'] as List;
        if (records.isNotEmpty) {
          _todayRecord = AttendanceModel.fromJson(records.first);
        } else {
          // Empty = genuinely no check-in today
          _todayRecord = null;
        }
      }
      // On API error: silently preserve last known state
    } catch (e) {
      // Network error — preserve last known state
    }
  }

  Future<void> _handleCheckInOut(String type) async {
    setState(() => _actionLoading = true);
    try {
      // Open camera to take selfie
      final base64Image = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(title: type == 'checkin' ? 'Check In Selfie' : 'Check Out Selfie'),
        ),
      );

      if (base64Image == null) {
        setState(() => _actionLoading = false);
        return;
      }

      // Upload selfie to Google Drive
      _showSnack('Uploading selfie...', Colors.blue.shade700);
      final uploadRes = await ApiService.uploadSelfie(_employee['empId']!, base64Image, type);
      String photoUrl = '';
      if (uploadRes['status'] == 'success') {
        photoUrl = uploadRes['photoUrl'] ?? '';
      } else {
        _showSnack('Selfie upload failed: ${uploadRes['message']}', Colors.orange.shade700);
      }

      // Perform check-in or check-out
      Map<String, dynamic> res;
      if (type == 'checkin') {
        res = await ApiService.checkIn(_employee['empId']!, photoUrl);
      } else {
        res = await ApiService.checkOut(_employee['empId']!, photoUrl);
      }

      if (res['status'] == 'success') {
        _showSnack(res['message'], Colors.green.shade700);
        // Optimistically update UI immediately before API refresh
        if (type == 'checkin') {
          final now = DateTime.now();
          final timeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          _todayRecord = AttendanceModel(
            attId: res['attId']?.toString() ?? 'temp',
            empId: _employee['empId'] ?? '',
            name: _employee['name'] ?? '',
            date: timeStr.substring(0, 10),
            checkInTime: timeStr,
            checkOutTime: '',
            workingHours: '',
            checkInPhotoUrl: photoUrl,
            checkOutPhotoUrl: '',
            status: 'Checked In',
          );
        } else {
          // For checkout, update local record's checkout time
          if (_todayRecord != null) {
            final now = DateTime.now();
            final timeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
            _todayRecord = AttendanceModel(
              attId: _todayRecord!.attId,
              empId: _todayRecord!.empId,
              name: _todayRecord!.name,
              date: _todayRecord!.date,
              checkInTime: _todayRecord!.checkInTime,
              checkOutTime: timeStr,
              workingHours: res['workingHours']?.toString() ?? '',
              checkInPhotoUrl: _todayRecord!.checkInPhotoUrl,
              checkOutPhotoUrl: photoUrl,
              status: 'Checked Out',
            );
          }
        }
        setState(() {});
        // Then also refresh from server in background
        await _fetchTodayRecord();
        setState(() {});
      } else {
        _showSnack(res['message'], Colors.red.shade700);
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SessionService.clearSession();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  String get _statusText {
    if (_todayRecord == null) return 'Not Checked In';
    if (_todayRecord!.isCheckedOut) return 'Checked Out';
    return 'Checked In';
  }

  Color get _statusColor {
    if (_todayRecord == null) return Colors.orange;
    if (_todayRecord!.isCheckedOut) return Colors.green;
    return const Color(0xFF6C63FF);
  }

  IconData get _statusIcon {
    if (_todayRecord == null) return Icons.access_time;
    if (_todayRecord!.isCheckedOut) return Icons.check_circle;
    return Icons.work;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF6C63FF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    if (_todayRecord != null) _buildTodayDetails(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildHistoryBtn(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9B5DE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employee['name'] ?? 'Employee',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('ID: ${_employee['empId'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('${_employee['designation'] ?? ''} • ${_employee['department'] ?? ''}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final now = DateTime.now();
    final dateStr = '${_dayName(now.weekday)}, ${now.day} ${_monthName(now.month)} ${now.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Status', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_statusText,
                    style: TextStyle(color: _statusColor, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Record', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _timeRow(Icons.login_rounded, 'Check In', _todayRecord!.checkInTime, Colors.green),
          if (_todayRecord!.hasCheckOut) ...[
            const SizedBox(height: 8),
            _timeRow(Icons.logout_rounded, 'Check Out', _todayRecord!.checkOutTime, Colors.orange),
            const SizedBox(height: 8),
            _timeRow(Icons.timer_outlined, 'Working Hours', _todayRecord!.workingHours, const Color(0xFF6C63FF)),
          ],
        ],
      ),
    );
  }

  Widget _timeRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Expanded(
          child: Text(value.isNotEmpty ? value : '--',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Determine state
    final bool notYetCheckedIn = _todayRecord == null;
    final bool checkedInOnly = _todayRecord != null && !_todayRecord!.isCheckedOut;
    final bool fullyDone = _todayRecord != null && _todayRecord!.isCheckedOut;

    if (_actionLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF6C63FF)),
            SizedBox(height: 16),
            Text('Processing... please wait', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }

    if (fullyDone) {
      // Both done — show completion card
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.4), width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.verified_rounded, color: Colors.green, size: 40),
            SizedBox(height: 12),
            Text('Attendance Complete!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 17)),
            SizedBox(height: 4),
            Text('You have checked in and checked out today.',
                style: TextStyle(color: Colors.green, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Step indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _stepDot(1, notYetCheckedIn ? 'pending' : 'done', 'Check In'),
              Expanded(
                child: Container(
                  height: 2,
                  color: notYetCheckedIn ? Colors.white12 : Colors.green.withOpacity(0.5),
                ),
              ),
              _stepDot(2, notYetCheckedIn ? 'pending' : checkedInOnly ? 'active' : 'done', 'Check Out'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Check In button — only if not yet checked in
        if (notYetCheckedIn)
          _actionBtn(
            icon: Icons.login_rounded,
            label: 'Check In',
            subtitle: 'Tap to mark your arrival',
            color: const Color(0xFF4CAF50),
            onTap: () => _handleCheckInOut('checkin'),
          ),

        // Check Out button — only if checked in but not yet out
        if (checkedInOnly)
          _actionBtn(
            icon: Icons.logout_rounded,
            label: 'Check Out',
            subtitle: 'Checked in at ${_todayRecord?.checkInTime.substring(11, 16) ?? '--'}. Tap to mark departure.',
            color: Colors.deepOrange,
            onTap: () => _handleCheckInOut('checkout'),
          ),
      ],
    );
  }

  Widget _stepDot(int step, String state, String label) {
    Color color;
    IconData icon;
    if (state == 'done') {
      color = Colors.green;
      icon = Icons.check;
    } else if (state == 'active') {
      color = const Color(0xFF6C63FF);
      icon = Icons.radio_button_checked;
    } else {
      color = Colors.white24;
      icon = Icons.circle_outlined;
    }
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }



  Widget _actionBtn({
    required IconData icon,
    required String label,
    String? subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }


  Widget _buildHistoryBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HistoryScreen(empId: _employee['empId'] ?? '')),
        ),
        icon: const Icon(Icons.history_rounded, color: Color(0xFF6C63FF)),
        label: const Text('View Attendance History', style: TextStyle(color: Color(0xFF6C63FF))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF6C63FF)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String _dayName(int d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(d - 1).clamp(0, 6)];
  }

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(m - 1).clamp(0, 11)];
  }
}
