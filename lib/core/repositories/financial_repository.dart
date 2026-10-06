import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/worker_withdrawal.dart';
import '../models/worker_deposit.dart';
import '../models/owner_payment.dart';
import '../models/daily_expense.dart';

class FinancialRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Expenses
  Future<int> addExpense(DailyExpense expense) async {
    final now = DateTime.now().toIso8601String();
    final DailyExpense expenseWithTimestamps = DailyExpense(
      id: expense.id,
      amount: expense.amount,
      date: expense.date,
      note: expense.note,
      createdAt: expense.createdAt.isNotEmpty ? expense.createdAt : now,
      updatedAt: now,
    );
    final db = await _dbHelper.database;
    return await db.insert('daily_expenses', expenseWithTimestamps.toMap());
  }

  Future<List<DailyExpense>> getExpensesByDateRange(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'daily_expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => DailyExpense.fromMap(maps[i]));
  }

  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('daily_expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Worker Withdrawals
  Future<int> addWorkerWithdrawal(WorkerWithdrawal withdrawal) async {
    final now = DateTime.now().toIso8601String();
    final WorkerWithdrawal withdrawalWithTimestamps = WorkerWithdrawal(
      id: withdrawal.id,
      operationNumber: withdrawal.operationNumber,
      amount: withdrawal.amount,
      date: withdrawal.date,
      time: withdrawal.time,
      note: withdrawal.note,
      createdAt: withdrawal.createdAt.isNotEmpty ? withdrawal.createdAt : now,
      updatedAt: now,
    );
    final db = await _dbHelper.database;
    return await db.insert('worker_withdrawals', withdrawalWithTimestamps.toMap());
  }

  Future<List<WorkerWithdrawal>> getWorkerWithdrawals() async {
    final db = await _dbHelper.database;
    final maps = await db.query('worker_withdrawals', orderBy: 'date DESC, time DESC');
    return List.generate(maps.length, (i) => WorkerWithdrawal.fromMap(maps[i]));
  }

  Future<int> deleteWorkerWithdrawal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('worker_withdrawals', where: 'id = ?', whereArgs: [id]);
  }

  // Worker Deposits
  Future<int> addWorkerDeposit(WorkerDeposit deposit) async {
    final now = DateTime.now().toIso8601String();
    final WorkerDeposit depositWithTimestamps = WorkerDeposit(
      id: deposit.id,
      operationNumber: deposit.operationNumber,
      amount: deposit.amount,
      date: deposit.date,
      time: deposit.time,
      note: deposit.note,
      createdAt: deposit.createdAt.isNotEmpty ? deposit.createdAt : now,
      updatedAt: now,
    );
    final db = await _dbHelper.database;
    return await db.insert('worker_deposits', depositWithTimestamps.toMap());
  }

  Future<List<WorkerDeposit>> getWorkerDeposits() async {
    final db = await _dbHelper.database;
    final maps = await db.query('worker_deposits', orderBy: 'date DESC, time DESC');
    return List.generate(maps.length, (i) => WorkerDeposit.fromMap(maps[i]));
  }

  Future<int> deleteWorkerDeposit(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('worker_deposits', where: 'id = ?', whereArgs: [id]);
  }

  // Owner Payments
  Future<int> addOwnerPayment(OwnerPayment payment) async {
    final now = DateTime.now().toIso8601String();
    final OwnerPayment paymentWithTimestamps = OwnerPayment(
      id: payment.id,
      amount: payment.amount,
      date: payment.date,
      time: payment.time,
      note: payment.note,
      createdAt: payment.createdAt.isNotEmpty ? payment.createdAt : now,
      updatedAt: now,
    );
    final db = await _dbHelper.database;
    return await db.insert('owner_payments', paymentWithTimestamps.toMap());
  }

  Future<List<OwnerPayment>> getOwnerPaymentsByDateRange(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'owner_payments',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, time DESC'
    );
    return List.generate(maps.length, (i) => OwnerPayment.fromMap(maps[i]));
  }

  Future<int> deleteOwnerPayment(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('owner_payments', where: 'id = ?', whereArgs: [id]);
  }
}
