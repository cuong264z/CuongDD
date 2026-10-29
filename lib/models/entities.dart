import '../core/format.dart';

class Roles {
  static const admin = 'Admin';
  static const manager = 'Manager';
  static const employee = 'Employee';
  static const all = [employee, manager, admin];

  static String label(String role) => switch (role) {
        admin => 'Quản trị viên',
        manager => 'Quản lý',
        _ => 'Nhân viên',
      };
}

/// Danh sách phân trang `{ total, page, pageSize, items }`.
class Paged<T> {
  Paged(this.total, this.items);
  final int total;
  final List<T> items;

  factory Paged.parse(dynamic json, T Function(Map<String, dynamic>) map) {
    final m = json as Map<String, dynamic>;
    return Paged<T>(m['total'] as int, [for (final e in m['items'] as List) map(e as Map<String, dynamic>)]);
  }
}

class AuthResult {
  AuthResult({required this.token, required this.role, required this.userId, required this.fullName, required this.email});

  final String token;
  final String role;
  final String userId;
  final String fullName;
  final String email;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        token: j['token'] as String,
        role: j['role'] as String,
        userId: j['userId'].toString(),
        fullName: (j['fullName'] ?? '') as String,
        email: (j['email'] ?? '') as String,
      );
}

class Profile {
  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.employeeCode,
    this.departmentId,
    required this.role,
    required this.hasFace,
    required this.deviceBound,
  });

  final String id;
  final String fullName;
  final String email;
  final String? employeeCode;
  final int? departmentId;
  final String role;
  final bool hasFace;
  final bool deviceBound;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'].toString(),
        fullName: (j['fullName'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        employeeCode: j['employeeCode'] as String?,
        departmentId: j['departmentId'] as int?,
        role: (j['role'] ?? Roles.employee) as String,
        hasFace: j['hasFace'] == true,
        deviceBound: j['deviceBound'] == true,
      );
}

class WorkLocation {
  WorkLocation({
    this.id = 0,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.shiftId,
  });

  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final int shiftId;

  factory WorkLocation.fromJson(Map<String, dynamic> j) => WorkLocation(
        id: j['id'] as int,
        name: j['name'] as String,
        address: j['address'] as String?,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        radiusMeters: j['radiusMeters'] as int,
        shiftId: j['shiftId'] as int,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'shiftId': shiftId,
      };
}

class Leave {
  Leave({
    required this.id,
    required this.userName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String userName;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;

  /// `Pending` / `Approved` / `Rejected`
  final String status;
  final DateTime createdAt;

  bool get isPending => status == 'Pending';

  int get days => toDate.difference(fromDate).inDays + 1;

  factory Leave.fromJson(Map<String, dynamic> j) => Leave(
        id: j['id'] as int,
        userName: (j['userName'] ?? '') as String,
        fromDate: parseApiDate(j['fromDate']),
        toDate: parseApiDate(j['toDate']),
        reason: (j['reason'] ?? '') as String,
        status: (j['status'] ?? 'Pending') as String,
        createdAt: parseUtc(j['createdAt']),
      );
}

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.type,
    required this.time,
    required this.isLate,
    required this.isEarlyLeave,
    required this.distance,
    required this.location,
    this.userName,
    this.latitude,
    this.longitude,
  });

  final int id;

  /// `CheckIn` / `CheckOut`
  final String type;
  final DateTime time;
  final bool isLate;
  final bool isEarlyLeave;
  final double distance;
  final String location;
  final String? userName;
  final double? latitude;
  final double? longitude;

  bool get isCheckIn => type == 'CheckIn';

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'] as int,
        type: j['type'] as String,
        time: parseUtc(j['timestamp']),
        isLate: j['isLate'] == true,
        isEarlyLeave: j['isEarlyLeave'] == true,
        distance: ((j['distanceMeters'] ?? 0) as num).toDouble(),
        location: (j['location'] ?? '') as String,
        userName: j['userName'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
      );
}

/// Kết quả một lần chấm công thành công.
class CheckResult {
  CheckResult({
    required this.type,
    required this.timeLocal,
    required this.isLate,
    required this.isEarlyLeave,
    required this.distance,
    required this.flags,
  });

  final String type;
  final DateTime timeLocal;
  final bool isLate;
  final bool isEarlyLeave;
  final double distance;
  final List<String> flags;

  factory CheckResult.fromJson(Map<String, dynamic> j) => CheckResult(
        type: j['type'].toString(),
        // `timeLocal` kèm múi giờ +07:00 nên đổi sang giờ máy.
        timeLocal: DateTime.parse(j['timeLocal'].toString()).toLocal(),
        isLate: j['isLate'] == true,
        isEarlyLeave: j['isEarlyLeave'] == true,
        distance: ((j['distance'] ?? 0) as num).toDouble(),
        flags: [for (final f in (j['flags'] as List? ?? const [])) f.toString()],
      );
}

class FraudAlert {
  FraudAlert({
    required this.id,
    required this.userName,
    required this.reason,
    this.detail,
    required this.createdAt,
    required this.resolved,
  });

  final int id;
  final String userName;
  final String reason;
  final String? detail;
  final DateTime createdAt;
  final bool resolved;

  factory FraudAlert.fromJson(Map<String, dynamic> j) => FraudAlert(
        id: j['id'] as int,
        userName: (j['userName'] ?? '') as String,
        reason: (j['reason'] ?? '') as String,
        detail: j['detail'] as String?,
        createdAt: parseUtc(j['createdAt']),
        resolved: j['resolved'] == true,
      );
}

class ReportRow {
  ReportRow({required this.name, required this.daysWorked, required this.lateCount, required this.earlyLeaveCount});

  final String name;
  final int daysWorked;
  final int lateCount;
  final int earlyLeaveCount;

  factory ReportRow.fromJson(Map<String, dynamic> j) => ReportRow(
        name: (j['name'] ?? '') as String,
        daysWorked: (j['daysWorked'] ?? 0) as int,
        lateCount: (j['lateCount'] ?? 0) as int,
        earlyLeaveCount: (j['earlyLeaveCount'] ?? 0) as int,
      );
}
