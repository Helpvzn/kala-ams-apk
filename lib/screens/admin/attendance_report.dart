import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/attendance.dart';
import '../../services/api_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<AttendanceModel> _records = [];
  bool _loading = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetch({String? date, String? empId}) async {
    setState(() => _loading = true);
    final res = await ApiService.getAllAttendance(
      date: date ?? _selectedDate,
      empId: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    if (res['status'] == 'success') {
      final list = res['records'] as List;
      _records = list.map((j) => AttendanceModel.fromJson(j)).toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF6C63FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
      _fetch();
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final res = await ApiService.exportReport(month);
    setState(() => _loading = false);
    if (res['status'] == 'success') {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Export Ready', style: TextStyle(color: Colors.white)),
          content: const Text(
            'CSV data is ready. In production, this can be saved to a file or shared. Copy the data from the Apps Script.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Export failed'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by Employee ID or Name...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                              _fetch();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    if (v.length >= 3 || v.isEmpty) _fetch();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Color(0xFF6C63FF), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate ?? 'Filter by Date',
                                style: TextStyle(
                                  color: _selectedDate != null ? Colors.white : Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedDate = null);
                          _fetch();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                          child: const Text('Clear', style: TextStyle(color: Colors.orange, fontSize: 13)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _exportCsv,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.download, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text('Export', style: TextStyle(color: Colors.green, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Records count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text('${_records.length} records', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white38, size: 18),
                  onPressed: _fetch,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                : _records.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 56, color: Colors.white24),
                            SizedBox(height: 12),
                            Text('No records found', style: TextStyle(color: Colors.white38, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _records.length,
                        itemBuilder: (_, i) => _buildCard(_records[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AttendanceModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: a.isCheckedOut ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
            child: Text(
              a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(a.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('${a.empId} • ${a.date}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (a.isCheckedOut ? Colors.green : Colors.orange).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              a.status,
              style: TextStyle(
                color: a.isCheckedOut ? Colors.green : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(Icons.login, 'Check In', a.checkInTime, Colors.green),
                  const SizedBox(height: 6),
                  _row(Icons.logout, 'Check Out', a.checkOutTime.isEmpty ? '--' : a.checkOutTime, Colors.orange),
                  const SizedBox(height: 6),
                  _row(Icons.timer, 'Working Hours', a.workingHours.isEmpty ? '--' : a.workingHours, const Color(0xFF6C63FF)),
                  if (a.checkInPhotoUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Check-In Selfie', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 6),
                    _photo(a.checkInPhotoUrl),
                  ],
                  if (a.checkOutPhotoUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Check-Out Selfie', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 6),
                    _photo(a.checkOutPhotoUrl),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _editRecord(a),
                        icon: const Icon(Icons.edit, size: 14, color: Colors.blue),
                        label: const Text('Edit', style: TextStyle(color: Colors.blue, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _deleteRecordConfirm(a),
                        icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Expanded(child: Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _photo(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 100,
          color: Colors.white12,
          child: const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 100,
          color: Colors.white12,
          child: const Icon(Icons.broken_image, color: Colors.white24),
        ),
      ),
    );
  }

  void _editRecord(AttendanceModel a) {
    final checkInCtrl = TextEditingController(text: a.checkInTime);
    final checkOutCtrl = TextEditingController(text: a.checkOutTime);
    final dateCtrl = TextEditingController(text: a.date);
    String status = a.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Edit Attendance Record', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Date (yyyy-MM-dd)',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: checkInCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Check In Time (yyyy-MM-dd HH:mm:ss)',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: checkOutCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Check Out Time (yyyy-MM-dd HH:mm:ss)',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      dropdownColor: const Color(0xFF1A1A2E),
                      value: status,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'Checked In', child: Text('Checked In')),
                        DropdownMenuItem(value: 'Checked Out', child: Text('Checked Out')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => status = val);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                final res = await ApiService.updateAttendance(
                  a.attId,
                  date: dateCtrl.text.trim(),
                  checkInTime: checkInCtrl.text.trim(),
                  checkOutTime: checkOutCtrl.text.trim(),
                  status: status,
                );
                setState(() => _loading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res['message'] ?? 'Done'),
                    backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
                _fetch();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecordConfirm(AttendanceModel a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Attendance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the attendance record of ${a.name} for ${a.date}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              final res = await ApiService.deleteAttendance(a.attId);
              setState(() => _loading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res['message'] ?? 'Done'),
                  backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
              _fetch();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
