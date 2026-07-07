import 'package:flutter/foundation.dart';

import '../core/api_client.dart' show extractErrorMessage;
import '../models/dashboard_summary.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  DashboardSummary? summary;
  List<RevenuePoint> revenueData = [];
  List<PackageSalesPoint> packageSales = [];
  List<TrainerSessionPoint> trainerSessions = [];
  List<ClassAttendancePoint> classAttendance = [];
  List<RevenuePoint> newMembersData = [];

  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchDashboardSummary() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      summary = await _service.getDashboardSummary();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRevenueReport({String? dateFrom, String? dateTo, String groupBy = 'month'}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      revenueData = await _service.getRevenueReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        groupBy: groupBy,
      );
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPackageSalesReport() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      packageSales = await _service.getPackageSalesReport();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTrainerSessionsReport() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      trainerSessions = await _service.getTrainerSessionsReport();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchClassAttendanceReport() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      classAttendance = await _service.getClassAttendanceReport();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNewMembersReport({String? dateFrom, String? dateTo, String groupBy = 'month'}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      newMembersData = await _service.getNewMembersReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        groupBy: groupBy,
      );
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }
}
