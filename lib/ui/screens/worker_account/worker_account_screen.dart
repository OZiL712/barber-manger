import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/worker_account_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/models/worker_deposit.dart';
import '../../../core/models/worker_withdrawal.dart';
import '../../../utils/export_helper.dart';

class WorkerAccountScreen extends StatefulWidget {
  const WorkerAccountScreen({super.key});

  @override
  State<WorkerAccountScreen> createState() => _WorkerAccountScreenState();
}

class _WorkerAccountScreenState extends State<WorkerAccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerAccountProvider>(context, listen: false).loadAccountData();
    });
  }

  void _showAddWithdrawalDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سحب رصيد (سحب يدوي)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ المسحوب',
                prefixIcon: Icon(Icons.money_off),
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
                labelText: 'ملاحظة أو بيان السحب (اختياري)',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                Provider.of<WorkerAccountProvider>(context, listen: false)
                    .addWithdrawal(amount, noteController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('تأكيد السحب'),
          ),
        ],
      ),
    );
  }

  void _showAddDepositDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة رصيد (إيداع يدوي)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ المودع',
                prefixIcon: Icon(Icons.add_card),
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
                labelText: 'ملاحظة أو بيان الإيداع (اختياري)',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                Provider.of<WorkerAccountProvider>(context, listen: false)
                    .addDeposit(amount, noteController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('تأكيد الإيداع'),
          ),
        ],
      ),
    );
  }

  void _showEditOpeningBalanceDialog(BuildContext context, double currentOpeningBalance) {
    final controller = TextEditingController(text: currentOpeningBalance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الرصيد الافتتاحي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'الرصيد الافتتاحي هو نقطة البداية لحسابك اليدوي المستقل، ولا يتأثر بأي حلاقات أو مصاريف خارجية.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'الرصيد الافتتاحي',
                prefixIcon: Icon(Icons.account_balance),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autofocus: true,
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
              final amount = double.tryParse(controller.text) ?? 0.0;
              Provider.of<WorkerAccountProvider>(context, listen: false)
                  .updateOpeningBalance(amount);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDeposit(BuildContext context, WorkerDeposit deposit, WorkerAccountProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الإيداع'),
        content: Text('هل أنت متأكد من حذف هذا الإيداع بمبلغ (${deposit.amount.toStringAsFixed(2)})؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteDeposit(deposit.id!);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWithdrawal(BuildContext context, WorkerWithdrawal withdrawal, WorkerAccountProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف السحب'),
        content: Text('هل أنت متأكد من حذف هذا السحب بمبلغ (${withdrawal.amount.toStringAsFixed(2)})؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteWithdrawal(withdrawal.id!);
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
        title: const Text('حسابي'),
        actions: [
          IconButton(
            tooltip: 'طباعة / تصدير التقرير',
            icon: const Icon(Icons.print),
            onPressed: () {
              final provider = Provider.of<WorkerAccountProvider>(context, listen: false);
              ExportHelper.showExportMenu(context, (format) {
                ExportService().exportWorkerAccountReport(
                  dateInfo: DateTime.now().toString().substring(0, 16),
                  openingBalance: provider.openingBalance,
                  totalDeposits: provider.totalDeposits,
                  totalWithdrawals: provider.totalWithdrawals,
                  currentBalance: provider.currentBalance,
                  format: format,
                );
              });
            },
          )
        ],
      ),
      body: Consumer<WorkerAccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final isPositive = provider.currentBalance >= 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner explaining the independent nature
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  margin: const EdgeInsets.only(bottom: 14.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'دفتر محاسبي يدوي مستقل بالكامل لا يتأثر بأي حلاقات أو إيرادات تلقائية.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Current Balance Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                    child: Column(
                      children: [
                        const Text(
                          'الرصيد الحالي',
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.currentBalance.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(الرصيد الافتتاحي + الإيداعات - السحوبات)',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Secondary Metric Cards (Opening Balance, Total Deposits, Total Withdrawals)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditOpeningBalanceDialog(context, provider.openingBalance),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildInfoCard(
                          'الرصيد الافتتاحي',
                          provider.openingBalance.toStringAsFixed(2),
                          Colors.indigo,
                          Icons.account_balance,
                          showEditIcon: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                        'إجمالي الإيداعات',
                        provider.totalDeposits.toStringAsFixed(2),
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                        'إجمالي السحوبات',
                        provider.totalWithdrawals.toStringAsFixed(2),
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle, size: 20),
                        label: const Text('إضافة رصيد', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddDepositDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.money_off, size: 20),
                        label: const Text('سحب رصيد', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddWithdrawalDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section: Manual Deposits List
                if (provider.deposits.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سجل الإيداعات اليدوية (${provider.deposits.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.deposits.length,
                    itemBuilder: (context, index) {
                      final dp = provider.deposits[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green.shade50,
                            child: const Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                          ),
                          title: Text(
                            'المبلغ: ${dp.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(
                            '${dp.date} • ${dp.time}${dp.note?.isNotEmpty == true ? " • ${dp.note}" : ""}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'حذف الإيداع',
                            onPressed: () => _confirmDeleteDeposit(context, dp, provider),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Section: Manual Withdrawals List
                if (provider.withdrawals.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سجل السحوبات اليدوية (${provider.withdrawals.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.withdrawals.length,
                    itemBuilder: (context, index) {
                      final wd = provider.withdrawals[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.red.shade50,
                            child: const Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                          ),
                          title: Text(
                            'المبلغ: ${wd.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(
                            '${wd.date} • ${wd.time}${wd.note?.isNotEmpty == true ? " • ${wd.note}" : ""}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'حذف السحب',
                            onPressed: () => _confirmDeleteWithdrawal(context, wd, provider),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                if (provider.withdrawals.isEmpty && provider.deposits.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد عمليات إيداع أو سحب مسجلة.',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    Color color,
    IconData iconData, {
    bool showEditIcon = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, size: 14, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                if (showEditIcon) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.edit, size: 12, color: color),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
