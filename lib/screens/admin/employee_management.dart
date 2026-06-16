import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/api_service.dart';
import 'add_edit_employee.dart';

class EmployeeManagementScreen extends StatelessWidget {
  final List<EmployeeModel> employees;
  final VoidCallback onRefresh;

  const EmployeeManagementScreen({
    super.key,
    required this.employees,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${employees.length} Employees',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${employees.where((e) => e.isActive).length} Active',
                          style: const TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditEmployeeScreen()),
                    );
                    onRefresh();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: employees.isEmpty
                ? const Center(
                    child: Text('No employees found', style: TextStyle(color: Colors.white38)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: employees.length,
                    itemBuilder: (_, i) => _buildCard(context, employees[i]),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emp.isActive ? const Color(0xFF6C63FF).withOpacity(0.2) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: emp.isActive ? const Color(0xFF6C63FF).withOpacity(0.2) : Colors.red.withOpacity(0.15),
          child: Text(
            emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
            style: TextStyle(color: emp.isActive ? const Color(0xFF6C63FF) : Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(emp.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${emp.empId} • ${emp.mobile}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text('${emp.designation} • ${emp.department}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: const Color(0xFF1A1A2E),
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          onSelected: (value) => _handleAction(context, emp, value),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
            PopupMenuItem(
              value: emp.isActive ? 'deactivate' : 'activate',
              child: Text(
                emp.isActive ? 'Deactivate' : 'Activate',
                style: TextStyle(color: emp.isActive ? Colors.orange : Colors.green),
              ),
            ),
            const PopupMenuItem(value: 'reset', child: Text('Reset Password', style: TextStyle(color: Colors.blue))),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, EmployeeModel emp, String action) async {
    switch (action) {
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditEmployeeScreen(employee: emp)),
        );
        onRefresh();
        break;
      case 'activate':
      case 'deactivate':
        final newStatus = action == 'activate' ? 'active' : 'inactive';
        final res = await ApiService.toggleEmployee(emp.empId, newStatus);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Done'),
            backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
        onRefresh();
        break;
      case 'reset':
        _showResetDialog(context, emp.empId);
        break;
      case 'delete':
        _confirmDelete(context, emp);
        break;
    }
  }

  void _showResetDialog(BuildContext context, String empId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'New Password',
            labelStyle: TextStyle(color: Colors.white60),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
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
        content: Text('Delete "${emp.name}"? This cannot be undone.',
            style: const TextStyle(color: Colors.white70)),
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
              onRefresh();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
