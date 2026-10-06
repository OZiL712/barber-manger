import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/haircut.dart';
import '../core/models/daily_expense.dart';
import '../core/models/worker_withdrawal.dart';
import '../core/models/worker_deposit.dart';
import '../core/repositories/haircut_repository.dart';
import '../core/repositories/financial_repository.dart';
import '../core/services/financial_service.dart';

class WorkerAccountProvider with ChangeNotifier {
  final HaircutRepository _haircutRepo = HaircutRepository();
  final FinancialRepository _financialRepo = FinancialRepository();
  late final FinancialService _financialService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _totalWorkerShare = 0;
  double _totalWithdrawals = 0;
  double _totalDeposits = 0;
  double _currentBalance = 0;

  double get totalWorkerShare => _totalWorkerShare;
  double get totalWithdrawals => _totalWithdrawals;
  double get totalDeposits => _totalDeposits;
  double get currentBalance => _currentBalance;

  List<WorkerWithdrawal> _withdrawals = [];
  List<WorkerWithdrawal> get withdrawals => _withdrawals;

  List<WorkerDeposit> _deposits = [];
  List<WorkerDeposit> get deposits => _deposits;

  WorkerAccountProvider() {
    _financialService = FinancialService(_haircutRepo, _financialRepo);
    loadAccountData();
  }

  Future<void> loadAccountData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // For simplicity, we calculate lifetime balance.
      // In a more complex app, this might be paginated or date-filtered.
      final allHaircuts = await _haircutRepo.getAllHaircuts();
      
      // Need all expenses to calculate net income correctly
      // Since FinancialRepository only has getExpensesByDateRange, 
      // let's fetch a large range or we need getAllExpenses().
      // Let's assume we can calculate it by grouping haircuts and fetching expenses per day, 
      // or we just fetch expenses from 2000 to 2100.
      final allExpenses = await _financialRepo.getExpensesByDateRange('2000-01-01', '2100-12-31');
      
      final totalIncome = _financialService.calculateTotalIncome(allHaircuts);
      final totalExpenses = _financialService.calculateTotalExpenses(allExpenses);
      final netIncome = _financialService.calculateNetIncome(totalIncome, totalExpenses);
      
      _totalWorkerShare = _financialService.calculateWorkerShare(netIncome);
      
      _withdrawals = await _financialRepo.getWorkerWithdrawals();
      _totalWithdrawals = _financialService.calculateTotalWithdrawals(_withdrawals);
      
      _deposits = await _financialRepo.getWorkerDeposits();
      _totalDeposits = _financialService.calculateTotalDeposits(_deposits);
      
      _currentBalance = _financialService.calculateWorkerBalance(_totalWorkerShare, _totalWithdrawals, _totalDeposits);

    } catch (e) {
      // handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWithdrawal(double amount, String note) async {
    final now = DateTime.now();
    final withdrawal = WorkerWithdrawal(
      operationNumber: 'WD-${now.millisecondsSinceEpoch}',
      amount: amount,
      date: DateFormat('yyyy-MM-dd').format(now),
      time: DateFormat('HH:mm').format(now),
      note: note,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );

    await _financialRepo.addWorkerWithdrawal(withdrawal);
    await loadAccountData();
  }

  Future<void> deleteWithdrawal(int id) async {
    await _financialRepo.deleteWorkerWithdrawal(id);
    await loadAccountData();
  }

  Future<void> addDeposit(double amount, String note) async {
    final now = DateTime.now();
    final deposit = WorkerDeposit(
      operationNumber: 'DP-${now.millisecondsSinceEpoch}',
      amount: amount,
      date: DateFormat('yyyy-MM-dd').format(now),
      time: DateFormat('HH:mm').format(now),
      note: note,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );

    await _financialRepo.addWorkerDeposit(deposit);
    await loadAccountData();
  }

  Future<void> deleteDeposit(int id) async {
    await _financialRepo.deleteWorkerDeposit(id);
    await loadAccountData();
  }
}
