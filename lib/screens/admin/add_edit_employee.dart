import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/api_service.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  final EmployeeModel? employee; // null = add mode, non-null = edit mode

  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _desigCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  bool get _isEditMode => widget.employee != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _idCtrl.text = widget.employee!.empId;
      _nameCtrl.text = widget.employee!.name;
      _mobileCtrl.text = widget.employee!.mobile;
      _deptCtrl.text = widget.employee!.department;
      _desigCtrl.text = widget.employee!.designation;
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _deptCtrl.dispose();
    _desigCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    Map<String, dynamic> res;
    if (_isEditMode) {
      res = await ApiService.updateEmployee({
        'empId': _idCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'designation': _desigCtrl.text.trim(),
      });
    } else {
      res = await ApiService.addEmployee({
        'empId': _idCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'designation': _desigCtrl.text.trim(),
        'password': _passCtrl.text.trim(),
      });
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Saved!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Error'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Employee' : 'Add Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Employee ID', _idCtrl, Icons.badge, readOnly: _isEditMode,
                  hint: 'e.g. EMP001'),
              const SizedBox(height: 16),
              _field('Full Name', _nameCtrl, Icons.person_outline, hint: 'e.g. Rahul Sharma'),
              const SizedBox(height: 16),
              _field('Mobile', _mobileCtrl, Icons.phone_outlined,
                  hint: 'e.g. 9876543210', keyboard: TextInputType.phone),
              const SizedBox(height: 16),
              _field('Department', _deptCtrl, Icons.business_outlined, hint: 'e.g. Sales'),
              const SizedBox(height: 16),
              _field('Designation', _desigCtrl, Icons.work_outline, hint: 'e.g. Executive'),
              if (!_isEditMode) ...[
                const SizedBox(height: 16),
                _field('Password', _passCtrl, Icons.lock_outlined, hint: 'e.g. pass123', obscure: true),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEditMode ? 'Update Employee' : 'Add Employee',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool readOnly = false,
    bool obscure = false,
    String hint = '',
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        suffixIcon: readOnly ? const Icon(Icons.lock_outline, color: Colors.white24, size: 16) : null,
      ),
      validator: (v) => v == null || v.isEmpty ? '$label is required' : null,
    );
  }
}
