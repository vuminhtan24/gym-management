import 'package:flutter/foundation.dart';

import '../core/api_client.dart' show extractErrorMessage;
import '../models/member.dart';
import '../models/subscription.dart';
import '../services/member_service.dart';

class MemberProvider extends ChangeNotifier {
  final MemberService _service = MemberService();

  List<Member> members = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  String? statusFilter; // null = tất cả, 'active', 'inactive'

  Future<void> fetchMembers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      members = await _service.list(search: searchQuery, statusFilter: statusFilter);
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value;
    fetchMembers();
  }

  void setStatusFilter(String? value) {
    statusFilter = value;
    fetchMembers();
  }

  Future<bool> createMember(Member member) async {
    try {
      final created = await _service.create(member);
      members.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMember(int id, Member member) async {
    try {
      final updated = await _service.update(id, member);
      final index = members.indexWhere((m) => m.id == id);
      if (index != -1) members[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMember(int id) async {
    try {
      await _service.delete(id);
      members.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<List<Subscription>> getSubscriptions(int memberId) {
    return _service.getSubscriptions(memberId);
  }
}
