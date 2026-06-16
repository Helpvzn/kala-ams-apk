import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/api_service.dart';
import 'add_edit_employee.dart';

class EmployeeManagementScreen extends StatefulWidget {
  final List<EmployeeModel> employees;
  final VoidCallback onRefresh;

  const EmployeeManagementScreen({
    super.key,
    required this.employees,
    required this.onRefresh,
  });

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _showActiveOnly = false;

  List<EmployeeModel> get _filtered {
    return widget.employees.where((e) {
      final matchSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.empId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.department.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.designation.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchActive = !_showActiveOnly || e.isActive;
      return matchSearch && matchActive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = widget.employees.where((e) => e.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        children: [
          // Header with search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${widget.employees.length} Employees Total',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Row(children: [
                            const Icon(Icons.circle, color: Colors.green, size: 8),
                            const SizedBox(width: 4),
                            Text('$activeCount Active',
                                style: const TextStyle(color: Colors.green, fontSize: 12)),
                            const SizedBox(width: 10),
                            const Icon(Icons.circle, color: Colors.red, size: 8),
                            const SizedBox(width: 4),
                            Text('${widget.employees.length - activeCount} Inactive',
                                style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ]),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditEmployeeScreen()),
                        );
                        widget.onRefresh();
                      },
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Employee'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search field
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by Name, ID, Department…',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Active Only'),
                      selected: _showActiveOnly,
                      onSelected: (v) => setState(() => _showActiveOnly = v),
                      selectedColor: Colors.green.withOpacity(0.2),
                      checkmarkColor: Colors.green,
                      labelStyle: TextStyle(
                        color: _showActiveOnly ? Colors.green : Colors.white54,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white10,
                      side: BorderSide(
                        color: _showActiveOnly ? Colors.green : Colors.white12,
                      ),
                    ),
                    const Spacer(),
                    Text('${filtered.length} shown',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          // Employee list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_search, size: 56, color: Colors.white12),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'No employees found' : 'No results for "$_searchQuery"',
                          style: const TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildCard(context, filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, EmployeeModel emp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emp.isActive ? const Color(0xFF6C63FF).withOpacity(0.2) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: emp.isActive
                ? const Color(0xFF6C63FF).withOpacity(0.18)
                : Colors.red.withOpacity(0.15),
            child: Text(
              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: emp.isActive ? const Color(0xFF6C63FF) : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(emp.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${emp.empId}  •  📱 ${emp.mobile}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text('${emp.designation}  •  ${emp.department}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (emp.isActive ? Colors.green : Colors.red).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              emp.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: emp.isActive ? Colors.green : Colors.red,
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
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 6),
                  _infoRow(Icons.badge_outlined, 'Employee ID', emp.empId),
                  _infoRow(Icons.phone_outlined, 'Mobile', emp.mobile),
                  _infoRow(Icons.business_outlined, 'Department', emp.department),
                  _infoRow(Icons.work_outline, 'Designation', emp.designation),
                  const SizedBox(height: 12),
                  // Action buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _actionChip(
                        Icons.edit,
                        'Edit',
                        Colors.blue,
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddEditEmployeeScreen(employee: emp)),
                          );
                          widget.onRefresh();
                        },
                      ),
                      _actionChip(
                        emp.isActive ? Icons.block : Icons.check_circle,
                        emp.isActive ? 'Deactivate' : 'Activate',
                        emp.isActive ? Colors.orange : Colors.green,
                        () => _toggleStatus(context, emp),
                      ),
                      _actionChip(
                        Icons.lock_reset,
                        'Reset Password',
                        const Color(0xFF6C63FF),
                        () => _showResetDialog(context, emp.empId),
                      ),
                      _actionChip(
                        Icons.delete,
                        'Delete',
                        Colors.red,
                        () => _confirmDelete(context, emp),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Expanded(
            child: Text(value.isNotEmpty ? value : '—',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, EmployeeModel emp) async {
    final newStatus = emp.isActive ? 'inactive' : 'active';
    final label = emp.isActive ? 'deactivate' : 'activate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('${emp.isActive ? 'Deactivate' : 'Activate'} Employee',
            style: const TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to $label "${emp.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: emp.isActive ? Colors.orange : Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: Text(emp.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ApiService.toggleEmployee(emp.empId, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Done'),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
    widget.onRefresh();
  }

  void _showResetDialog(BuildContext context, String empId) {
    final ctrl = TextEditingController();
    final confirm = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              if (ctrl.text != confirm.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Passwords do not match'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              Navigator.pop(context);
              final res = await ApiService.resetPassword(empId, ctrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res['message'] ?? 'Done'),
                  backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EmployeeModel emp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Employee', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              'Delete "${emp.name}" (${emp.empId})?\n\nThis will permanently remove the employee and cannot be undone!',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final res = await ApiService.deleteEmployee(emp.empId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res['message'] ?? 'Done'),
                  backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
              widget.onRefresh();
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
