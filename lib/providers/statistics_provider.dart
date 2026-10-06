import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/haircut.dart';
import '../core/models/daily_expense.dart';
import '../core/repositories/haircut_repository.dart';
import '../core/repositories/financial_repository.dart';
import '../core/services/financial_service.dart';
import '../core/models/barber_service.dart';

class StatisticsProvider with ChangeNotifier {
  final HaircutRepository _haircutRepo = HaircutRepository();
  final FinancialRepository _financialRepo = FinancialRepository();
  late final FinancialService _financialService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Raw data
  List<Haircut> _allHaircuts = [];
  List<DailyExpense> _allExpenses = [];
  
  // Weekly Stats
  double _weeklyIncome = 0;
  int _weeklyCustomers = 0;
  double _weeklyNetIncome = 0;
  double _weeklyExpenses = 0;

  // Monthly Stats
  double _monthlyIncome = 0;
  int _monthlyCustomers = 0;
  double _monthlyNetIncome = 0;
  double _monthlyExpenses = 0;
  double _monthlyOwnerShare = 0;
  double _monthlyWorkerShare = 0;
  
  // Best Days
  String _bestIncomeDay = '';
  double _bestIncomeAmount = 0;
  String _highestCustomerDay = '';
  int _highestCustomerCount = 0;
  double _averageDailyCustomers = 0;

  // Services Stats
  Map<String, int> _serviceUsage = {};

  // Getters
  double get weeklyIncome => _weeklyIncome;
  int get weeklyCustomers => _weeklyCustomers;
  double get weeklyNetIncome => _weeklyNetIncome;
  double get weeklyExpenses => _weeklyExpenses;

  double get monthlyIncome => _monthlyIncome;
  int get monthlyCustomers => _monthlyCustomers;
  double get monthlyNetIncome => _monthlyNetIncome;
  double get monthlyExpenses => _monthlyExpenses;
  double get monthlyOwnerShare => _monthlyOwnerShare;
  double get monthlyWorkerShare => _monthlyWorkerShare;

  String get bestIncomeDay => _bestIncomeDay;
  double get bestIncomeAmount => _bestIncomeAmount;
  String get highestCustomerDay => _highestCustomerDay;
  int get highestCustomerCount => _highestCustomerCount;
  double get averageDailyCustomers => _averageDailyCustomers;
  Map<String, int> get serviceUsage => _serviceUsage;

  // Grouped data for charts
  Map<String, double> _dailyIncomeLast7Days = {};
  Map<String, double> get dailyIncomeLast7Days => _dailyIncomeLast7Days;

  StatisticsProvider() {
    _financialService = FinancialService(_haircutRepo, _financialRepo);
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allHaircuts = await _haircutRepo.getAllHaircuts();
      _allExpenses = await _financialRepo.getExpensesByDateRange('2000-01-01', '2100-12-31');

      _calculateWeeklyStats();
      _calculateMonthlyStats();
      _calculateBestDaysAndAverages();
      _calculateServiceStats();

    } catch (e) {
      // Handle errors
    }

    _isLoading = false;
    notifyListeners();
  }

  void _calculateWeeklyStats() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final weeklyHcs = _allHaircuts.where((h) {
      final date = DateTime.tryParse(h.date);
      return date != null && date.isAfter(sevenDaysAgo) && date.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    final weeklyExps = _allExpenses.where((e) {
      final date = DateTime.tryParse(e.date);
      return date != null && date.isAfter(sevenDaysAgo) && date.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    _weeklyIncome = _financialService.calculateTotalIncome(weeklyHcs);
    _weeklyCustomers = weeklyHcs.length;
    _weeklyExpenses = _financialService.calculateTotalExpenses(weeklyExps);
    _weeklyNetIncome = _financialService.calculateNetIncome(_weeklyIncome, _weeklyExpenses);

    // Chart data for last 7 days
    _dailyIncomeLast7Days.clear();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(day);
      final dayHaircuts = weeklyHcs.where((h) => h.date == dateString).toList();
      _dailyIncomeLast7Days[DateFormat('MM-dd').format(day)] = _financialService.calculateTotalIncome(dayHaircuts);
    }
  }

  void _calculateMonthlyStats() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final monthlyHcs = _allHaircuts.where((h) {
      final date = DateTime.tryParse(h.date);
      return date != null && date.isAfter(thirtyDaysAgo) && date.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    final monthlyExps = _allExpenses.where((e) {
      final date = DateTime.tryParse(e.date);
      return date != null && date.isAfter(thirtyDaysAgo) && date.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    _monthlyIncome = _financialService.calculateTotalIncome(monthlyHcs);
    _monthlyCustomers = monthlyHcs.length;
    _monthlyExpenses = _financialService.calculateTotalExpenses(monthlyExps);
    _monthlyNetIncome = _financialService.calculateNetIncome(_monthlyIncome, _monthlyExpenses);
    _monthlyOwnerShare = _financialService.calculateOwnerShare(_monthlyNetIncome);
    _monthlyWorkerShare = _financialService.calculateWorkerShare(_monthlyNetIncome);
  }

  void _calculateBestDaysAndAverages() {
    Map<String, double> incomeByDate = {};
    Map<String, int> customersByDate = {};

    for (var hc in _allHaircuts) {
      incomeByDate[hc.date] = (incomeByDate[hc.date] ?? 0) + hc.price;
      customersByDate[hc.date] = (customersByDate[hc.date] ?? 0) + 1;
    }

    _bestIncomeAmount = 0;
    _bestIncomeDay = 'لا يوجد';
    incomeByDate.forEach((date, amount) {
      if (amount > _bestIncomeAmount) {
        _bestIncomeAmount = amount;
        _bestIncomeDay = date;
      }
    });

    _highestCustomerCount = 0;
    _highestCustomerDay = 'لا يوجد';
    customersByDate.forEach((date, count) {
      if (count > _highestCustomerCount) {
        _highestCustomerCount = count;
        _highestCustomerDay = date;
      }
    });

    int workingDays = incomeByDate.length;
    _averageDailyCustomers = workingDays > 0 ? _allHaircuts.length / workingDays : 0;
  }

  void _calculateServiceStats() {
    _serviceUsage.clear();
    for (var hc in _allHaircuts) {
      for (var s in hc.services) {
        _serviceUsage[s.name] = (_serviceUsage[s.name] ?? 0) + 1;
      }
    }
    
    // Sort descending
    var sortedEntries = _serviceUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _serviceUsage = Map.fromEntries(sortedEntries);
  }
}
