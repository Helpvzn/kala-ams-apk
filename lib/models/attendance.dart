class AttendanceModel {
  final String attId;
  final String empId;
  final String name;
  final String date;
  final String checkInTime;
  final String checkOutTime;
  final String workingHours;
  final String checkInPhotoUrl;
  final String checkOutPhotoUrl;
  final String status;
  final String? updatedAt;

  AttendanceModel({
    required this.attId,
    required this.empId,
    required this.name,
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.workingHours,
    required this.checkInPhotoUrl,
    required this.checkOutPhotoUrl,
    required this.status,
    this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attId: json['attId']?.toString() ?? '',
      empId: json['empId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      checkInTime: json['checkInTime']?.toString() ?? '',
      checkOutTime: json['checkOutTime']?.toString() ?? '',
      workingHours: json['workingHours']?.toString() ?? '',
      checkInPhotoUrl: json['checkInPhotoUrl']?.toString() ?? '',
      checkOutPhotoUrl: json['checkOutPhotoUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  bool get hasCheckIn => checkInTime.isNotEmpty;
  bool get hasCheckOut => checkOutTime.isNotEmpty;
  // Robust: consider checked out if status says so OR checkout time is filled
  bool get isCheckedOut =>
      status.toLowerCase() == 'checked out' ||
      status.toLowerCase() == 'checked-out' ||
      checkOutTime.isNotEmpty;
}
