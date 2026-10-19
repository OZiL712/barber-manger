import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/daily_expense.dart';
import '../core/models/owner_payment.dart';
import '../core/models/haircut.dart';
import '../core/repositories/haircut_repository.dart';
import '../core/repositories/financial_repository.dart';
import '../core/services/financial_service.dart';

class DailyIncomeProvider with ChangeNotifier {
  final HaircutRepository _haircutRepo = HaircutRepository();
  final FinancialRepository _financialRepo = FinancialRepository();
  late final FinancialService _financialService;

  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String get selectedDate => _selectedDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Haircut> _dailyHaircuts = [];
  List<DailyExpense> _dailyExpenses = [];
  List<OwnerPayment> _ownerPayments = [];

  double _totalIncome = 0;
  double _totalReceived = 0;
  double _totalExpenses = 0;
  double _netIncome = 0;
  
  double _ownerShare = 0;
  double _ownerDelivered = 0;

  double get totalIncome => _totalIncome;
  double get totalReceived => _totalReceived;
  double get totalExpenses => _totalExpenses;
  double get netIncome => _netIncome;
  
  double get ownerShare => _ownerShare;
  double get workerShare => _ownerShare; // Equal share (netIncome / 2)
  double get ownerDelivered => _ownerDelivered;
  double get finalOwnerAmountDue => _ownerShare - _ownerDelivered;
  List<OwnerPayment> get ownerPayments => _ownerPayments;
  
  int get haircutsCount => _dailyHaircuts.length;
  int get customersCount => _dailyHaircuts.length;

  List<Haircut> get dailyHaircuts => _dailyHaircuts;
  List<DailyExpense> get dailyExpenses => _dailyExpenses;

  bool get isToday => _selectedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _selectedDate == DateFormat('yyyy-MM-dd').format(yesterday);
  }

  DailyIncomeProvider() {
    _financialService = FinancialService(_haircutRepo, _financialRepo);
    loadDailyData();
  }

  void changeDate(String newDate) {
    _selectedDate = newDate;
    loadDailyData();
  }

  void selectToday() {
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    loadDailyData();
  }

  void selectYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    _selectedDate = DateFormat('yyyy-MM-dd').format(yesterday);
    loadDailyData();
  }

  void selectPreviousDay() {
    final current = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final prev = current.subtract(const Duration(days: 1));
    _selectedDate = DateFormat('yyyy-MM-dd').format(prev);
    loadDailyData();
  }

  void selectNextDay() {
    final current = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final next = current.add(const Duration(days: 1));
    _selectedDate = DateFormat('yyyy-MM-dd').format(next);
    loadDailyData();
  }

  Future<void> loadDailyData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _dailyHaircuts = await _haircutRepo.getHaircutsByDateRange(_selectedDate, _selectedDate);
      _dailyExpenses = await _financialRepo.getExpensesByDateRange(_selectedDate, _selectedDate);
      _ownerPayments = await _financialRepo.getOwnerPaymentsByDateRange(_selectedDate, _selectedDate);

      // Apply strict financial rules
      _totalIncome = _financialService.calculateTotalIncome(_dailyHaircuts);
      _totalReceived = _financialService.calculateTotalReceived(_dailyHaircuts);
      _totalExpenses = _financialService.calculateTotalExpenses(_dailyExpenses);
      _netIncome = _financialService.calculateNetIncome(_totalIncome, _totalExpenses);
      
      _ownerShare = _financialService.calculateOwnerShare(_netIncome);
      _ownerDelivered = _financialService.calculateTotalOwnerPayments(_ownerPayments);

    } catch (e) {
      // Handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(double amount, String note) async {
    final expense = DailyExpense(
      amount: amount,
      date: _selectedDate,
      note: note,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _financialRepo.addExpense(expense);
    await loadDailyData();
  }

  Future<void> deleteExpense(int id) async {
    await _financialRepo.deleteExpense(id);
    await loadDailyData();
  }

  Future<void> deliverOwnerAccount(double amount, String note) async {
    final now = DateTime.now();
    final payment = OwnerPayment(
      amount: amount,
      date: _selectedDate,
      time: DateFormat('HH:mm').format(now),
      note: note,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    await _financialRepo.addOwnerPayment(payment);
    await loadDailyData();
  }

  Future<void> deleteOwnerPayment(int id) async {
    await _financialRepo.deleteOwnerPayment(id);
    await loadDailyData();
  }
}
