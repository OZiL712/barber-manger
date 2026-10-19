import 'package:flutter_test/flutter_test.dart';
import 'package:barber_manager/core/models/haircut.dart';
import 'package:barber_manager/core/models/daily_expense.dart';
import 'package:barber_manager/core/models/owner_payment.dart';
import 'package:barber_manager/core/models/worker_withdrawal.dart';
import 'package:barber_manager/core/models/worker_deposit.dart';
import 'package:barber_manager/core/repositories/haircut_repository.dart';
import 'package:barber_manager/core/repositories/financial_repository.dart';
import 'package:barber_manager/core/services/financial_service.dart';
import 'package:barber_manager/providers/statistics_provider.dart';

void main() {
  group('اختبارات القواعد والحسابات المالية (Financial Regression Tests)', () {
    final service = FinancialService(HaircutRepository(), FinancialRepository());

    test('TEST 6 — FINANCIAL REGRESSION: حساب الأرباح والحصص والمستحق وحذف مخروج صاحب المحل', () {
      // Total Income = 24,000
      final haircuts = [
        Haircut(
          operationNumber: 'OP-1',
          date: '2026-10-19',
          time: '10:00',
          price: 14000,
          amountReceived: 14000,
          createdAt: '2026-10-19T10:00:00',
          updatedAt: '2026-10-19T10:00:00',
        ),
        Haircut(
          operationNumber: 'OP-2',
          date: '2026-10-19',
          time: '11:00',
          price: 10000,
          amountReceived: 10000,
          createdAt: '2026-10-19T11:00:00',
          updatedAt: '2026-10-19T11:00:00',
        ),
      ];

      final totalIncome = service.calculateTotalIncome(haircuts);
      expect(totalIncome, 24000.0);

      // Business Expenses = 4,000
      final expenses = [
        DailyExpense(
          amount: 4000,
          date: '2026-10-19',
          createdAt: '2026-10-19T12:00:00',
          updatedAt: '2026-10-19T12:00:00',
        ),
      ];
      final totalExpenses = service.calculateTotalExpenses(expenses);
      expect(totalExpenses, 4000.0);

      // Net Income = 20,000
      final netIncome = service.calculateNetIncome(totalIncome, totalExpenses);
      expect(netIncome, 20000.0);

      // Owner Share = 10,000
      final ownerShare = service.calculateOwnerShare(netIncome);
      expect(ownerShare, 10000.0);

      // Worker Share = 10,000
      final workerShare = service.calculateWorkerShare(netIncome);
      expect(workerShare, 10000.0);

      // Owner Expenses = 3,000
      final ownerPayments = [
        OwnerPayment(
          id: 1,
          amount: 3000,
          date: '2026-10-19',
          time: '14:00',
          createdAt: '2026-10-19T14:00:00',
          updatedAt: '2026-10-19T14:00:00',
        ),
      ];
      final ownerDelivered = service.calculateTotalOwnerPayments(ownerPayments);
      expect(ownerDelivered, 3000.0);

      // Final Owner Amount Due = 7,000
      final finalOwnerDue = ownerShare - ownerDelivered;
      expect(finalOwnerDue, 7000.0);

      // Deleting the 3,000 owner expense must produce:
      ownerPayments.clear();
      final ownerDeliveredAfterDelete = service.calculateTotalOwnerPayments(ownerPayments);
      expect(ownerDeliveredAfterDelete, 0.0);

      final finalOwnerDueAfterDelete = ownerShare - ownerDeliveredAfterDelete;
      expect(finalOwnerDueAfterDelete, 10000.0);
      expect(netIncome, 20000.0);
      expect(ownerShare, 10000.0);
      expect(workerShare, 10000.0);
    });

    test('TEST 4 — MY ACCOUNT INDEPENDENCE: استقلالية حسابي وحساب الرصيد اليدوي', () {
      // Opening Balance = 5,000
      const openingBalance = 5000.0;
      // Manual Deposits = 2,000 + 1,000 = 3,000
      final deposits = [
        WorkerDeposit(
          id: 1,
          operationNumber: 'DP-1',
          amount: 2000,
          date: '2026-10-19',
          time: '10:00',
          createdAt: '2026-10-19T10:00:00',
          updatedAt: '2026-10-19T10:00:00',
        ),
        WorkerDeposit(
          id: 2,
          operationNumber: 'DP-2',
          amount: 1000,
          date: '2026-10-19',
          time: '12:00',
          createdAt: '2026-10-19T12:00:00',
          updatedAt: '2026-10-19T12:00:00',
        ),
      ];
      final totalDeposits = service.calculateTotalDeposits(deposits);
      expect(totalDeposits, 3000.0);

      // Manual Withdrawals = 1,500
      final withdrawals = [
        WorkerWithdrawal(
          id: 1,
          operationNumber: 'WD-1',
          amount: 1500,
          date: '2026-10-19',
          time: '15:00',
          createdAt: '2026-10-19T15:00:00',
          updatedAt: '2026-10-19T15:00:00',
        ),
      ];
      final totalWithdrawals = service.calculateTotalWithdrawals(withdrawals);
      expect(totalWithdrawals, 1500.0);

      // Balance = 5000 + 3000 - 1500 = 6500
      final balance = service.calculateManualAccountBalance(
        openingBalance,
        totalDeposits,
        totalWithdrawals,
      );
      expect(balance, 6500.0);
    });

    test('TEST 5 — CUSTOM STATISTICS PERIODS: حساب التاريخ التقويمي الدقيق للأشهر والأيام', () {
      // Example: Current date 2026-10-19
      final testDate = DateTime(2026, 10, 19, 14, 30);

      // Subtraction: 3 calendar months and 2 days
      // 2026-10-19 minus 3 months -> 2026-07-19
      // 2026-07-19 minus 2 days -> 2026-07-17
      final result = StatisticsProvider.subtractCalendarMonthsAndDays(
        testDate,
        months: 3,
        days: 2,
      );

      expect(result.year, 2026);
      expect(result.month, 7);
      expect(result.day, 17);
      expect(result.hour, 14);
      expect(result.minute, 30);

      // Month-end clamping check: May 31 minus 1 month -> April 30 (not May 1)
      final endOfMay = DateTime(2026, 5, 31, 10, 0);
      final minusOneMonth = StatisticsProvider.subtractCalendarMonthsAndDays(
        endOfMay,
        months: 1,
      );
      expect(minusOneMonth.year, 2026);
      expect(minusOneMonth.month, 4);
      expect(minusOneMonth.day, 30);

      // Leap year check: March 31, 2024 (leap year) minus 1 month -> Feb 29, 2024
      final leapYearMarch = DateTime(2024, 3, 31, 10, 0);
      final febLeap = StatisticsProvider.subtractCalendarMonthsAndDays(
        leapYearMarch,
        months: 1,
      );
      expect(febLeap.year, 2024);
      expect(febLeap.month, 2);
      expect(febLeap.day, 29);

      // Non-leap year check: March 31, 2025 minus 1 month -> Feb 28, 2025
      final nonLeapMarch = DateTime(2025, 3, 31, 10, 0);
      final febNonLeap = StatisticsProvider.subtractCalendarMonthsAndDays(
        nonLeapMarch,
        months: 1,
      );
      expect(febNonLeap.year, 2025);
      expect(febNonLeap.month, 2);
      expect(febNonLeap.day, 28);
    });
  });
}
