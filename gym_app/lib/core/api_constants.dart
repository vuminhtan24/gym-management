import 'package:flutter/foundation.dart';

/// Cấu hình địa chỉ backend FastAPI.
///
/// QUAN TRỌNG - đổi baseUrl tuỳ theo nơi bạn chạy app:
/// - Web (Chrome/Edge) -> dùng 127.0.0.1 hoặc localhost
/// - Android EMULATOR  -> dùng 10.0.2.2 (trỏ về "localhost" của máy tính host)
/// - iOS SIMULATOR     -> dùng 127.0.0.1 hoặc localhost
/// - Thiết bị thật (điện thoại) -> dùng IP LAN của máy chạy backend,
///   ví dụ http://192.168.1.5:8000 (máy tính và điện thoại phải cùng WiFi).
///   Xem IP bằng lệnh `ipconfig` (Windows) rồi thay vào bên dưới.
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
  );

  // Auth
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Members
  static const String members = '/members';
  static String memberDetail(int id) => '/members/$id';
  static String memberSubscriptions(int id) => '/members/$id/subscriptions';

  // Packages
  static const String packages = '/packages';
  static String packageDetail(int id) => '/packages/$id';

  // Subscriptions
  static const String subscriptions = '/subscriptions';
  static String subscriptionDetail(int id) => '/subscriptions/$id';
}
