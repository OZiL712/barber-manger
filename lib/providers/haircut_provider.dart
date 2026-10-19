import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String get selectedDate => _selectedDate;

  bool _isAllDates = false;
  bool get isAllDates => _isAllDates;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool get isToday => _selectedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _selectedDate == DateFormat('yyyy-MM-dd').format(yesterday);
  }

  double get totalIncomeForSelectedDate {
    return _haircuts.fold(0.0, (sum, item) => sum + item.amountReceived);
  }

  HaircutProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _services = await _serviceRepo.getAllServices();
      await _fetchHaircuts();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء تحميل البيانات: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchHaircuts() async {
    List<Haircut> list;
    if (_isAllDates) {
      list = await _haircutRepo.getAllHaircuts();
    } else {
      list = await _haircutRepo.getHaircutsByDateRange(_selectedDate, _selectedDate);
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((h) =>
        h.operationNumber.toLowerCase().contains(q) ||
        (h.notes?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    _haircuts = list;
  }

  Future<void> refreshHaircuts() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchHaircuts();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء تحديث البيانات: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  void changeDate(String newDate) {
    _selectedDate = newDate;
    _isAllDates = false;
    refreshHaircuts();
  }

  void selectToday() {
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _isAllDates = false;
    refreshHaircuts();
  }

  void selectYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    _selectedDate = DateFormat('yyyy-MM-dd').format(yesterday);
    _isAllDates = false;
    refreshHaircuts();
  }

  void selectPreviousDay() {
    final current = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final prev = current.subtract(const Duration(days: 1));
    _selectedDate = DateFormat('yyyy-MM-dd').format(prev);
    _isAllDates = false;
    refreshHaircuts();
  }

  void selectNextDay() {
    final current = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final next = current.add(const Duration(days: 1));
    _selectedDate = DateFormat('yyyy-MM-dd').format(next);
    _isAllDates = false;
    refreshHaircuts();
  }

  void showAllDates() {
    _isAllDates = true;
    refreshHaircuts();
  }

  void searchHaircuts(String query) {
    _searchQuery = query;
    refreshHaircuts();
  }

  Future<void> addHaircut(Haircut haircut) async {
    try {
      await _haircutRepo.addHaircut(haircut);
      // If added for a different date, we can switch to that date or stay on current
      if (!_isAllDates && haircut.date != _selectedDate) {
        _selectedDate = haircut.date;
      }
      await refreshHaircuts();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء الإضافة: $e";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateHaircut(Haircut haircut) async {
    try {
      await _haircutRepo.updateHaircut(haircut);
      await refreshHaircuts();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء التعديل: $e";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteHaircut(int id) async {
    try {
      await _haircutRepo.deleteHaircut(id);
      await refreshHaircuts();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء الحذف: $e";
      notifyListeners();
      rethrow;
    }
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
