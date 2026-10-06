import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';

class ThemeProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['is_dark_mode']);
      if (result.isNotEmpty) {
        _isDarkMode = result.first['value'] == 'true';
        notifyListeners();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final db = await _dbHelper.database;
      final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['is_dark_mode']);
      if (result.isEmpty) {
        await db.insert('app_settings', {'key': 'is_dark_mode', 'value': _isDarkMode.toString()});
      } else {
        await db.update('app_settings', {'value': _isDarkMode.toString()}, where: 'key = ?', whereArgs: ['is_dark_mode']);
      }
    } catch (e) {
      // ignore
    }
  }
}
