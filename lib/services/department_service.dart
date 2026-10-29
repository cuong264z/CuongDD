import '../models/department.dart';
import '../models/entities.dart';
import 'api_client.dart';

class DepartmentService {
  static Future<List<Department>> all() async {
    final res = await Api.get('/api/departments', query: {'pageSize': 200});
    return Paged.parse(res, Department.fromJson).items;
  }

  static Future<void> create(String name, String? description) =>
      Api.post('/api/departments', {'name': name, 'description': description});

  static Future<void> update(int id, String name, String? description) =>
      Api.put('/api/departments/$id', {'id': id, 'name': name, 'description': description});

  static Future<void> delete(int id) => Api.delete('/api/departments/$id');
}
