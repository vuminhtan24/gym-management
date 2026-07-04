import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'secure_storage.dart';

/// Client HTTP dùng chung cho toàn app.
/// - Tự động gắn header Authorization: Bearer <token> nếu đã đăng nhập.
/// - Gọi [onUnauthorized] khi backend trả về 401 (token hết hạn/không hợp lệ),
///   để lớp AuthProvider có thể tự đăng xuất.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.instance.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  /// Callback được gán từ AuthProvider để xử lý khi token hết hạn.
  void Function()? onUnauthorized;
}

/// Trích xuất thông báo lỗi dễ đọc từ DioException (backend FastAPI trả về
/// {"detail": "..."} khi lỗi).
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        // Lỗi validate của Pydantic trả về dạng list
        final first = detail.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
      }
      return detail.toString();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối tới server. Kiểm tra lại backend và địa chỉ IP trong api_constants.dart';
    }
  }
  return error.toString();
}
