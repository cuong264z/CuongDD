import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_hung_cuong_kt/core/format.dart';
import 'package:hoang_hung_cuong_kt/models/entities.dart';
import 'package:hoang_hung_cuong_kt/models/shift.dart';
import 'package:hoang_hung_cuong_kt/services/gps_service.dart';
import 'package:hoang_hung_cuong_kt/services/place_service.dart';

void main() {
  test('parseUtc hiểu chuỗi có và không có Z', () {
    final a = parseUtc('2026-10-29T01:05:00Z');
    final b = parseUtc('2026-10-29T01:05:00');
    expect(a.toUtc().hour, 1);
    expect(b.toUtc().hour, 1);
  });

  test('Paged.parse + Shift', () {
    final p = Paged.parse({
      'total': 3,
      'page': 1,
      'pageSize': 50,
      'items': [
        {'id': 1, 'name': 'Ca hành chính', 'startTime': '08:00:00', 'endTime': '17:00:00', 'lateToleranceMinutes': 10},
      ],
    }, Shift.fromJson);
    expect(p.total, 3);
    expect(p.items.single.range, '08:00 – 17:00');
  });

  test('Leave tính số ngày và trạng thái', () {
    final l = Leave.fromJson({
      'id': 5,
      'userName': 'A',
      'fromDate': '2026-11-02',
      'toDate': '2026-11-03',
      'reason': 'Việc nhà',
      'status': 'Pending',
      'createdAt': '2026-10-29T01:00:00Z',
    });
    expect(l.days, 2);
    expect(l.isPending, isTrue);
  });

  test('CheckResult đọc giờ có múi +07:00', () {
    final r = CheckResult.fromJson({
      'id': 1,
      'type': 'CheckIn',
      'timeLocal': '2026-10-29T08:05:00+07:00',
      'isLate': false,
      'isEarlyLeave': false,
      'distance': 12,
      'flags': ['trùng toạ độ'],
    });
    expect(r.timeLocal.toUtc().hour, 1);
    expect(r.flags, ['trùng toạ độ']);
  });

  test('tách locationId từ token QR', () {
    expect(PlaceService.locationIdOf('SC1.7.1730000000.abcd'), 7);
    expect(PlaceService.locationIdOf('https://example.com'), isNull);
    expect(PlaceService.locationIdOf('SC1.x.1.2'), isNull);
  });

  test('khoảng cách haversine', () {
    // 0.001 độ vĩ ≈ 111 m
    final d = GpsService.distance(10.0, 106.0, 10.001, 106.0);
    expect(d, closeTo(111, 2));
  });
}
