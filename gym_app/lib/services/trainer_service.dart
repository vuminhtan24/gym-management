import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/trainer.dart';

class TrainerService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Trainer>> list({String? search, String? statusFilter}) async {
    final response = await _dio.get(
      ApiConstants.trainers,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (statusFilter != null && statusFilter.isNotEmpty) 'status': statusFilter,
      },
    );
    return (response.data as List)
        .map((e) => Trainer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Trainer> create(Trainer trainer) async {
    final response = await _dio.post(ApiConstants.trainers, data: trainer.toJson());
    return Trainer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Trainer> update(int id, Trainer trainer) async {
    final response = await _dio.put(ApiConstants.trainerDetail(id), data: trainer.toJson());
    return Trainer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.trainerDetail(id));
  }
}
