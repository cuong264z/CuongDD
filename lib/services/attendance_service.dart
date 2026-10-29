import '../core/session.dart';
import '../models/entities.dart';
import 'api_client.dart';
import 'gps_service.dart';

class AttendanceService {
  /// Gửi nguyên chuỗi QR đã quét + vị trí + kết quả kiểm tra khuôn mặt lên server.
  static Future<CheckResult> submit({
    required bool checkIn,
    required String qrToken,
    required GpsReading gps,
    required bool faceVerified,
  }) async {
    final res = await Api.post(checkIn ? '/api/attendance/check-in' : '/api/attendance/check-out', {
      'qrToken': qrToken,
      'latitude': gps.latitude,
      'longitude': gps.longitude,
      'accuracy': gps.accuracy,
      'isMocked': gps.isMocked,
      'deviceId': await Session.deviceId(),
      'faceVerified': faceVerified,
      'faceEmbedding': null,
    });
    return CheckResult.fromJson(res as Map<String, dynamic>);
  }

  /// Lịch sử của chính mình, mới nhất trước.
  static Future<List<AttendanceRecord>> mine({int days = 30}) async {
    final res = await Api.get('/api/attendance/my', query: {'days': days});
    return [for (final e in res as List) AttendanceRecord.fromJson(e as Map<String, dynamic>)];
  }

  /// Admin/Manager: chấm công của mọi người, có toạ độ để vẽ bản đồ.
  static Future<Paged<AttendanceRecord>> all({DateTime? from, DateTime? to, int page = 1, int pageSize = 30}) async {
    final res = await Api.get('/api/attendance', query: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      'page': page,
      'pageSize': pageSize,
    });
    return Paged.parse(res, AttendanceRecord.fromJson);
  }

  /// Bảng công tháng. Nhân viên chỉ nhận của mình.
  static Future<List<ReportRow>> report(int year, int month) async {
    final res = await Api.get('/api/attendance/report', query: {'year': year, 'month': month}) as Map<String, dynamic>;
    return [for (final e in res['rows'] as List) ReportRow.fromJson(e as Map<String, dynamic>)];
  }
}
