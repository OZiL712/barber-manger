import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/worker_account_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../utils/export_helper.dart';

class WorkerAccountScreen extends StatefulWidget {
  @override
  _WorkerAccountScreenState createState() => _WorkerAccountScreenState();
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
        title: const Text('سحب رصيد (Withdrawal)'),
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
                Provider.of<WorkerAccountProvider>(context, listen: false)
                    .addWithdrawal(amount, noteController.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('سحب'),
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
        title: const Text('إضافة رصيد (Deposit)'),
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
                Provider.of<WorkerAccountProvider>(context, listen: false)
                    .addDeposit(amount, noteController.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
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
            icon: const Icon(Icons.print),
            onPressed: () {
              final provider = Provider.of<WorkerAccountProvider>(context, listen: false);
              ExportHelper.showExportMenu(context, (format) {
                ExportService().exportWorkerAccountReport(
                  DateTime.now().toString(),
                  provider.totalWorkerShare,
                  provider.totalWithdrawals,
                  provider.currentBalance,
                  format,
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('الرصيد الحالي', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          provider.currentBalance.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: provider.currentBalance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard('إجمالي الحصة', provider.totalWorkerShare.toStringAsFixed(2), Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard('الرصيد المضاف', provider.totalDeposits.toStringAsFixed(2), Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard('إجمالي السحوبات', provider.totalWithdrawals.toStringAsFixed(2), Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('العمليات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle, size: 18),
                          label: const Text('إضافة رصيد'),
                          onPressed: () => _showAddDepositDialog(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.money_off, size: 18),
                          label: const Text('سحب رصيد'),
                          onPressed: () => _showAddWithdrawalDialog(context),
                        ),
                      ],
                    )
                  ],
                ),
                
                const SizedBox(height: 16),
                
                if (provider.deposits.isNotEmpty) ...[
                  const Text('الرصيد المضاف:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.deposits.length,
                    itemBuilder: (context, index) {
                      final dp = provider.deposits[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.arrow_upward, color: Colors.green),
                          title: Text('المبلغ: ${dp.amount}'),
                          subtitle: Text('${dp.date} ${dp.time} - ${dp.note ?? "بدون ملاحظة"}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => provider.deleteDeposit(dp.id!),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (provider.withdrawals.isNotEmpty) ...[
                  const Text('سجل السحوبات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.withdrawals.length,
                    itemBuilder: (context, index) {
                      final wd = provider.withdrawals[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.arrow_downward, color: Colors.red),
                          title: Text('مبلغ السحب: ${wd.amount}'),
                          subtitle: Text('${wd.date} ${wd.time} - ${wd.note ?? "بدون ملاحظة"}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => provider.deleteWithdrawal(wd.id!),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                
                if (provider.withdrawals.isEmpty && provider.deposits.isEmpty)
                  const Center(child: Text('لا توجد عمليات مسجلة.')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    IconData iconData = title.contains('الحصة') ? Icons.account_balance : Icons.money_off;
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
                Icon(iconData, size: 18, color: color),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
