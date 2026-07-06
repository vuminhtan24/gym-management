import 'package:flutter/foundation.dart';

import '../core/api_client.dart' show extractErrorMessage;
import '../models/trainer.dart';
import '../services/trainer_service.dart';

class TrainerProvider extends ChangeNotifier {
  final TrainerService _service = TrainerService();

  List<Trainer> trainers = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  String? statusFilter;

  Future<void> fetchTrainers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      trainers = await _service.list(search: searchQuery, statusFilter: statusFilter);
    } catch (e) {
      errorMessage = extractErrorMessage(e);
    }
    isLoading = false;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value;
    fetchTrainers();
  }

  void setStatusFilter(String? value) {
    statusFilter = value;
    fetchTrainers();
  }

  Future<bool> createTrainer(Trainer trainer) async {
    try {
      final created = await _service.create(trainer);
      trainers.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTrainer(int id, Trainer trainer) async {
    try {
      final updated = await _service.update(id, trainer);
      final index = trainers.indexWhere((t) => t.id == id);
      if (index != -1) trainers[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTrainer(int id) async {
    try {
      await _service.delete(id);
      trainers.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
