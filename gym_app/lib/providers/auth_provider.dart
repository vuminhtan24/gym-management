import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/secure_storage.dart';
import '../models/staff.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Nếu token hết hạn giữa chừng (401 từ server), tự đăng xuất.
    ApiClient.instance.onUnauthorized = logout;
  }

  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  Staff? staff;
  bool isLoading = false;
  String? errorMessage;

  /// Gọi lúc khởi động app: kiểm tra token đã lưu còn dùng được không.
  Future<void> tryAutoLogin() async {
    final token = await SecureStorage.instance.readToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      staff = await _authService.getMe();
      status = AuthStatus.authenticated;
    } catch (_) {
      await SecureStorage.instance.deleteToken();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.login(username, password);
      await SecureStorage.instance.saveToken(result.accessToken);
      staff = result.staff;
      status = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.instance.deleteToken();
    staff = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
