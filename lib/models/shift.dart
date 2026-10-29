import '../core/format.dart';

class Shift {
  Shift({required this.id, required this.name, required this.startTime, required this.endTime, required this.lateToleranceMinutes});

  final int id;
  final String name;

  /// `HH:mm:ss` đúng như server trả.
  final String startTime;
  final String endTime;
  final int lateToleranceMinutes;

  String get range => '${shortTime(startTime)} – ${shortTime(endTime)}';

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'] as int,
        name: j['name'] as String,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        lateToleranceMinutes: (j['lateToleranceMinutes'] ?? 0) as int,
      );
}
