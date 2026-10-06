import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/statistics_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../utils/export_helper.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(context, listen: false).loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات العمل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              final provider = Provider.of<StatisticsProvider>(context, listen: false);
              ExportHelper.showExportMenu(context, (format) {
                ExportService().exportStatisticsReport(
                  DateTime.now().toString(),
                  provider.weeklyIncome,
                  provider.weeklyNetIncome,
                  provider.monthlyIncome,
                  provider.monthlyNetIncome,
                  format,
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
                _buildSectionTitle('إحصائيات آخر 7 أيام'),
                _buildWeeklyCards(provider, context),
                
                const SizedBox(height: 24),
                _buildChartSection(provider),

                const SizedBox(height: 24),
                _buildSectionTitle('إحصائيات آخر 30 يوماً'),
                _buildMonthlyCards(provider),

                const SizedBox(height: 24),
                _buildSectionTitle('أفضل الأيام والمعدلات'),
                _buildBestDaysCards(provider),

                const SizedBox(height: 24),
                _buildSectionTitle('إحصائيات الخدمات (الأكثر طلباً)'),
                _buildServicesStats(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
    );
  }

  Widget _buildWeeklyCards(StatisticsProvider provider, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoCard('الزبائن', provider.weeklyCustomers.toString(), Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildInfoCard('إجمالي الدخل', provider.weeklyIncome.toStringAsFixed(2), Colors.green)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildInfoCard('المصروفات', provider.weeklyExpenses.toStringAsFixed(2), Colors.red)),
            const SizedBox(width: 8),
            Expanded(child: _buildInfoCard('صافي الدخل', provider.weeklyNetIncome.toStringAsFixed(2), Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyCards(StatisticsProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildRowStat('الزبائن:', provider.monthlyCustomers.toString()),
            const Divider(),
            _buildRowStat('الدخل الإجمالي:', provider.monthlyIncome.toStringAsFixed(2)),
            _buildRowStat('المصروفات:', provider.monthlyExpenses.toStringAsFixed(2)),
            const Divider(),
            _buildRowStat('صافي الدخل:', provider.monthlyNetIncome.toStringAsFixed(2), isBold: true),
            const SizedBox(height: 8),
            _buildRowStat('حصة صاحب المحل:', provider.monthlyOwnerShare.toStringAsFixed(2), color: Colors.deepPurple),
            _buildRowStat('حصة العامل:', provider.monthlyWorkerShare.toStringAsFixed(2), color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildBestDaysCards(StatisticsProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildRowStat('أفضل يوم دخل:', '${provider.bestIncomeDay} (${provider.bestIncomeAmount.toStringAsFixed(2)})'),
            _buildRowStat('أكثر يوم زبائن:', '${provider.highestCustomerDay} (${provider.highestCustomerCount})'),
            _buildRowStat('متوسط الزبائن اليومي:', provider.averageDailyCustomers.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesStats(StatisticsProvider provider) {
    if (provider.serviceUsage.isEmpty) {
      return const Text('لا توجد بيانات للخدمات');
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: provider.serviceUsage.entries.map((entry) {
            return ListTile(
              dense: true,
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: CircleAvatar(
                radius: 16,
                child: Text(entry.value.toString(), style: const TextStyle(fontSize: 14)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartSection(StatisticsProvider provider) {
    final chartData = provider.dailyIncomeLast7Days;
    if (chartData.isEmpty) return const SizedBox.shrink();

    List<BarChartGroupData> barGroups = [];
    int index = 0;
    
    chartData.forEach((date, amount) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Colors.green,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        )
      );
      index++;
    });

    final titles = chartData.keys.toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('مؤشر الدخل (آخر 7 أيام)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
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
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowStat(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color, {bool isLarge = false}) {
    IconData iconData = Icons.analytics;
    if (title.contains('الزبائن')) iconData = Icons.groups;
    if (title.contains('الدخل')) iconData = Icons.monetization_on;
    if (title.contains('المصروفات')) iconData = Icons.money_off;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, size: isLarge ? 24 : 18, color: color),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: isLarge ? 16 : 14)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: isLarge ? 28 : 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
