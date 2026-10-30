import 'package:google_sign_in/google_sign_in.dart';

import '../core/session.dart';
import '../models/entities.dart';
import 'api_client.dart';

class AuthService {
  /// Bước 1 đăng ký: server gửi mã 6 số tới email.
  static Future<void> register({required String fullName, required String email, required String password}) =>
      Api.post('/api/auth/register', {'email': email, 'password': password, 'fullName': fullName});

  /// Bước 1 đăng nhập: đúng mật khẩu thì server gửi OTP tới email.
  static Future<void> login(String email, String password) =>
      Api.post('/api/auth/login', {'userNameOrEmail': email, 'password': password});

  /// Bước 2 (cả đăng nhập lẫn xác minh email khi đăng ký): đúng mã thì nhận token.
  static Future<AuthResult> verifyOtp(String email, String code) async {
    final res = await Api.post('/api/auth/verify-otp', {
      'userNameOrEmail': email,
      'code': code,
      'deviceId': await Session.deviceId(),
    });
    return _store(res);
  }

  static Future<void> resendOtp(String email) => Api.post('/api/auth/resend-otp', {'userNameOrEmail': email});

  static Future<void> forgotPassword(String email) => Api.post('/api/auth/forgot-password', {'email': email});

  /// Đổi mật khẩu xong server cấp token luôn.
  static Future<AuthResult> resetPassword({required String email, required String code, required String newPassword}) async {
    final res = await Api.post('/api/auth/reset-password', {'email': email, 'code': code, 'newPassword': newPassword});
    return _store(res);
  }

  static Future<Profile> me() async => Profile.fromJson(await Api.get('/api/auth/me') as Map<String, dynamic>);

  static Future<void> logout() => Session.clear();

  static Future<bool> hasSavedToken() async {
    return Session.isLoggedIn;
  }

  /// Đăng nhập bằng Google
  static Future<AuthResult?> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Không lấy được token xác thực từ Google');

    final res = await Api.post('/api/auth/google-login', {
      'idToken': idToken,
      'deviceId': await Session.deviceId(),
    });
    return _store(res);
  }

  static Future<AuthResult> _store(dynamic json) async {
    final result = AuthResult.fromJson(json as Map<String, dynamic>);
    await Session.save(result);
    return result;
  }
}