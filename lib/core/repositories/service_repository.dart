import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/barber_service.dart';

class ServiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<BarberService>> getAllServices() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('barber_services');
    return List.generate(maps.length, (i) {
      return BarberService.fromMap(maps[i]);
    });
  }

  Future<int> addService(BarberService service) async {
    final db = await _dbHelper.database;
    return await db.insert('barber_services', service.toMap());
  }

  Future<int> deleteService(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'barber_services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
