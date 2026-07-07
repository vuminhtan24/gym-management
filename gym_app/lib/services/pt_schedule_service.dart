import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/pt_schedule.dart';

class PTScheduleService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<PTSchedule>> list({
    int? memberId,
    int? trainerId,
    String? dateFrom,
    String? dateTo,
    String? status,
  }) async {
    final response = await _dio.get(
      ApiConstants.ptSchedules,
      queryParameters: {
        if (memberId != null) 'member_id': memberId,
        if (trainerId != null) 'trainer_id': trainerId,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (status != null) 'status': status,
      },
    );
    return (response.data as List)
        .map((e) => PTSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PTSchedule> create(PTSchedule schedule) async {
    final response = await _dio.post(ApiConstants.ptSchedules, data: schedule.toJson());
    return PTSchedule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PTSchedule> update(int id, Map<String, dynamic> updateData) async {
    final response = await _dio.put(ApiConstants.ptScheduleDetail(id), data: updateData);
    return PTSchedule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.ptScheduleDetail(id));
  }
}
