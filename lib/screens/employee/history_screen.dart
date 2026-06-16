import 'package:flutter/material.dart';
import '../../models/attendance.dart';
import '../../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistoryScreen extends StatefulWidget {
  final String empId;
  const HistoryScreen({super.key, required this.empId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AttendanceModel> _records = [];
  bool _loading = false;
  String _filter = 'month'; // 'today', 'month', 'custom'
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _monthStart() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    String? from, to;
    final today = _today();
    if (_filter == 'today') {
      from = today;
      to = today;
    } else if (_filter == 'month') {
      from = _monthStart();
      to = today;
    } else if (_filter == 'custom' && _customRange != null) {
      from = _fmt(_customRange!.start);
      to = _fmt(_customRange!.end);
    }
    final res = await ApiService.getHistory(widget.empId, fromDate: from, toDate: to);
    if (res['status'] == 'success') {
      final list = res['records'] as List;
      _records = list.map((j) => AttendanceModel.fromJson(j)).toList();
    }
    setState(() => _loading = false);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF6C63FF)),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _customRange = range;
        _filter = 'custom';
      });
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(title: const Text('Attendance History')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                : _records.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _records.length,
                        itemBuilder: (_, i) => _buildCard(_records[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1A2E),
      child: Row(
        children: [
          _filterChip('Today', 'today'),
          const SizedBox(width: 8),
          _filterChip('This Month', 'month'),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickCustomRange,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _filter == 'custom' ? const Color(0xFF6C63FF) : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Custom', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _fetch();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6C63FF) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 13)),
      ),
    );
  }

  Widget _buildCard(AttendanceModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: a.isCheckedOut ? Colors.green.withOpacity(0.2) : const Color(0xFF6C63FF).withOpacity(0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (a.isCheckedOut ? Colors.green : const Color(0xFF6C63FF)).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              a.isCheckedOut ? Icons.check_circle : Icons.work,
              color: a.isCheckedOut ? Colors.green : const Color(0xFF6C63FF),
              size: 22,
            ),
          ),
          title: Text(a.date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(a.status,
              style: TextStyle(
                  color: a.isCheckedOut ? Colors.green : Colors.orange,
                  fontSize: 12)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _row(Icons.login, 'Check In', a.checkInTime, Colors.green),
                  const SizedBox(height: 6),
                  _row(Icons.logout, 'Check Out', a.checkOutTime.isEmpty ? '--' : a.checkOutTime, Colors.orange),
                  const SizedBox(height: 6),
                  _row(Icons.timer, 'Working Hours', a.workingHours.isEmpty ? '--' : a.workingHours, const Color(0xFF6C63FF)),
                  if (a.checkInPhotoUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _photoRow('Check-In Selfie', a.checkInPhotoUrl),
                  ],
                  if (a.checkOutPhotoUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _photoRow('Check-Out Selfie', a.checkOutPhotoUrl),
                  ],
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
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Expanded(child: Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _photoRow(String label, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 120,
              color: Colors.white12,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 120,
              color: Colors.white12,
              child: const Icon(Icons.broken_image, color: Colors.white38),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 60, color: Colors.white24),
          const SizedBox(height: 12),
          const Text('No records found', style: TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }
}
