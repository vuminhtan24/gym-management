import 'package:flutter/foundation.dart';

import '../core/api_client.dart' show extractErrorMessage;
import '../models/package.dart';
import '../models/subscription.dart';
import '../services/package_service.dart';

class PackageProvider extends ChangeNotifier {
  final PackageService _service = PackageService();

  List<GymPackage> packages = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchPackages() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      packages = await _service.list();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createPackage(GymPackage pkg) async {
    try {
      final created = await _service.create(pkg);
      packages.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePackage(int id, GymPackage pkg) async {
    try {
      final updated = await _service.update(id, pkg);
      final index = packages.indexWhere((p) => p.id == id);
      if (index != -1) packages[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePackage(int id) async {
    try {
      await _service.delete(id);
      packages.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> subscribeMember({
    required int memberId,
    required int packageId,
    required DateTime startDate,
    double? pricePaid,
  }) async {
    try {
      await _service.createSubscription(
        memberId: memberId,
        packageId: packageId,
        startDate: startDate,
        pricePaid: pricePaid,
      );
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
