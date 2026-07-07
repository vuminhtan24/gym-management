import 'package:flutter/foundation.dart';

import '../core/api_client.dart' show extractErrorMessage;
import '../models/group_class.dart';
import '../models/class_schedule.dart';
import '../models/class_registration.dart';
import '../services/class_service.dart';

class ClassProvider extends ChangeNotifier {
  final ClassService _service = ClassService();

  List<GroupClass> classes = [];
  List<ClassSchedule> schedules = [];
  List<ClassRegistration> registrations = [];
  bool isLoading = false;
  String? errorMessage;

  // Fetch all classes
  Future<void> fetchClasses() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      classes = await _service.listClasses();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createClass(GroupClass groupClass) async {
    try {
      final created = await _service.createClass(groupClass);
      classes.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClass(int id, GroupClass groupClass) async {
    try {
      final updated = await _service.updateClass(id, groupClass);
      final index = classes.indexWhere((c) => c.id == id);
      if (index != -1) classes[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClass(int id) async {
    try {
      await _service.deleteClass(id);
      classes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Class Schedules
  Future<void> fetchSchedules({int? classId, DateTime? dateFrom, DateTime? dateTo}) async {
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

      schedules = await _service.listSchedules(
        classId: classId,
        dateFrom: fromStr,
        dateTo: toStr,
      );
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createSchedule(ClassSchedule schedule) async {
    try {
      final created = await _service.createSchedule(schedule);
      schedules.add(created);
      _sortSchedules();
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
      await _service.deleteSchedule(id);
      schedules.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Registrations
  Future<void> fetchRegistrations(int classScheduleId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      registrations = await _service.listRegistrations(classScheduleId: classScheduleId);
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> registerMember(int classScheduleId, int memberId) async {
    try {
      final created = await _service.registerClass(classScheduleId, memberId);
      registrations.add(created);

      // Increment registered count in schedule
      final index = schedules.indexWhere((s) => s.id == classScheduleId);
      if (index != -1) {
        schedules[index].registeredCount++;
      }

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAttendance(int registrationId, String status, int classScheduleId) async {
    try {
      final updated = await _service.updateRegistrationStatus(registrationId, status);
      final index = registrations.indexWhere((r) => r.id == registrationId);
      if (index != -1) {
        registrations[index] = updated;
      }
      
      // If cancelled, decrement registered count
      if (status == 'cancelled') {
        final sIndex = schedules.indexWhere((s) => s.id == classScheduleId);
        if (sIndex != -1) {
          schedules[sIndex].registeredCount = (schedules[sIndex].registeredCount - 1).clamp(0, 9999);
        }
      }

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
