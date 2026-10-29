import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/entities.dart';

/// Phiên đăng nhập: lưu trong bộ nhớ + kho bảo mật của máy.
class Session {
  Session._();

  static const _store = FlutterSecureStorage();

  static String? token;
  static String role = '';
  static String userId = '';
  static String fullName = '';
  static String email = '';

  static bool get isLoggedIn => token != null && token!.isNotEmpty && role.isNotEmpty;
  static bool get isAdmin => role == Roles.admin;
  static bool get isManager => role == Roles.manager;
  static bool get canReview => isAdmin || isManager;

  static Future<void> load() async {
    token = await _store.read(key: 'token');
    role = await _store.read(key: 'role') ?? '';
    userId = await _store.read(key: 'userId') ?? '';
    fullName = await _store.read(key: 'fullName') ?? '';
    email = await _store.read(key: 'email') ?? '';
  }

  static Future<void> save(AuthResult r) async {
    token = r.token;
    role = r.role;
    userId = r.userId;
    fullName = r.fullName;
    email = r.email;
    await _store.write(key: 'token', value: r.token);
    await _store.write(key: 'role', value: r.role);
    await _store.write(key: 'userId', value: r.userId);
    await _store.write(key: 'fullName', value: r.fullName);
    await _store.write(key: 'email', value: r.email);
  }

  static Future<void> clear() async {
    token = null;
    role = '';
    userId = '';
    fullName = '';
    email = '';
    // Giữ lại mã thiết bị: server gắn tài khoản với máy, đăng xuất không được làm đổi mã này.
    final device = await _store.read(key: _deviceKey);
    await _store.deleteAll();
    if (device != null) await _store.write(key: _deviceKey, value: device);
  }

  static const _deviceKey = 'device_id';

  /// Mã cố định của máy, sinh một lần rồi lưu lại (server dùng để chống chấm công hộ).
  static Future<String> deviceId() async {
    var id = await _store.read(key: _deviceKey);
    if (id == null || id.isEmpty) {
      final rnd = Random.secure();
      id = 'hhc-${List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      await _store.write(key: _deviceKey, value: id);
    }
    return id;
  }
}
