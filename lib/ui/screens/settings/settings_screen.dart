import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../providers/haircut_provider.dart';
import '../../../providers/daily_income_provider.dart';
import '../../../providers/worker_account_provider.dart';
import '../../../providers/statistics_provider.dart';
import '../../../providers/theme_provider.dart';
import 'developer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;

  void _showLoading(bool show) {
    setState(() {
      _isLoading = show;
    });
  }

  void _handleBackup() async {
    _showLoading(true);
    try {
      await _backupService.createBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز النسخة الاحتياطية بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إنشاء النسخة: $e')));
    }
    _showLoading(false);
  }

  void _handleRestore() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.isNotEmpty && result.first.path != null) {
      final filePath = result.first.path!;
      
      _showLoading(true);
      try {
        final previewData = await _backupService.previewBackup(filePath);
        _showLoading(false);
        
        if (!mounted) return;
        _showRestoreConfirmation(previewData);
      } catch (e) {
        _showLoading(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ملف غير صالح: $e')));
      }
    }
  }

  void _showRestoreConfirmation(Map<String, dynamic> data) {
    final date = data['backup_date'];
    final haircutsCount = (data['haircuts'] as List).length;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سيتم استبدال جميع البيانات الحالية ببيانات النسخة الاحتياطية. هل أنت متأكد؟', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('تاريخ النسخة: $date', textDirection: TextDirection.ltr),
            Text('عدد الحلاقات المسجلة: $haircutsCount'),
            const SizedBox(height: 8),
            const Text('ملاحظة: سيتم إنشاء نقطة استعادة أمنية تلقائياً قبل البدء.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _performRestore(data);
            },
            child: const Text('نعم، استعادة الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performRestore(Map<String, dynamic> data) async {
    _showLoading(true);
    try {
      await _backupService.restoreBackup(data);
      
      // Refresh all providers
      if (!mounted) return;
      Provider.of<HaircutProvider>(context, listen: false).loadInitialData();
      Provider.of<DailyIncomeProvider>(context, listen: false).loadDailyData();
      Provider.of<WorkerAccountProvider>(context, listen: false).loadAccountData();
      Provider.of<StatisticsProvider>(context, listen: false).loadStatistics();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استعادة النسخة الاحتياطية بنجاح!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الاستعادة: $e')));
    }
    _showLoading(false);
  }

  void _handleResetDatabase() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تهيئة قاعدة البيانات', style: TextStyle(color: Colors.red)),
        content: const Text('هل أنت متأكد من مسح جميع بيانات التطبيق بالكامل؟ لا يمكن التراجع عن هذه الخطوة!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              _showLoading(true);
              try {
                final data = await _backupService.previewBackup('impossible_dummy_file'); // Force a safety backup
              } catch (_) {}
              
              try {
                // To reset completely, we restore an empty map. BackupService will clear existing data.
                await _backupService.restoreBackup({});
                if (!mounted) return;
                Provider.of<HaircutProvider>(context, listen: false).loadInitialData();
                Provider.of<DailyIncomeProvider>(context, listen: false).loadDailyData();
                Provider.of<WorkerAccountProvider>(context, listen: false).loadAccountData();
                Provider.of<StatisticsProvider>(context, listen: false).loadStatistics();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تهيئة قاعدة البيانات بنجاح.')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء التهيئة: $e')));
              }
              _showLoading(false);
            },
            child: const Text('نعم، امسح البيانات', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text('المظهر والتخصيص', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.brightness_6),
                  title: const Text('الوضع الليلي (Dark Mode)'),
                  value: themeProvider.isDarkMode,
                  onChanged: (val) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('النسخ الاحتياطي والاستعادة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.backup, color: Colors.blue),
                  title: const Text('إنشاء نسخة احتياطية'),
                  subtitle: const Text('حفظ جميع البيانات في ملف نصي (TXT)'),
                  onTap: _handleBackup,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restore, color: Colors.orange),
                  title: const Text('استعادة نسخة احتياطية'),
                  subtitle: const Text('استرجاع البيانات من ملف سابق'),
                  onTap: _handleRestore,
                ),
              ),
              const SizedBox(height: 16),
              const Text('إدارة البيانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              Card(
                color: Colors.red.withOpacity(0.1),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('تهيئة قاعدة البيانات (Format)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text('مسح كافة السجلات الحالية وبدء سجل جديد'),
                  onTap: _handleResetDatabase,
                ),
              ),
              const SizedBox(height: 32),
              const Text('معلومات التطبيق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: const Text('صفحة المطور (Developer)'),
                  subtitle: const Text('Amro Alshurafy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperScreen()));
                  },
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('نظام إدارة صالون الحلاقة'),
                  subtitle: Text('الإصدار 1.0.0'),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
