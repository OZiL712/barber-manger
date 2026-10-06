import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/haircut_provider.dart';
import 'add_edit_haircut_screen.dart';
import '../../../core/models/haircut.dart';
import '../../../core/services/export_service.dart';
import '../../../utils/export_helper.dart';

class HaircutsScreen extends StatefulWidget {
  @override
  _HaircutsScreenState createState() => _HaircutsScreenState();
}

class _HaircutsScreenState extends State<HaircutsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HaircutProvider>(context, listen: false).loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحلاقات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              final provider = Provider.of<HaircutProvider>(context, listen: false);
              ExportHelper.showExportMenu(context, (format) {
                ExportService().exportHaircutsReport(
                  provider.haircuts,
                  DateTime.now().toString(),
                  format,
                );
              });
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث برقم العملية أو الملاحظات...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                Provider.of<HaircutProvider>(context, listen: false).searchHaircuts(value);
              },
            ),
          ),
        ),
      ),
      body: Consumer<HaircutProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)));
          }

          if (provider.haircuts.isEmpty) {
            return const Center(child: Text('لا توجد سجلات حلاقة.'));
          }

          return ListView.builder(
            itemCount: provider.haircuts.length,
            itemBuilder: (context, index) {
              final haircut = provider.haircuts[index];
              return _buildHaircutCard(context, haircut, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditHaircutScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة حلاقة'),
      ),
    );
  }

  Widget _buildHaircutCard(BuildContext context, Haircut haircut, HaircutProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.content_cut, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          'عملية: ${haircut.operationNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${haircut.date} • ${haircut.time}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: haircut.services.map((s) => Chip(
                label: Text(s.name, style: const TextStyle(fontSize: 12)),
                padding: EdgeInsets.zero,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                side: BorderSide.none,
              )).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text('المبلغ المستلم: ${haircut.amountReceived}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEditHaircutScreen(haircut: haircut)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _confirmDelete(context, haircut.id!, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, HaircutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الحلاقة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteHaircut(id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
