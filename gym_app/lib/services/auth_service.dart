import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/staff.dart';

class LoginResult {
  final String accessToken;
  final Staff staff;
  LoginResult({required this.accessToken, required this.staff});
}

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  /// Backend dùng OAuth2PasswordRequestForm -> phải gửi form-urlencoded,
  /// không phải JSON.
  Future<LoginResult> login(String username, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: FormData.fromMap({'username': username, 'password': password}),
    );
    final data = response.data as Map<String, dynamic>;
    return LoginResult(
      accessToken: data['access_token'] as String,
      staff: Staff.fromJson(data['staff'] as Map<String, dynamic>),
    );
  }

  Future<Staff> getMe() async {
    final response = await _dio.get(ApiConstants.me);
    return Staff.fromJson(response.data as Map<String, dynamic>);
  }
}
