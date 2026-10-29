/// Địa chỉ backend đã deploy. Đổi bằng `--dart-define=BASE_URL=https://...`.
const String kBaseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://vupham309-001-site1.etempurl.com',
);

/// Lỗi đã được dịch sang tiếng Việt, sẵn sàng hiện cho người dùng.
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.status, this.reasons = const []});

  final String message;

  /// Mã lỗi nghiệp vụ của server (QR_INVALID, OUT_OF_RANGE, ...), nếu có.
  final String? code;
  final int? status;
  final List<String> reasons;

  @override
  String toString() => message;

  /// Dùng trong `catch (e)` của giao diện.
  static String of(Object e) => e is ApiException ? e.message : 'Có lỗi xảy ra, hãy thử lại.';
}

/// Được gọi khi server trả 401 trong lúc đang đăng nhập (token hết hạn) → đưa về màn đăng nhập.
void Function()? onSessionExpired;
