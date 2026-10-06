import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/daily_income_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../utils/export_helper.dart';

class DailyIncomeScreen extends StatefulWidget {
  @override
  _DailyIncomeScreenState createState() => _DailyIncomeScreenState();
}

class _DailyIncomeScreenState extends State<DailyIncomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DailyIncomeProvider>(context, listen: false).loadDailyData();
    });
  }

  void _pickDate(BuildContext context) async {
    final provider = Provider.of<DailyIncomeProvider>(context, listen: false);
    final initialDate = DateTime.tryParse(provider.selectedDate) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      provider.changeDate(formattedDate);
    }
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مصروف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'المبلغ'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                Provider.of<DailyIncomeProvider>(context, listen: false)
                    .addExpense(amount, noteController.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showAddOwnerExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final provider = Provider.of<DailyIncomeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مخروج لصاحب المحل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'المبلغ'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'سبب المخروج (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                provider.deliverOwnerAccount(amount, noteController.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدخل اليومي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              final provider = Provider.of<DailyIncomeProvider>(context, listen: false);
              ExportHelper.showExportMenu(context, (format) {
                ExportService().exportDailyIncomeReport(
                  provider.selectedDate,
                  provider.totalIncome,
                  provider.totalReceived,
                  provider.totalExpenses,
                  provider.netIncome,
                  provider.ownerShare,
                  provider.ownerDelivered,
                  provider.ownerPayments,
                  format,
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: Consumer<DailyIncomeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'تاريخ: ${provider.selectedDate}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Summary Cards
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildSummaryRow('إجمالي الدخل', provider.totalIncome, Colors.green),
                        const Divider(),
                        _buildSummaryRow('الصرفة', provider.totalExpenses, Colors.red),
                        const Divider(),
                        _buildSummaryRow('صافي الدخل', provider.netIncome, Colors.purple, isBold: true),
                        const Divider(),
                        _buildSummaryRow('حصة صاحب المحل', provider.ownerShare, Colors.blue),
                        const Divider(),
                        _buildSummaryRow('مخروجات صاحب المحل', provider.ownerDelivered, Colors.orange),
                        const Divider(),
                        _buildSummaryRow('المبلغ المستحق لصاحب المحل', provider.ownerShare - provider.ownerDelivered, Colors.green, isBold: true),
                        const Divider(),
                        _buildSummaryRow('حصة العامل', provider.ownerShare, Colors.teal, isBold: true),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                // Owner Account Section (Phase 7)
                _buildOwnerAccountSection(context, provider),

                const SizedBox(height: 24),
                
                // Expenses Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('مصروفات اليوم:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: () => _showAddExpenseDialog(context),
                    )
                  ],
                ),
                
                if (provider.dailyExpenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('لا توجد مصروفات مسجلة لهذا اليوم.'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.dailyExpenses.length,
                    itemBuilder: (context, index) {
                      final exp = provider.dailyExpenses[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            child: const Icon(Icons.money_off, color: Colors.red),
                          ),
                          title: Text('المبلغ: ${exp.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(exp.note ?? 'بدون ملاحظة'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => provider.deleteExpense(exp.id!),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String title, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value.toStringAsFixed(2), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildOwnerAccountSection(BuildContext context, DailyIncomeProvider provider) {
    final ownerShare = provider.ownerShare;
    final ownerExpenses = provider.ownerDelivered;
    final finalOwnerAmountDue = ownerShare - ownerExpenses;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حساب صاحب المحل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المبلغ المستحق لصاحب المحل:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(finalOwnerAmountDue.toStringAsFixed(2), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: finalOwnerAmountDue >= 0 ? Colors.green : Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.money_off),
                label: const Text('إضافة مخروج لصاحب المحل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showAddOwnerExpenseDialog(context),
              ),
            ),
            
            // List of deliveries for the day
            if (provider.ownerPayments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('سجل مخروجات صاحب المحل:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...provider.ownerPayments.map((p) => ListTile(
                dense: true,
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: Text('المبلغ: ${p.amount}'),
                subtitle: Text('الوقت: ${p.time} ${p.note != null && p.note!.isNotEmpty ? " | السبب: ${p.note}" : ""}'),
              )).toList(),
            ]
          ],
        ),
      ),
    );
  }
}
