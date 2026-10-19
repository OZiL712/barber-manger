import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/worker_withdrawal.dart';
import '../core/models/worker_deposit.dart';
import '../core/repositories/financial_repository.dart';
import '../core/services/financial_service.dart';
import '../core/repositories/haircut_repository.dart';
import '../core/database/database_helper.dart';

class WorkerAccountProvider with ChangeNotifier {
  final FinancialRepository _financialRepo = FinancialRepository();
  late final FinancialService _financialService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _openingBalance = 0.0;
  double _totalWithdrawals = 0.0;
  double _totalDeposits = 0.0;
  double _currentBalance = 0.0;

  double get openingBalance => _openingBalance;
  double get totalWithdrawals => _totalWithdrawals;
  double get totalDeposits => _totalDeposits;
  double get currentBalance => _currentBalance;

  // Kept for backward compatibility if any legacy widget queries it
  double get totalWorkerShare => 0.0;

  List<WorkerWithdrawal> _withdrawals = [];
  List<WorkerWithdrawal> get withdrawals => _withdrawals;

  List<WorkerDeposit> _deposits = [];
  List<WorkerDeposit> get deposits => _deposits;

  WorkerAccountProvider() {
    _financialService = FinancialService(HaircutRepository(), _financialRepo);
    loadAccountData();
  }

  Future<void> loadAccountData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load Opening Balance from app_settings
      final db = await DatabaseHelper.instance.database;
      final settingRows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['account_opening_balance'],
      );
      if (settingRows.isNotEmpty) {
        _openingBalance = double.tryParse(settingRows.first['value'].toString()) ?? 0.0;
      } else {
        _openingBalance = 0.0;
      }

      // 2. Fetch all manual withdrawals
      _withdrawals = await _financialRepo.getWorkerWithdrawals();
      _totalWithdrawals = _financialService.calculateTotalWithdrawals(_withdrawals);

      // 3. Fetch all manual deposits
      _deposits = await _financialRepo.getWorkerDeposits();
      _totalDeposits = _financialService.calculateTotalDeposits(_deposits);

      // 4. Calculate strict independent balance: Opening Balance + Deposits - Withdrawals
      _currentBalance = _financialService.calculateManualAccountBalance(
        _openingBalance,
        _totalDeposits,
        _totalWithdrawals,
      );
    } catch (e) {
      // handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOpeningBalance(double newBalance) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final existing = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['account_opening_balance'],
      );
      if (existing.isEmpty) {
        await db.insert('app_settings', {
          'key': 'account_opening_balance',
          'value': newBalance.toString(),
        });
      } else {
        await db.update(
          'app_settings',
          {'value': newBalance.toString()},
          where: 'key = ?',
          whereArgs: ['account_opening_balance'],
        );
      }
      await loadAccountData();
    } catch (e) {
      // handle error
    }
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
