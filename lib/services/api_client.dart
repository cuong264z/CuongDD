import 'package:dio/dio.dart';

import '../core/api.dart';
import '../core/session.dart';

/// Bộ gọi HTTP dùng chung. Mọi lỗi đều được đổi thành [ApiException].
class Api {
  Api._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      // Host miễn phí "ngủ" khi nhàn rỗi nên request đầu có thể mất 10-30 giây.
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 45),
      headers: {'Accept': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = Session.token;
          if (t != null && t.isNotEmpty) options.headers['Authorization'] = 'Bearer $t';
          handler.next(options);
        },
        onError: (e, handler) {
          final hadToken = e.requestOptions.headers.containsKey('Authorization');
          if (e.response?.statusCode == 401 && hadToken) {
            Session.clear().then((_) => onSessionExpired?.call());
          }
          handler.next(e);
        },
      ),
    );

  static Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  static Future<dynamic> post(String path, [Object? body]) => _send(() => _dio.post(path, data: body));

  static Future<dynamic> put(String path, Object body) => _send(() => _dio.put(path, data: body));

  static Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  static Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw _translate(e);
    }
  }

  static ApiException _translate(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Máy chủ phản hồi quá chậm. Host miễn phí có thể đang "thức dậy", hãy thử lại sau ít giây.');
      case DioExceptionType.connectionError:
        return ApiException('Không kết nối được máy chủ. Hãy kiểm tra mạng của bạn.');
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      final code = data['code']?.toString();
      final reasons = data['reasons'] is List ? [for (final r in data['reasons'] as List) r.toString()] : <String>[];
      if (data['message'] != null) {
        return ApiException(data['message'].toString(), code: code, status: status, reasons: reasons);
      }
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        return ApiException((data['errors'] as List).join('\n'), status: status);
      }
      // Lỗi kiểm tra dữ liệu mặc định của ASP.NET: { errors: { Field: ["..."] } }
      if (data['errors'] is Map) {
        final all = (data['errors'] as Map).values.expand((v) => v is List ? v : [v]).join('\n');
        if (all.isNotEmpty) return ApiException(all, status: status);
      }
    }
    return ApiException(switch (status) {
      401 => 'Phiên đăng nhập đã hết hạn hoặc thông tin không đúng.',
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy dữ liệu.',
      409 => 'Thao tác xung đột với dữ liệu hiện có.',
      final s? when s >= 500 => 'Máy chủ đang gặp lỗi ($s). Hãy thử lại sau.',
      _ => 'Có lỗi xảy ra, hãy thử lại.',
    }, status: status);
  }
}
