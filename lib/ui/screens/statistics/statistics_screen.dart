import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/statistics_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../utils/export_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedFilterTab = 0; // 0: Predefined, 1: Custom Duration, 2: Custom Range

  // Controllers for Custom Duration
  final _monthsController = TextEditingController();
  final _daysController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  // Controllers / State for Custom Range
  DateTime _rangeStartDate = DateTime.now().subtract(const Duration(days: 7));
  TimeOfDay _rangeStartTime = const TimeOfDay(hour: 0, minute: 0);
  DateTime _rangeEndDate = DateTime.now();
  TimeOfDay _rangeEndTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(context, listen: false).loadStatistics();
    });
  }

  @override
  void dispose() {
    _monthsController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _pickRangeStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('ar', 'SA'),
    );
    if (picked != null) {
      setState(() {
        _rangeStartDate = picked;
      });
    }
  }

  void _pickRangeStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _rangeStartTime,
    );
    if (picked != null) {
      setState(() {
        _rangeStartTime = picked;
      });
    }
  }

  void _pickRangeEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('ar', 'SA'),
    );
    if (picked != null) {
      setState(() {
        _rangeEndDate = picked;
      });
    }
  }

  void _pickRangeEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _rangeEndTime,
    );
    if (picked != null) {
      setState(() {
        _rangeEndTime = picked;
      });
    }
  }

  void _applyCustomRange(StatisticsProvider provider) {
    final start = DateTime(
      _rangeStartDate.year,
      _rangeStartDate.month,
      _rangeStartDate.day,
      _rangeStartTime.hour,
      _rangeStartTime.minute,
    );
    final end = DateTime(
      _rangeEndDate.year,
      _rangeEndDate.month,
      _rangeEndDate.day,
      _rangeEndTime.hour,
      _rangeEndTime.minute,
    );

    final success = provider.applyCustomRange(start, end);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'نطاق التاريخ والوقت غير صالح'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyCustomDuration(StatisticsProvider provider) {
    final months = int.tryParse(_monthsController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;

    if (months == 0 && days == 0 && hours == 0 && minutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال قيمة في حقل واحد على الأقل.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    provider.applyCustomDuration(
      months: months,
      days: days,
      hours: hours,
      minutes: minutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات العمل'),
        actions: [
          IconButton(
            tooltip: 'طباعة / تصدير التقرير',
            icon: const Icon(Icons.print),
            onPressed: () {
              final provider = Provider.of<StatisticsProvider>(context, listen: false);
              ExportHelper.showExportMenu(context, (format) {
                ExportService().exportStatisticsReport(
                  periodTitle: provider.filterLabel,
                  totalIncome: provider.totalIncome,
                  haircutsCount: provider.haircutsCount,
                  totalExpenses: provider.totalExpenses,
                  netIncome: provider.netIncome,
                  ownerShare: provider.ownerShare,
                  workerShare: provider.workerShare,
                  ownerExpenses: provider.ownerExpenses,
                  finalOwnerDue: provider.finalOwnerDue,
                  format: format,
                );
              });
            },
          )
        ],
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter Control Card
                _buildFilterControlCard(context, provider),

                const SizedBox(height: 16),

                // Active Filter Banner
                _buildActiveFilterBanner(context, provider),

                const SizedBox(height: 16),

                // Main Financial Overview Cards
                _buildFinancialOverviewSection(context, provider),

                const SizedBox(height: 20),

                // Chart Section
                _buildChartSection(provider),

                const SizedBox(height: 20),

                // Best Days & Performance Averages
                _buildBestDaysCards(provider),

                const SizedBox(height: 20),

                // Popular Services Statistics
                _buildServicesStats(provider),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterControlCard(BuildContext context, StatisticsProvider provider) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'تحديد فترة الإحصائيات:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Selector
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('فترات جاهزة'), icon: Icon(Icons.flash_on, size: 16)),
                ButtonSegment(value: 1, label: Text('مدة مخصصة'), icon: Icon(Icons.timer_outlined, size: 16)),
                ButtonSegment(value: 2, label: Text('نطاق زمني'), icon: Icon(Icons.date_range, size: 16)),
              ],
              selected: {_selectedFilterTab},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedFilterTab = newSelection.first;
                });
              },
            ),

            const SizedBox(height: 14),

            // Content based on selected tab
            if (_selectedFilterTab == 0) _buildPredefinedPeriodsView(provider),
            if (_selectedFilterTab == 1) _buildCustomDurationView(provider),
            if (_selectedFilterTab == 2) _buildCustomRangeView(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedPeriodsView(StatisticsProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('آخر ساعة'),
          selected: provider.filterType == StatFilterType.predefined &&
              provider.predefinedPeriod == PredefinedPeriod.lastHour,
          onSelected: (val) {
            if (val) provider.selectPredefinedPeriod(PredefinedPeriod.lastHour);
          },
        ),
        ChoiceChip(
          label: const Text('آخر 5 ساعات'),
          selected: provider.filterType == StatFilterType.predefined &&
              provider.predefinedPeriod == PredefinedPeriod.last5Hours,
          onSelected: (val) {
            if (val) provider.selectPredefinedPeriod(PredefinedPeriod.last5Hours);
          },
        ),
        ChoiceChip(
          label: const Text('آخر 24 ساعة'),
          selected: provider.filterType == StatFilterType.predefined &&
              provider.predefinedPeriod == PredefinedPeriod.last24Hours,
          onSelected: (val) {
            if (val) provider.selectPredefinedPeriod(PredefinedPeriod.last24Hours);
          },
        ),
        ChoiceChip(
          label: const Text('آخر 7 أيام'),
          selected: provider.filterType == StatFilterType.predefined &&
              provider.predefinedPeriod == PredefinedPeriod.last7Days,
          onSelected: (val) {
            if (val) provider.selectPredefinedPeriod(PredefinedPeriod.last7Days);
          },
        ),
        ChoiceChip(
          label: const Text('آخر 30 يوماً'),
          selected: provider.filterType == StatFilterType.predefined &&
              provider.predefinedPeriod == PredefinedPeriod.last30Days,
          onSelected: (val) {
            if (val) provider.selectPredefinedPeriod(PredefinedPeriod.last30Days);
          },
        ),
        ChoiceChip(
          label: const Text('آخر 3 أشهر'),
          selected: provider.filterType == StatFilterType.predefined &&
              provider.predefinedPeriod == PredefinedPeriod.last3Months,
          onSelected: (val) {
            if (val) provider.selectPredefinedPeriod(PredefinedPeriod.last3Months);
          },
        ),
        ChoiceChip(
          label: const Text('كل الأوقات'),
          selected: provider.filterType == StatFilterType.predefined &&
              provider.predefinedPeriod == PredefinedPeriod.allTime,
          onSelected: (val) {
            if (val) provider.selectPredefinedPeriod(PredefinedPeriod.allTime);
          },
        ),
      ],
    );
  }

  Widget _buildCustomDurationView(StatisticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أدخل المدة المطلوبة بالشهور أو الأيام أو الساعات:',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _monthsController,
                decoration: const InputDecoration(labelText: 'أشهر', hintText: '0', isDense: true),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _daysController,
                decoration: const InputDecoration(labelText: 'أيام', hintText: '0', isDense: true),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _hoursController,
                decoration: const InputDecoration(labelText: 'ساعات', hintText: '0', isDense: true),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _minutesController,
                decoration: const InputDecoration(labelText: 'دقائق', hintText: '0', isDense: true),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Quick Presets
        Wrap(
          spacing: 6,
          children: [
            ActionChip(
              label: const Text('3 أشهر ويومين'),
              onPressed: () {
                _monthsController.text = '3';
                _daysController.text = '2';
                _hoursController.text = '';
                _minutesController.text = '';
                _applyCustomDuration(provider);
              },
            ),
            ActionChip(
              label: const Text('27 يوماً'),
              onPressed: () {
                _monthsController.text = '';
                _daysController.text = '27';
                _hoursController.text = '';
                _minutesController.text = '';
                _applyCustomDuration(provider);
              },
            ),
            ActionChip(
              label: const Text('5 ساعات'),
              onPressed: () {
                _monthsController.text = '';
                _daysController.text = '';
                _hoursController.text = '5';
                _minutesController.text = '';
                _applyCustomDuration(provider);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('تطبيق المدة وعرض الإحصائيات'),
          onPressed: () => _applyCustomDuration(provider),
        ),
      ],
    );
  }

  Widget _buildCustomRangeView(StatisticsProvider provider) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Start date & time
        Card(
          elevation: 0,
          color: Colors.blue.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                const Text('من:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(dateFormat.format(_rangeStartDate)),
                    onPressed: _pickRangeStartDate,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_rangeStartTime.format(context)),
                  onPressed: _pickRangeStartTime,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // End date & time
        Card(
          elevation: 0,
          color: Colors.purple.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.purple.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                const Text('إلى:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(dateFormat.format(_rangeEndDate)),
                    onPressed: _pickRangeEndDate,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_rangeEndTime.format(context)),
                  onPressed: _pickRangeEndTime,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('عرض الإحصائيات للفترة'),
          onPressed: () => _applyCustomRange(provider),
        ),
      ],
    );
  }

  Widget _buildActiveFilterBanner(BuildContext context, StatisticsProvider provider) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الفترة المعروضة حالياً:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  provider.filterLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverviewSection(BuildContext context, StatisticsProvider provider) {
    return Column(
      children: [
        // 1. Total Income & Haircuts
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'إجمالي الدخل',
                provider.totalIncome.toStringAsFixed(2),
                Colors.green,
                Icons.payments,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'عدد الحلاقات',
                '${provider.haircutsCount}',
                Colors.blue,
                Icons.content_cut,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2. Expenses & Net Income
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'الصرفة (المصروفات)',
                provider.totalExpenses.toStringAsFixed(2),
                Colors.red,
                Icons.money_off,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'صافي الدخل',
                provider.netIncome.toStringAsFixed(2),
                Colors.purple,
                Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 3. Detailed Distribution Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('توزيع الحصص للفترة المحددة:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Divider(height: 18),
                _buildStatRow('حصة صاحب المحل (50% من الصافي):', provider.ownerShare.toStringAsFixed(2), Colors.indigo.shade700),
                const SizedBox(height: 6),
                _buildStatRow('حصة العامل (50% من الصافي):', provider.workerShare.toStringAsFixed(2), Colors.teal.shade700),
                const SizedBox(height: 6),
                _buildStatRow('مخروجات صاحب المحل خلال الفترة:', provider.ownerExpenses.toStringAsFixed(2), Colors.orange.shade800),
                const Divider(height: 18),
                _buildStatRow(
                  'المبلغ المستحق لصاحب المحل عن الفترة:',
                  provider.finalOwnerDue.toStringAsFixed(2),
                  provider.finalOwnerDue >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBestDaysCards(StatisticsProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أفضل الأيام والمعدلات خلال الفترة:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const Divider(height: 20),
            _buildStatRow('أفضل يوم دخل:', '${provider.bestIncomeDay} (${provider.bestIncomeAmount.toStringAsFixed(2)})', Colors.green.shade800),
            const SizedBox(height: 8),
            _buildStatRow('أكثر يوم زبائن:', '${provider.highestCustomerDay} (${provider.highestCustomerCount})', Colors.blue.shade800),
            const SizedBox(height: 8),
            _buildStatRow('متوسط الزبائن اليومي:', provider.averageDailyCustomers.toStringAsFixed(1), Colors.teal.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesStats(StatisticsProvider provider) {
    if (provider.serviceUsage.isEmpty) {
      return Card(
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('لا توجد بيانات للخدمات خلال هذه الفترة.')),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إحصائيات الخدمات الأكثر طلباً خلال الفترة:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const Divider(height: 20),
            ...provider.serviceUsage.entries.map((entry) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: Icon(Icons.content_cut, size: 16, color: Colors.deepPurple.shade700),
                ),
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Chip(
                  label: Text('${entry.value} مرة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(StatisticsProvider provider) {
    final chartData = provider.chartData;
    if (chartData.isEmpty) {
      return Card(
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('لا توجد عمليات مسجلة لعرض الرسم البياني خلال هذه الفترة.')),
        ),
      );
    }

    List<BarChartGroupData> barGroups = [];
    int index = 0;

    chartData.forEach((label, amount) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Colors.green.shade600,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
      index++;
    });

    final titles = chartData.keys.toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('مؤشر الدخل خلال الفترة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 && value.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
