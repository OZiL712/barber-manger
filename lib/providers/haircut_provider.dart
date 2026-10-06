import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/haircut.dart';
import '../core/models/barber_service.dart';
import '../core/repositories/haircut_repository.dart';
import '../core/repositories/service_repository.dart';

class HaircutProvider with ChangeNotifier {
  final HaircutRepository _haircutRepo = HaircutRepository();
  final ServiceRepository _serviceRepo = ServiceRepository();

  List<Haircut> _haircuts = [];
  List<Haircut> get haircuts => _haircuts;

  List<BarberService> _services = [];
  List<BarberService> get services => _services;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HaircutProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _services = await _serviceRepo.getAllServices();
      _haircuts = await _haircutRepo.getAllHaircuts();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء تحميل البيانات: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHaircut(Haircut haircut) async {
    try {
      await _haircutRepo.addHaircut(haircut);
      await loadInitialData(); // Refresh the list
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء الإضافة: $e";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateHaircut(Haircut haircut) async {
    try {
      await _haircutRepo.updateHaircut(haircut);
      await loadInitialData();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء التعديل: $e";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteHaircut(int id) async {
    try {
      await _haircutRepo.deleteHaircut(id);
      await loadInitialData();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء الحذف: $e";
      notifyListeners();
      rethrow;
    }
  }

  void searchHaircuts(String query) async {
    if (query.isEmpty) {
      await loadInitialData();
      return;
    }
    
    // In-memory filter for simplicity, could also query DB
    final allHaircuts = await _haircutRepo.getAllHaircuts();
    _haircuts = allHaircuts.where((h) => 
      h.operationNumber.contains(query) || 
      (h.notes?.contains(query) ?? false)
    ).toList();
    
    notifyListeners();
  }

  Future<void> filterByDateRange(String startDate, String endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      _haircuts = await _haircutRepo.getHaircutsByDateRange(startDate, endDate);
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء التصفية: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
