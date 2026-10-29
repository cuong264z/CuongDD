import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

class GpsReading {
  const GpsReading({required this.latitude, required this.longitude, required this.accuracy, required this.isMocked});

  final double latitude;
  final double longitude;

  /// Sai số ước tính, mét.
  final double accuracy;

  /// Hệ điều hành báo đây là vị trí giả lập.
  final bool isMocked;
}

class GpsException implements Exception {
  GpsException(this.message, {this.openAppSettings = false, this.openLocationSettings = false});

  final String message;
  final bool openAppSettings;
  final bool openLocationSettings;

  @override
  String toString() => message;
}

class GpsService {
  /// Xin quyền rồi đọc một vị trí. Ném [GpsException] kèm lời nhắn tiếng Việt nếu không đọc được.
  static Future<GpsReading> read() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw GpsException('GPS đang tắt. Hãy bật dịch vụ vị trí rồi thử lại.', openLocationSettings: true);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) {
      throw GpsException('Quyền vị trí đã bị chặn. Hãy bật lại trong Cài đặt của ứng dụng.', openAppSettings: true);
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.unableToDetermine) {
      throw GpsException('Cần quyền vị trí để biết bạn có đang ở điểm chấm công hay không.');
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 20)),
      );
      return GpsReading(latitude: p.latitude, longitude: p.longitude, accuracy: p.accuracy, isMocked: p.isMocked);
    } on TimeoutException {
      throw GpsException('Chưa bắt được tín hiệu GPS. Hãy ra nơi thoáng hơn rồi thử lại.');
    } on LocationServiceDisabledException {
      throw GpsException('GPS đang tắt. Hãy bật dịch vụ vị trí rồi thử lại.', openLocationSettings: true);
    }
  }

  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  static Future<void> openAppSettings() => Geolocator.openAppSettings();

  /// Khoảng cách đường chim bay (mét) theo công thức haversine.
  static double distance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
    return 2 * r * asin(sqrt(a));
  }
}
