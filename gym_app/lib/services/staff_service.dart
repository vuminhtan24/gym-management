import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/staff.dart';

class StaffService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Staff>> list({String? search, String? role}) async {
    final response = await _dio.get(
      ApiConstants.staff,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null && role.isNotEmpty) 'role': role,
      },
    );
    return (response.data as List)
        .map((e) => Staff.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Staff> create({
    required String fullName,
    required String phone,
    String? email,
    required String role,
    double? salary,
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.staff,
      data: {
        'full_name': fullName,
        'phone': phone,
        'email': (email == null || email.isEmpty) ? null : email,
        'role': role,
        'salary': salary,
        'username': username,
        'password': password,
      },
    );
    return Staff.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Staff> update(
    int id, {
    String? fullName,
    String? phone,
    String? email,
    String? role,
    double? salary,
    String? status,
    String? password,
  }) async {
    final response = await _dio.put(
      ApiConstants.staffDetail(id),
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email.isEmpty ? null : email,
        if (role != null) 'role': role,
        if (salary != null) 'salary': salary,
        if (status != null) 'status': status,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
    return Staff.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.staffDetail(id));
  }
}
