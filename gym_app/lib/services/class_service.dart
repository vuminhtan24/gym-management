import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/group_class.dart';
import '../models/class_schedule.dart';
import '../models/class_registration.dart';

class ClassService {
  final Dio _dio = ApiClient.instance.dio;

  // Group Classes
  Future<List<GroupClass>> listClasses() async {
    final response = await _dio.get(ApiConstants.classes);
    return (response.data as List)
        .map((e) => GroupClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroupClass> createClass(GroupClass groupClass) async {
    final response = await _dio.post(ApiConstants.classes, data: groupClass.toJson());
    return GroupClass.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroupClass> updateClass(int id, GroupClass groupClass) async {
    final response = await _dio.put(ApiConstants.classDetail(id), data: groupClass.toJson());
    return GroupClass.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteClass(int id) async {
    await _dio.delete(ApiConstants.classDetail(id));
  }

  // Class Schedules
  Future<List<ClassSchedule>> listSchedules({
    int? classId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dio.get(
      ApiConstants.classSchedules,
      queryParameters: {
        if (classId != null) 'class_id': classId,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
      },
    );
    return (response.data as List)
        .map((e) => ClassSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClassSchedule> createSchedule(ClassSchedule schedule) async {
    final response = await _dio.post(ApiConstants.classSchedules, data: schedule.toJson());
    return ClassSchedule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSchedule(int id) async {
    await _dio.delete(ApiConstants.classScheduleDetail(id));
  }

  // Class Registrations
  Future<List<ClassRegistration>> listRegistrations({
    int? classScheduleId,
    int? memberId,
  }) async {
    final response = await _dio.get(
      ApiConstants.classRegistrations,
      queryParameters: {
        if (classScheduleId != null) 'class_schedule_id': classScheduleId,
        if (memberId != null) 'member_id': memberId,
      },
    );
    return (response.data as List)
        .map((e) => ClassRegistration.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClassRegistration> registerClass(int classScheduleId, int memberId) async {
    final response = await _dio.post(
      ApiConstants.classRegistrations,
      data: {
        'class_schedule_id': classScheduleId,
        'member_id': memberId,
      },
    );
    return ClassRegistration.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ClassRegistration> updateRegistrationStatus(int registrationId, String status) async {
    final response = await _dio.put(
      ApiConstants.classRegistrationDetail(registrationId),
      data: {'status': status},
    );
    return ClassRegistration.fromJson(response.data as Map<String, dynamic>);
  }
}
