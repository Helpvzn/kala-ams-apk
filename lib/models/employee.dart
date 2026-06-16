class EmployeeModel {
  final String empId;
  final String name;
  final String mobile;
  final String department;
  final String designation;
  final String status;
  final String? createdAt;

  EmployeeModel({
    required this.empId,
    required this.name,
    required this.mobile,
    required this.department,
    required this.designation,
    required this.status,
    this.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      empId: json['empId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empId': empId,
      'name': name,
      'mobile': mobile,
      'department': department,
      'designation': designation,
      'status': status,
    };
  }

  bool get isActive => status.toLowerCase() == 'active';
}
