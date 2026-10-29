/// Server trả giờ UTC; hiển thị theo giờ của máy.
DateTime parseUtc(Object? raw) {
  final s = raw.toString();
  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(s);
  return DateTime.parse(hasZone ? s : '${s}Z').toLocal();
}

String two(int n) => n.toString().padLeft(2, '0');

String fmtTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

String fmtDateTime(DateTime d) => '${fmtTime(d)} · ${fmtDate(d)}';

/// `yyyy-MM-dd` cho API.
String apiDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime parseApiDate(Object? raw) {
  final p = raw.toString().split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2].substring(0, 2)));
}

const _weekdays = ['Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'];

String weekdayVi(DateTime d) => _weekdays[d.weekday - 1];

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String dayLabel(DateTime d) {
  final now = DateTime.now();
  if (sameDay(d, now)) return 'Hôm nay';
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Hôm qua';
  return '${weekdayVi(d)}, ${fmtDate(d)}';
}

/// `08:00:00` → `08:00`
String shortTime(String hms) => hms.length >= 5 ? hms.substring(0, 5) : hms;

String fmtMeters(num m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';
