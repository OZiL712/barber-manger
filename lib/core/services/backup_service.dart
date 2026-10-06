import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _schemaVersion = "1.0.0";
  static const String _appIdentifier = "barber_manager";

  // ===================== CREATE BACKUP =====================

  Future<void> createBackup() async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> backupData = {
      'app_id': _appIdentifier,
      'schema_version': _schemaVersion,
      'backup_date': DateTime.now().toIso8601String(),
    };

    // Fetch all tables
    final tables = [
      'app_settings',
      'barber_services',
      'haircuts',
      'haircut_services',
      'worker_withdrawals',
      'owner_payments',
      'daily_expenses'
    ];

    for (String table in tables) {
      final rows = await db.query(table);
      backupData[table] = rows;
    }

    final String jsonString = jsonEncode(backupData);
    
    // Save to temp and share
    final directory = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File('${directory.path}/barber_backup_$timestamp.txt');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية لصالون الحلاقة');
  }

  // ===================== RESTORE BACKUP =====================

  Future<Map<String, dynamic>> previewBackup(String filePath) async {
    final file = File(filePath);
    final String content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    // Validate Identity
    if (data['app_id'] != _appIdentifier) {
      throw Exception('الملف لا ينتمي لهذا التطبيق.');
    }
    
    // Validate required tables exist
    if (!data.containsKey('haircuts') || !data.containsKey('barber_services')) {
      throw Exception('الملف تالف أو يفتقر إلى جداول أساسية.');
    }

    return data;
  }

  Future<void> restoreBackup(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;

    // 1. Create safety backup first
    await _createSafetyBackup(db);

    // 2. Perform restore inside a transaction (Rollback on failure)
    try {
      await db.transaction((txn) async {
        final tables = [
          'app_settings',
          'barber_services',
          'haircuts',
          'haircut_services',
          'worker_withdrawals',
          'owner_payments',
          'daily_expenses'
        ];

        // Clear existing data
        for (String table in tables.reversed) {
          await txn.delete(table);
        }

        // Insert new data
        for (String table in tables) {
          if (data.containsKey(table)) {
            final List<dynamic> rows = data[table];
            for (var row in rows) {
              await txn.insert(table, Map<String, dynamic>.from(row));
            }
          }
        }
      });
    } catch (e) {
      // If transaction fails, the safety backup can be restored manually if needed, 
      // but sqflite transaction rolls back automatically on exception.
      throw Exception('فشل استعادة النسخة الاحتياطية. تم إلغاء التغييرات: $e');
    }
  }

  Future<void> _createSafetyBackup(Database db) async {
    final Map<String, dynamic> safetyData = {
      'app_id': _appIdentifier,
      'schema_version': _schemaVersion,
      'backup_date': DateTime.now().toIso8601String(),
      'type': 'safety_backup',
    };

    final tables = [
      'app_settings', 'barber_services', 'haircuts', 'haircut_services',
      'worker_withdrawals', 'owner_payments', 'daily_expenses'
    ];

    for (String table in tables) {
      final rows = await db.query(table);
      safetyData[table] = rows;
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/safety_backup_latest.txt');
    await file.writeAsString(jsonEncode(safetyData));
  }
}
