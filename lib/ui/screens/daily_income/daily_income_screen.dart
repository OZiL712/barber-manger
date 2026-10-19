import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/daily_income_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/models/owner_payment.dart';
import '../../../core/models/daily_expense.dart';
import '../../../utils/export_helper.dart';

class DailyIncomeScreen extends StatefulWidget {
  const DailyIncomeScreen({super.key});

  @override
  State<DailyIncomeScreen> createState() => _DailyIncomeScreenState();
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
      locale: const Locale('ar', 'SA'),
    );

    if (picked != null) {
      final formattedDate =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      provider.changeDate(formattedDate);
    }
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة صرفة (مصروف محل)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة أو بيان الصرفة (اختياري)',
                prefixIcon: Icon(Icons.note),
              ),
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
                    .addExpense(amount, noteController.text.trim());
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
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'سبب المخروج (اختياري)',
                prefixIcon: Icon(Icons.description),
              ),
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
                provider.deliverOwnerAccount(amount, noteController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOwnerPayment(BuildContext context, OwnerPayment payment, DailyIncomeProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف مخروج صاحب المحل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا المخروج بمبلغ (${payment.amount.toStringAsFixed(2)})؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteOwnerPayment(payment.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف المخروج بنجاح وإعادة احتساب المستحق.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, DailyExpense expense, DailyIncomeProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصرفة'),
        content: Text('هل أنت متأكد من حذف هذه الصرفة بمبلغ (${expense.amount.toStringAsFixed(2)})؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteExpense(expense.id!);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
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
            tooltip: 'تصدير / طباعة',
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
            tooltip: 'اختيار تاريخ',
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Bar
                _buildDateNavigationCard(context, provider),
                const SizedBox(height: 14),

                // SECTION A: DAILY INCOME
                _buildSectionA(context, provider),
                const SizedBox(height: 14),

                // SECTION B: BUSINESS EXPENSES (الصرفة)
                _buildSectionB(context, provider),
                const SizedBox(height: 14),

                // SECTION C: NET INCOME & SHARES
                _buildSectionC(context, provider),
                const SizedBox(height: 14),

                // SECTION D: OWNER EXPENSES (مخروجات صاحب المحل)
                _buildSectionD(context, provider),
                const SizedBox(height: 14),

                // SECTION E: FINAL OWNER SETTLEMENT
                _buildSectionE(context, provider),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateNavigationCard(BuildContext context, DailyIncomeProvider provider) {
    final theme = Theme.of(context);
    String dateTitle;
    if (provider.isToday) {
      dateTitle = 'اليوم (${provider.selectedDate})';
    } else if (provider.isYesterday) {
      dateTitle = 'أمس (${provider.selectedDate})';
    } else {
      dateTitle = provider.selectedDate;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'اليوم التالي',
              onPressed: () => provider.selectNextDay(),
            ),
            InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      dateTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'اليوم السابق',
              onPressed: () => provider.selectPreviousDay(),
            ),
          ],
        ),
      ),
    );
  }

  // SECTION A: DAILY INCOME
  Widget _buildSectionA(BuildContext context, DailyIncomeProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('القسم الأول: الدخل اليومي', Icons.trending_up, Colors.green),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'إجمالي الدخل',
                    value: provider.totalIncome.toStringAsFixed(2),
                    color: Colors.green.shade700,
                    icon: Icons.payments,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'عدد الحلاقات',
                    value: '${provider.haircutsCount}',
                    color: Colors.blue.shade700,
                    icon: Icons.content_cut,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // SECTION B: BUSINESS EXPENSES (الصرفة)
  Widget _buildSectionB(BuildContext context, DailyIncomeProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('القسم الثاني: الصرفة (مصروفات المحل)', Icons.shopping_bag_outlined, Colors.red),
                ElevatedButton.icon(
                  onPressed: () => _showAddExpenseDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة صرفة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي الصرفة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  provider.totalExpenses.toStringAsFixed(2),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                ),
              ],
            ),
            if (provider.dailyExpenses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('سجل الصرفة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              ...provider.dailyExpenses.map((exp) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.red.shade100,
                        child: Icon(Icons.money_off, size: 16, color: Colors.red.shade700),
                      ),
                      title: Text(
                        'المبلغ: ${exp.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(exp.note?.isNotEmpty == true ? exp.note! : 'بدون ملاحظة'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: 'حذف الصرفة',
                        onPressed: () => _confirmDeleteExpense(context, exp, provider),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // SECTION C: NET INCOME & SHARES
  Widget _buildSectionC(BuildContext context, DailyIncomeProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('القسم الثالث: صافي الدخل والحصص', Icons.pie_chart_outline, Colors.purple),
            const Divider(height: 20),
            _buildValueRow('صافي الدخل (الدخل - الصرفة):', provider.netIncome.toStringAsFixed(2), Colors.purple.shade700, isHighlight: true),
            const SizedBox(height: 8),
            _buildValueRow('حصة صاحب المحل (50%):', provider.ownerShare.toStringAsFixed(2), Colors.indigo.shade700),
            const SizedBox(height: 8),
            _buildValueRow('حصة العامل (50%):', provider.workerShare.toStringAsFixed(2), Colors.teal.shade700),
          ],
        ),
      ),
    );
  }

  // SECTION D: OWNER EXPENSES (مخروجات صاحب المحل)
  Widget _buildSectionD(BuildContext context, DailyIncomeProvider provider) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('القسم الرابع: مخروجات صاحب المحل', Icons.account_balance_wallet, Colors.orange.shade800),
                ElevatedButton.icon(
                  onPressed: () => _showAddOwnerExpenseDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة مخروج'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي مخروجات صاحب المحل:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  provider.ownerDelivered.toStringAsFixed(2),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.ownerPayments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'لا توجد مخروجات مسجلة لصاحب المحل في هذا اليوم.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              const Text('سجل المخروجات (انقر على الحذف لإلغاء أي مخروج):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              ...provider.ownerPayments.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(Icons.arrow_downward, size: 16, color: Colors.orange.shade900),
                      ),
                      title: Text(
                        'المبلغ: ${p.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        'الوقت: ${p.time}${p.note?.isNotEmpty == true ? " • السبب: ${p.note}" : ""}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 22),
                        tooltip: 'حذف هذا المخروج',
                        onPressed: () => _confirmDeleteOwnerPayment(context, p, provider),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // SECTION E: FINAL OWNER SETTLEMENT
  Widget _buildSectionE(BuildContext context, DailyIncomeProvider provider) {
    final due = provider.finalOwnerAmountDue;
    final isPositive = due >= 0;

    return Card(
      elevation: 4,
      color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPositive ? Colors.green.shade400 : Colors.red.shade400,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive ? Icons.check_circle : Icons.warning_amber,
                  color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'القسم الخامس: الحساب النهائي لصاحب المحل',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'المبلغ المستحق لصاحب المحل',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 6),
            Text(
              due.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '(حصة صاحب المحل: ${provider.ownerShare.toStringAsFixed(2)} - مخروجاته: ${provider.ownerDelivered.toStringAsFixed(2)})',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, String value, Color color, {bool isHighlight = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isHighlight ? 12 : 4, vertical: isHighlight ? 10 : 4),
      decoration: isHighlight
          ? BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 15 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
