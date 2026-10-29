class Employee {
  Employee({
    required this.id,
    required this.fullName,
    required this.email,
    this.employeeCode,
    this.departmentId,
    this.department,
    required this.isActive,
    required this.hasFace,
    this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final String? employeeCode;
  final int? departmentId;
  final String? department;
  final bool isActive;
  final bool hasFace;

  /// Chỉ có khi lấy chi tiết một nhân viên (danh sách không trả role).
  final String? role;

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: j['id'].toString(),
        fullName: (j['fullName'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        employeeCode: j['employeeCode'] as String?,
        departmentId: j['departmentId'] as int?,
        department: j['department'] as String?,
        isActive: j['isActive'] != false,
        hasFace: j['hasFace'] == true,
        role: j['role'] as String?,
      );
}
