import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/dashboard_summary.dart';

class ReportService {
  final Dio _dio = ApiClient.instance.dio;

  Future<DashboardSummary> getDashboardSummary() async {
    final response = await _dio.get(ApiConstants.reportsDashboard);
    return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RevenuePoint>> getRevenueReport({
    String? dateFrom,
    String? dateTo,
    String groupBy = 'month',
  }) async {
    final response = await _dio.get(
      ApiConstants.reportsRevenue,
      queryParameters: {
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        'group_by': groupBy,
      },
    );
    return (response.data as List)
        .map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PackageSalesPoint>> getPackageSalesReport() async {
    final response = await _dio.get(ApiConstants.reportsPackageSales);
    return (response.data as List)
        .map((e) => PackageSalesPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrainerSessionPoint>> getTrainerSessionsReport() async {
    final response = await _dio.get(ApiConstants.reportsTrainerSessions);
    return (response.data as List)
        .map((e) => TrainerSessionPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ClassAttendancePoint>> getClassAttendanceReport() async {
    final response = await _dio.get(ApiConstants.reportsClassAttendance);
    return (response.data as List)
        .map((e) => ClassAttendancePoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RevenuePoint>> getNewMembersReport({
    String? dateFrom,
    String? dateTo,
    String groupBy = 'month',
  }) async {
    final response = await _dio.get(
      ApiConstants.reportsNewMembers,
      queryParameters: {
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        'group_by': groupBy,
      },
    );
    return (response.data as List)
        .map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
