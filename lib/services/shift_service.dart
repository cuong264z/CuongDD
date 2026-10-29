import '../models/entities.dart';
import '../models/shift.dart';
import 'api_client.dart';

class ShiftService {
  static Future<List<Shift>> all() async {
    final res = await Api.get('/api/shifts', query: {'pageSize': 200});
    return Paged.parse(res, Shift.fromJson).items;
  }

  static Map<String, dynamic> _body(String name, String start, String end, int tolerance) => {
        'name': name,
        'startTime': start,
        'endTime': end,
        'lateToleranceMinutes': tolerance,
      };

  /// `start`/`end` dạng `HH:mm:ss`.
  static Future<void> create(String name, String start, String end, int tolerance) =>
      Api.post('/api/shifts', _body(name, start, end, tolerance));

  static Future<void> update(int id, String name, String start, String end, int tolerance) =>
      Api.put('/api/shifts/$id', {'id': id, ..._body(name, start, end, tolerance)});

  static Future<void> delete(int id) => Api.delete('/api/shifts/$id');
}
