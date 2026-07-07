import 'package:flutter/foundation.dart';

import '../core/api_client.dart' show extractErrorMessage;
import '../models/pt_schedule.dart';
import '../services/pt_schedule_service.dart';

class PTScheduleProvider extends ChangeNotifier {
  final PTScheduleService _service = PTScheduleService();

  List<PTSchedule> schedules = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchSchedules({
    int? memberId,
    int? trainerId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final fromStr = dateFrom != null
          ? '${dateFrom.year.toString().padLeft(4, '0')}-${dateFrom.month.toString().padLeft(2, '0')}-${dateFrom.day.toString().padLeft(2, '0')}'
          : null;
      final toStr = dateTo != null
          ? '${dateTo.year.toString().padLeft(4, '0')}-${dateTo.month.toString().padLeft(2, '0')}-${dateTo.day.toString().padLeft(2, '0')}'
          : null;

      schedules = await _service.list(
        memberId: memberId,
        trainerId: trainerId,
        dateFrom: fromStr,
        dateTo: toStr,
        status: status,
      );
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createSchedule(PTSchedule schedule) async {
    try {
      final created = await _service.create(schedule);
      schedules.add(created);
      // Sort schedules by date and start time
      _sortSchedules();
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateScheduleStatus(int id, String status) async {
    try {
      final updated = await _service.update(id, {'status': status});
      final index = schedules.indexWhere((s) => s.id == id);
      if (index != -1) {
        schedules[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateScheduleNotes(int id, String notes) async {
    try {
      final updated = await _service.update(id, {'notes': notes});
      final index = schedules.indexWhere((s) => s.id == id);
      if (index != -1) {
        schedules[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSchedule(int id) async {
    try {
      await _service.delete(id);
      schedules.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  void _sortSchedules() {
    schedules.sort((a, b) {
      final dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return a.startTime.compareTo(b.startTime);
    });
  }
}
