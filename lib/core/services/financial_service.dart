import '../models/haircut.dart';
import '../models/daily_expense.dart';
import '../models/worker_withdrawal.dart';
import '../models/worker_deposit.dart';
import '../models/owner_payment.dart';
import '../repositories/haircut_repository.dart';
import '../repositories/financial_repository.dart';

class FinancialService {
  final HaircutRepository _haircutRepo;
  final FinancialRepository _financialRepo;

  FinancialService(this._haircutRepo, this._financialRepo);

  // Calculates Total Income = Sum of Haircut Prices (Rule 8)
  double calculateTotalIncome(List<Haircut> haircuts) {
    return haircuts.fold(0.0, (sum, haircut) => sum + haircut.price);
  }

  // Calculates Total Amount Received (For reference, but NOT for income calculation)
  double calculateTotalReceived(List<Haircut> haircuts) {
    return haircuts.fold(0.0, (sum, haircut) => sum + haircut.amountReceived);
  }

  // Calculates Total Expenses
  double calculateTotalExpenses(List<DailyExpense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Calculates Net Income = Total Income - Expenses (Rule 9)
  double calculateNetIncome(double totalIncome, double totalExpenses) {
    return totalIncome - totalExpenses;
  }

  // Calculates Shares (Rule 10)
  double calculateOwnerShare(double netIncome) {
    return netIncome / 2;
  }

  double calculateWorkerShare(double netIncome) {
    return netIncome / 2;
  }

  // Calculates Total Withdrawals
  double calculateTotalWithdrawals(List<WorkerWithdrawal> withdrawals) {
    return withdrawals.fold(0.0, (sum, withdrawal) => sum + withdrawal.amount);
  }

  double calculateTotalDeposits(List<WorkerDeposit> deposits) {
    return deposits.fold(0.0, (sum, deposit) => sum + deposit.amount);
  }

  // Calculates Current Worker Balance
  double calculateWorkerBalance(double totalWorkerShare, double totalWithdrawals, double totalDeposits) {
    return totalWorkerShare - totalWithdrawals + totalDeposits;
  }

  // Calculates Total Deliveries to Owner
  double calculateTotalOwnerPayments(List<OwnerPayment> payments) {
    return payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }
}
