import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThreatLogger {
  static const storage = FlutterSecureStorage();

  static Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final existing = await storage.read(key: 'threat_logs') ?? '';
    final updated = '$existing\n[$timestamp] $message';
    await storage.write(key: 'threat_logs', value: updated);
  }

  static Future<String?> readLogs() async {
    return await storage.read(key: 'threat_logs');
  }

  static Future<void> clearLogs() async {
    await storage.delete(key: 'threat_logs');
  }
}
