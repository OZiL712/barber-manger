import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/haircut.dart';
import '../models/barber_service.dart';

class HaircutRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addHaircut(Haircut haircut) async {
    // Ensure timestamps are set
    final now = DateTime.now().toIso8601String();
    final Haircut haircutWithTimestamps = Haircut(
      id: haircut.id,
      operationNumber: haircut.operationNumber,
      date: haircut.date,
      time: haircut.time,
      price: haircut.price,
      amountReceived: haircut.amountReceived,
      notes: haircut.notes,
      createdAt: haircut.createdAt.isNotEmpty ? haircut.createdAt : now,
      updatedAt: now,
      services: haircut.services,
    );
    final db = await _dbHelper.database;
    int haircutId = 0;
    await db.transaction((txn) async {
      haircutId = await txn.insert('haircuts', haircutWithTimestamps.toMap());
      for (var service in haircutWithTimestamps.services) {
        await txn.insert('haircut_services', {
          'haircut_id': haircutId,
          'service_id': service.id,
        });
      }
    });
    return haircutId;

  }

  Future<List<Haircut>> getAllHaircuts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> haircutMaps = await db.query('haircuts', orderBy: 'date DESC, id DESC');

    List<Haircut> haircuts = [];
    for (var map in haircutMaps) {
      final int id = map['id'];
      
      final List<Map<String, dynamic>> serviceMaps = await db.rawQuery('''
        SELECT s.* FROM barber_services s
        INNER JOIN haircut_services hs ON s.id = hs.service_id
        WHERE hs.haircut_id = ?
      ''', [id]);

      List<BarberService> services = serviceMaps.map((s) => BarberService.fromMap(s)).toList();

      haircuts.add(Haircut.fromMap(map, services));
    }

    return haircuts;
  }

  Future<int> updateHaircut(Haircut haircut) async {
    final db = await _dbHelper.database;
    int result = 0;

    await db.transaction((txn) async {
      result = await txn.update(
        'haircuts',
        haircut.toMap(),
        where: 'id = ?',
        whereArgs: [haircut.id],
      );

      // Update services by deleting old ones and inserting new ones
      await txn.delete('haircut_services', where: 'haircut_id = ?', whereArgs: [haircut.id]);

      for (var service in haircut.services) {
        await txn.insert('haircut_services', {
          'haircut_id': haircut.id,
          'service_id': service.id,
        });
      }
    });

    return result;
  }

  Future<int> deleteHaircut(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'haircuts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Haircut>> getHaircutsByDateRange(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> haircutMaps = await db.query(
      'haircuts',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, id DESC',
    );

    List<Haircut> haircuts = [];
    for (var map in haircutMaps) {
      final int id = map['id'];
      
      final List<Map<String, dynamic>> serviceMaps = await db.rawQuery('''
        SELECT s.* FROM barber_services s
        INNER JOIN haircut_services hs ON s.id = hs.service_id
        WHERE hs.haircut_id = ?
      ''', [id]);

      List<BarberService> services = serviceMaps.map((s) => BarberService.fromMap(s)).toList();

      haircuts.add(Haircut.fromMap(map, services));
    }

    return haircuts;
  }
}
