import '../models/employee.dart';
import '../models/entities.dart';
import 'api_client.dart';

/// Nhân viên (API `/api/employees`: Admin/Manager xem, chỉ Admin ghi).
class UserService {
  static Future<Paged<Employee>> search({String? q, int? departmentId, int page = 1, int pageSize = 20}) async {
    final res = await Api.get('/api/employees', query: {
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      'departmentId': ?departmentId,
      'page': page,
      'pageSize': pageSize,
    });
    return Paged.parse(res, Employee.fromJson);
  }

  static Future<Employee> get(String id) async =>
      Employee.fromJson(await Api.get('/api/employees/$id') as Map<String, dynamic>);

  static Future<void> create({
    required String email,
    required String password,
    required String fullName,
    String? employeeCode,
    int? departmentId,
    required String role,
  }) =>
      Api.post('/api/employees', {
        'email': email,
        'password': password,
        'fullName': fullName,
        'employeeCode': employeeCode,
        'departmentId': departmentId,
        'role': role,
      });

  static Future<void> update(
    String id, {
    required String fullName,
    String? employeeCode,
    int? departmentId,
    required String role,
    required bool isActive,
  }) =>
      Api.put('/api/employees/$id', {
        'fullName': fullName,
        'employeeCode': employeeCode,
        'departmentId': departmentId,
        'role': role,
        'isActive': isActive,
      });

  static Future<void> delete(String id) => Api.delete('/api/employees/$id');

  /// Gỡ ràng buộc máy khi nhân viên đổi điện thoại.
  static Future<void> resetDevice(String id) => Api.post('/api/employees/$id/reset-device');
}
