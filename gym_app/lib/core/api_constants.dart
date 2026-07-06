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

  // Trainers
  static const String trainers = '/trainers';
  static String trainerDetail(int id) => '/trainers/$id';
  // PT Schedules
  static const String ptSchedules = '/pt-schedules';
  static String ptScheduleDetail(int id) => '/pt-schedules/$id';

  // Group Classes & Class Schedules & Class Registrations
  static const String classes = '/classes';
  static String classDetail(int id) => '/classes/$id';
  static const String classSchedules = '/classes/schedules';
  static String classScheduleDetail(int id) => '/classes/schedules/$id';
  static const String classRegistrations = '/classes/registrations';
  static String classRegistrationDetail(int id) => '/classes/registrations/$id';

  // Staff
  static const String staff = '/staff';
  static String staffDetail(int id) => '/staff/$id';

  // Reports
  static const String reportsDashboard = '/reports/dashboard';
  static const String reportsRevenue = '/reports/revenue';
  static const String reportsPackageSales = '/reports/package-sales';
  static const String reportsTrainerSessions = '/reports/trainer-sessions';
  static const String reportsClassAttendance = '/reports/class-attendance';
  static const String reportsNewMembers = '/reports/new-members';
}
