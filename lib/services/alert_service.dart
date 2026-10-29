import '../models/entities.dart';
import 'api_client.dart';

class AlertService {
  static Future<List<FraudAlert>> list({bool? resolved}) async {
    final res = await Api.get('/api/fraud-alerts', query: {'resolved': ?resolved});
    return [for (final e in res as List) FraudAlert.fromJson(e as Map<String, dynamic>)];
  }

  static Future<void> resolve(int id) => Api.post('/api/fraud-alerts/$id/resolve');

  /// Chỉ Admin.
  static Future<void> delete(int id) => Api.delete('/api/fraud-alerts/$id');
}
