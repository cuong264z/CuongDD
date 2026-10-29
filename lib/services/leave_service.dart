import '../core/format.dart';
import '../models/entities.dart';
import 'api_client.dart';

class LeaveService {
  /// Nhân viên nhận đơn của mình, Admin/Manager nhận tất cả. `status`: Pending/Approved/Rejected.
  static Future<List<Leave>> list({String? status}) async {
    final res = await Api.get('/api/leaves', query: {'status': ?status});
    return [for (final e in res as List) Leave.fromJson(e as Map<String, dynamic>)];
  }

  static Map<String, dynamic> _body(DateTime from, DateTime to, String reason) =>
      {'fromDate': apiDate(from), 'toDate': apiDate(to), 'reason': reason};

  static Future<void> create(DateTime from, DateTime to, String reason) =>
      Api.post('/api/leaves', _body(from, to, reason));

  static Future<void> update(int id, DateTime from, DateTime to, String reason) =>
      Api.put('/api/leaves/$id', _body(from, to, reason));

  static Future<void> delete(int id) => Api.delete('/api/leaves/$id');

  static Future<void> review(int id, {required bool approve}) => Api.post('/api/leaves/$id/review', {'approve': approve});
}
