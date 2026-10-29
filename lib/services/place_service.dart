import '../models/entities.dart';
import 'api_client.dart';

/// Điểm chấm công (API `/api/locations`) và mã QR của điểm đó.
class PlaceService {
  static Future<List<WorkLocation>> all() async {
    final res = await Api.get('/api/locations', query: {'pageSize': 200});
    return Paged.parse(res, WorkLocation.fromJson).items;
  }

  static Future<WorkLocation> get(int id) async =>
      WorkLocation.fromJson(await Api.get('/api/locations/$id') as Map<String, dynamic>);

  static Future<void> create(WorkLocation l) => Api.post('/api/locations', l.toJson());

  static Future<void> update(WorkLocation l) => Api.put('/api/locations/${l.id}', {'id': l.id, ...l.toJson()});

  static Future<void> delete(int id) => Api.delete('/api/locations/$id');

  /// Admin/Manager: lấy chuỗi để vẽ mã QR. Token sống ~1 giờ nhưng màn hình vẫn xin lại mỗi 30 giây.
  static Future<String> qrToken(int locationId) async {
    final res = await Api.get('/api/qr/current', query: {'locationId': locationId}) as Map<String, dynamic>;
    return res['token'] as String;
  }

  /// Token có dạng `SC1.{locationId}.{hạn}.{chữ ký}`. Chỉ dùng để hiện thông tin trước khi gửi;
  /// việc kiểm tra thật do server làm.
  static int? locationIdOf(String token) {
    final parts = token.trim().split('.');
    if (parts.length != 4 || parts.first != 'SC1') return null;
    return int.tryParse(parts[1]);
  }
}
