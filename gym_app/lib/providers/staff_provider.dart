import 'package:flutter/foundation.dart';

import '../core/api_client.dart' show extractErrorMessage;
import '../models/staff.dart';
import '../services/staff_service.dart';

class StaffProvider extends ChangeNotifier {
  final StaffService _service = StaffService();

  List<Staff> staffList = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  String? roleFilter;

  Future<void> fetchStaff() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      staffList = await _service.list(search: searchQuery, role: roleFilter);
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value;
    fetchStaff();
  }

  void setRoleFilter(String? value) {
    roleFilter = value;
    fetchStaff();
  }

  Future<bool> createStaff({
    required String fullName,
    required String phone,
    String? email,
    required String role,
    double? salary,
    required String username,
    required String password,
  }) async {
    try {
      final created = await _service.create(
        fullName: fullName,
        phone: phone,
        email: email,
        role: role,
        salary: salary,
        username: username,
        password: password,
      );
      staffList.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStaff(
    int id, {
    String? fullName,
    String? phone,
    String? email,
    String? role,
    double? salary,
    String? status,
    String? password,
  }) async {
    try {
      final updated = await _service.update(
        id,
        fullName: fullName,
        phone: phone,
        email: email,
        role: role,
        salary: salary,
        status: status,
        password: password,
      );
      final index = staffList.indexWhere((s) => s.id == id);
      if (index != -1) {
        staffList[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStaff(int id) async {
    try {
      await _service.delete(id);
      staffList.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
