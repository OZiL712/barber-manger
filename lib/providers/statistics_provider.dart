import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/haircut.dart';
import '../core/models/daily_expense.dart';
import '../core/models/owner_payment.dart';
import '../core/repositories/haircut_repository.dart';
import '../core/repositories/financial_repository.dart';
import '../core/services/financial_service.dart';

enum StatFilterType {
  predefined,
  customDuration,
  customRange,
}

enum PredefinedPeriod {
  lastHour,
  last5Hours,
  last24Hours,
  last7Days,
  last30Days,
  last3Months,
  allTime,
}

class StatisticsProvider with ChangeNotifier {
  final HaircutRepository _haircutRepo = HaircutRepository();
  final FinancialRepository _financialRepo = FinancialRepository();
  late final FinancialService _financialService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Raw all-time data
  List<Haircut> _allHaircuts = [];
  List<DailyExpense> _allExpenses = [];
  List<OwnerPayment> _allOwnerPayments = [];

  // Filter state
  StatFilterType _filterType = StatFilterType.predefined;
  StatFilterType get filterType => _filterType;

  PredefinedPeriod _predefinedPeriod = PredefinedPeriod.last7Days;
  PredefinedPeriod get predefinedPeriod => _predefinedPeriod;

  String _filterLabel = 'آخر 7 أيام';
  String get filterLabel => _filterLabel;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime get startDate => _startDate;

  DateTime _endDate = DateTime.now();
  DateTime get endDate => _endDate;

  // Filtered Results
  double _totalIncome = 0;
  int _haircutsCount = 0;
  double _totalExpenses = 0;
  double _netIncome = 0;
  double _ownerShare = 0;
  double _workerShare = 0;
  double _ownerExpenses = 0;
  double _finalOwnerDue = 0;

  // Best Days
  String _bestIncomeDay = '';
  double _bestIncomeAmount = 0;
  String _highestCustomerDay = '';
  int _highestCustomerCount = 0;
  double _averageDailyCustomers = 0;

  // Services Stats
  Map<String, int> _serviceUsage = {};

  // Chart data
  final Map<String, double> _chartData = {};
  Map<String, double> get chartData => _chartData;

  // Getters for filtered metrics
  double get totalIncome => _totalIncome;
  int get haircutsCount => _haircutsCount;
  int get customersCount => _haircutsCount;
  double get totalExpenses => _totalExpenses;
  double get netIncome => _netIncome;
  double get ownerShare => _ownerShare;
  double get workerShare => _workerShare;
  double get ownerExpenses => _ownerExpenses;
  double get finalOwnerDue => _finalOwnerDue;

  String get bestIncomeDay => _bestIncomeDay;
  double get bestIncomeAmount => _bestIncomeAmount;
  String get highestCustomerDay => _highestCustomerDay;
  int get highestCustomerCount => _highestCustomerCount;
  double get averageDailyCustomers => _averageDailyCustomers;
  Map<String, int> get serviceUsage => _serviceUsage;

  // Backward compatibility getters
  double get weeklyIncome => _totalIncome;
  int get weeklyCustomers => _haircutsCount;
  double get weeklyNetIncome => _netIncome;
  double get weeklyExpenses => _totalExpenses;
  double get monthlyIncome => _totalIncome;
  int get monthlyCustomers => _haircutsCount;
  double get monthlyNetIncome => _netIncome;
  double get monthlyExpenses => _totalExpenses;
  double get monthlyOwnerShare => _ownerShare;
  double get monthlyWorkerShare => _workerShare;
  Map<String, double> get dailyIncomeLast7Days => _chartData;

  StatisticsProvider() {
    _financialService = FinancialService(_haircutRepo, _financialRepo);
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allHaircuts = await _haircutRepo.getAllHaircuts();
      _allExpenses = await _financialRepo.getExpensesByDateRange('2000-01-01', '2100-12-31');
      _allOwnerPayments = await _financialRepo.getOwnerPaymentsByDateRange('2000-01-01', '2100-12-31');

      _applyCurrentFilter();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء تحميل الإحصائيات: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  // 1. Predefined Filter
  void selectPredefinedPeriod(PredefinedPeriod period) {
    _filterType = StatFilterType.predefined;
    _predefinedPeriod = period;
    _errorMessage = null;

    final now = DateTime.now();
    switch (period) {
      case PredefinedPeriod.lastHour:
        _startDate = now.subtract(const Duration(hours: 1));
        _endDate = now;
        _filterLabel = 'آخر ساعة';
        break;
      case PredefinedPeriod.last5Hours:
        _startDate = now.subtract(const Duration(hours: 5));
        _endDate = now;
        _filterLabel = 'آخر 5 ساعات';
        break;
      case PredefinedPeriod.last24Hours:
        _startDate = now.subtract(const Duration(hours: 24));
        _endDate = now;
        _filterLabel = 'آخر 24 ساعة';
        break;
      case PredefinedPeriod.last7Days:
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        _filterLabel = 'آخر 7 أيام';
        break;
      case PredefinedPeriod.last30Days:
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
        _filterLabel = 'آخر 30 يوماً';
        break;
      case PredefinedPeriod.last3Months:
        _startDate = subtractCalendarMonthsAndDays(now, months: 3);
        _endDate = now;
        _filterLabel = 'آخر 3 أشهر';
        break;
      case PredefinedPeriod.allTime:
        _startDate = DateTime(2020, 1, 1);
        _endDate = now.add(const Duration(days: 1));
        _filterLabel = 'كل الأوقات';
        break;
    }

    _applyCurrentFilter();
    notifyListeners();
  }

  // 2. Custom Duration Filter (e.g. 3 months and 2 days, or 27 days, or 5 hours)
  void applyCustomDuration({
    int months = 0,
    int days = 0,
    int hours = 0,
    int minutes = 0,
  }) {
    if (months == 0 && days == 0 && hours == 0 && minutes == 0) {
      _errorMessage = 'الرجاء تحديد مدة زمنية صالحة.';
      notifyListeners();
      return;
    }

    _filterType = StatFilterType.customDuration;
    _errorMessage = null;
    final now = DateTime.now();

    _startDate = subtractCalendarMonthsAndDays(
      now,
      months: months,
      days: days,
      hours: hours,
      minutes: minutes,
    );
    _endDate = now;

    List<String> labelParts = [];
    if (months > 0) labelParts.add('$months شهر');
    if (days > 0) labelParts.add('$days يوم');
    if (hours > 0) labelParts.add('$hours ساعة');
    if (minutes > 0) labelParts.add('$minutes دقيقة');
    _filterLabel = 'آخر (${labelParts.join(' و ')})';

    _applyCurrentFilter();
    notifyListeners();
  }

  // 3. Custom Date/Time Range Filter
  bool applyCustomRange(DateTime start, DateTime end) {
    if (start.isAfter(end)) {
      _errorMessage = 'تاريخ ووقت البداية يجب أن يكون قبل تاريخ ووقت النهاية.';
      notifyListeners();
      return false;
    }

    _filterType = StatFilterType.customRange;
    _errorMessage = null;
    _startDate = start;
    _endDate = end;

    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    _filterLabel = 'من ${formatter.format(start)} إلى ${formatter.format(end)}';

    _applyCurrentFilter();
    notifyListeners();
    return true;
  }

  void _applyCurrentFilter() {
    // Filter Haircuts
    final filteredHaircuts = _allHaircuts.where((h) {
      final dt = _parseHaircutDateTime(h);
      if (dt == null) return false;
      return !dt.isBefore(_startDate) && !dt.isAfter(_endDate);
    }).toList();

    // Filter Expenses
    final filteredExpenses = _allExpenses.where((e) {
      final dt = _parseExpenseDateTime(e);
      if (dt == null) return false;
      return !dt.isBefore(_startDate) && !dt.isAfter(_endDate);
    }).toList();

    // Filter Owner Payments
    final filteredOwnerPayments = _allOwnerPayments.where((p) {
      final dt = _parseOwnerPaymentDateTime(p);
      if (dt == null) return false;
      return !dt.isBefore(_startDate) && !dt.isAfter(_endDate);
    }).toList();

    // Apply strict financial rules
    _totalIncome = _financialService.calculateTotalIncome(filteredHaircuts);
    _haircutsCount = filteredHaircuts.length;
    _totalExpenses = _financialService.calculateTotalExpenses(filteredExpenses);
    _netIncome = _financialService.calculateNetIncome(_totalIncome, _totalExpenses);
    _ownerShare = _financialService.calculateOwnerShare(_netIncome);
    _workerShare = _financialService.calculateWorkerShare(_netIncome);
    _ownerExpenses = _financialService.calculateTotalOwnerPayments(filteredOwnerPayments);
    _finalOwnerDue = _ownerShare - _ownerExpenses;

    // Best Days calculation
    Map<String, double> incomeByDate = {};
    Map<String, int> customersByDate = {};

    for (var hc in filteredHaircuts) {
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
    _averageDailyCustomers = workingDays > 0 ? filteredHaircuts.length / workingDays : 0;

    // Services popularity
    _serviceUsage.clear();
    for (var hc in filteredHaircuts) {
      for (var s in hc.services) {
        _serviceUsage[s.name] = (_serviceUsage[s.name] ?? 0) + 1;
      }
    }
    var sortedEntries = _serviceUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _serviceUsage = Map.fromEntries(sortedEntries);

    // Chart Data
    _chartData.clear();
    final duration = _endDate.difference(_startDate);
    if (duration.inHours <= 48) {
      // Group by hours
      for (var hc in filteredHaircuts) {
        final dt = _parseHaircutDateTime(hc);
        if (dt != null) {
          final label = DateFormat('HH:00').format(dt);
          _chartData[label] = (_chartData[label] ?? 0) + hc.price;
        }
      }
    } else {
      // Group by day
      for (var hc in filteredHaircuts) {
        final label = DateFormat('MM-dd').format(DateTime.parse(hc.date));
        _chartData[label] = (_chartData[label] ?? 0) + hc.price;
      }
    }
  }

  DateTime? _parseHaircutDateTime(Haircut h) {
    try {
      final dateParts = h.date.split('-');
      final timeStr = h.time.trim();
      final timeParts = timeStr.split(':');
      if (dateParts.length == 3 && timeParts.length >= 2) {
        int hour = int.parse(timeParts[0].trim());
        int minute = int.parse(timeParts[1].replaceAll(RegExp(r'[^0-9]'), ''));
        final upper = timeStr.toUpperCase();
        if (upper.contains('PM') || timeStr.contains('م')) {
          if (hour < 12) hour += 12;
        } else if (upper.contains('AM') || timeStr.contains('ص')) {
          if (hour == 12) hour = 0;
        }
        return DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          hour,
          minute,
        );
      }
    } catch (_) {}
    return DateTime.tryParse(h.createdAt) ?? DateTime.tryParse(h.date);
  }

  DateTime? _parseExpenseDateTime(DailyExpense e) {
    try {
      final dt = DateTime.tryParse(e.createdAt);
      if (dt != null) return dt;
      return DateTime.tryParse(e.date);
    } catch (_) {
      return DateTime.tryParse(e.date);
    }
  }

  DateTime? _parseOwnerPaymentDateTime(OwnerPayment p) {
    try {
      final dateParts = p.date.split('-');
      final timeParts = p.time.split(':');
      if (dateParts.length == 3 && timeParts.length >= 2) {
        return DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      }
    } catch (_) {}
    return DateTime.tryParse(p.createdAt) ?? DateTime.tryParse(p.date);
  }

  static DateTime subtractCalendarMonthsAndDays(
    DateTime from, {
    int months = 0,
    int days = 0,
    int hours = 0,
    int minutes = 0,
  }) {
    int year = from.year;
    int month = from.month - months;
    while (month <= 0) {
      month += 12;
      year -= 1;
    }
    int daysInMonth = _getDaysInMonth(year, month);
    int day = from.day > daysInMonth ? daysInMonth : from.day;

    DateTime monthAdjusted = DateTime(
      year,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
    );
    return monthAdjusted.subtract(Duration(days: days, hours: hours, minutes: minutes));
  }

  static int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      final isLeapYear = (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const daysInMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonths[month - 1];
  }
}
