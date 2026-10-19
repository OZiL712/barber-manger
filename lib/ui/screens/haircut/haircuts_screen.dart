import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/haircut_provider.dart';
import 'add_edit_haircut_screen.dart';
import '../../../core/models/haircut.dart';
import '../../../core/services/export_service.dart';
import '../../../utils/export_helper.dart';

class HaircutsScreen extends StatefulWidget {
  const HaircutsScreen({super.key});

  @override
  State<HaircutsScreen> createState() => _HaircutsScreenState();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickDate(BuildContext context, HaircutProvider provider) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحلاقات'),
        actions: [
          IconButton(
            tooltip: 'تصدير / طباعة',
            icon: const Icon(Icons.print),
            onPressed: () {
              final provider = Provider.of<HaircutProvider>(context, listen: false);
              final dateInfo = provider.isAllDates
                  ? 'جميع التواريخ'
                  : 'تاريخ: ${provider.selectedDate}';
              ExportHelper.showExportMenu(context, (format) {
                ExportService().exportHaircutsReport(
                  provider.haircuts,
                  dateInfo,
                  format,
                );
              });
            },
          )
        ],
      ),
      body: Consumer<HaircutProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Date Filter & Navigation Header
              _buildDateFilterHeader(context, provider),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث برقم العملية أو الملاحظات...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.searchHaircuts('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  onChanged: (value) {
                    provider.searchHaircuts(value);
                  },
                ),
              ),

              // Summary Bar for currently viewed date
              _buildQuickSummaryBar(context, provider),

              // List of Haircuts
              Expanded(
                child: _buildHaircutsList(context, provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditHaircutScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة حلاقة'),
      ),
    );
  }

  Widget _buildDateFilterHeader(BuildContext context, HaircutProvider provider) {
    final theme = Theme.of(context);
    String dateLabel;
    if (provider.isAllDates) {
      dateLabel = 'جميع التواريخ';
    } else if (provider.isToday) {
      dateLabel = 'اليوم (${provider.selectedDate})';
    } else if (provider.isYesterday) {
      dateLabel = 'أمس (${provider.selectedDate})';
    } else {
      dateLabel = provider.selectedDate;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Column(
        children: [
          // Row with date navigation arrows and picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'اليوم التالي',
                onPressed: provider.isAllDates ? null : () => provider.selectNextDay(),
              ),
              InkWell(
                onTap: () => _pickDate(context, provider),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
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
                onPressed: provider.isAllDates ? null : () => provider.selectPreviousDay(),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Quick Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('اليوم'),
                  selected: !provider.isAllDates && provider.isToday,
                  onSelected: (val) {
                    if (val) provider.selectToday();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('أمس'),
                  selected: !provider.isAllDates && provider.isYesterday,
                  onSelected: (val) {
                    if (val) provider.selectYesterday();
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: const Text('اختيار تاريخ'),
                  onPressed: () => _pickDate(context, provider),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('عرض الكل'),
                  selected: provider.isAllDates,
                  onSelected: (val) {
                    if (val) provider.showAllDates();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummaryBar(BuildContext context, HaircutProvider provider) {
    final theme = Theme.of(context);
    final count = provider.haircuts.length;
    final total = provider.totalIncomeForSelectedDate;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.content_cut, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'العدد: $count',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.payments, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text(
                'المستلم: ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHaircutsList(BuildContext context, HaircutProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            provider.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (provider.haircuts.isEmpty) {
      final msg = provider.isAllDates
          ? 'لا توجد سجلات حلاقة في النظام.'
          : (provider.isToday
              ? 'لا توجد حلاقات مسجلة لليوم حتى الآن.'
              : 'لا توجد سجلات حلاقة بتاريخ ${provider.selectedDate}.');

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              msg,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (!provider.isToday && !provider.isAllDates)
              OutlinedButton.icon(
                icon: const Icon(Icons.today),
                label: const Text('العودة إلى اليوم'),
                onPressed: () => provider.selectToday(),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 4),
      itemCount: provider.haircuts.length,
      itemBuilder: (context, index) {
        final haircut = provider.haircuts[index];
        return _buildHaircutCard(context, haircut, provider);
      },
    );
  }

  Widget _buildHaircutCard(BuildContext context, Haircut haircut, HaircutProvider provider) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.content_cut, color: theme.colorScheme.primary),
        ),
        title: Text(
          'عملية: ${haircut.operationNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${haircut.date} • ${haircut.time}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (haircut.services.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: haircut.services
                    .map((s) => Chip(
                          label: Text(s.name, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'المبلغ المستلم: ${haircut.amountReceived}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (haircut.notes != null && haircut.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'ملاحظات: ${haircut.notes}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'تعديل',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEditHaircutScreen(haircut: haircut)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'حذف',
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
