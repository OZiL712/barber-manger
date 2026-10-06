import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "barber_manager.db";
  static const _databaseVersion = 4;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    // 1. App Settings
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    // 2. Barber Services (e.g. Head, Beard, Scrub)
    await db.execute('''
      CREATE TABLE barber_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Insert default services
    final defaultServices = ['قص شعر', 'لحية', 'صنفرة', 'صبغة', 'أخرى'];
    for (var service in defaultServices) {
      await db.insert('barber_services', {'name': service});
    }

    // 3. Haircuts
    await db.execute('''
      CREATE TABLE haircuts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_number TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        price REAL NOT NULL,
        amount_received REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Haircut Services (Many-to-Many relation)
    await db.execute('''
      CREATE TABLE haircut_services (
        haircut_id INTEGER NOT NULL,
        service_id INTEGER NOT NULL,
        PRIMARY KEY (haircut_id, service_id),
        FOREIGN KEY (haircut_id) REFERENCES haircuts (id) ON DELETE CASCADE,
        FOREIGN KEY (service_id) REFERENCES barber_services (id) ON DELETE CASCADE
      )
    ''');

    // 5. Worker Withdrawals
    await db.execute('''
      CREATE TABLE worker_withdrawals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_number TEXT NOT NULL UNIQUE,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 6. Owner Payments (Deliveries)
    await db.execute('''
      CREATE TABLE owner_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 7. Daily Expenses (entered manually)
    await db.execute('''
      CREATE TABLE daily_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 8. Worker Deposits
    await db.execute('''
      CREATE TABLE worker_deposits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_number TEXT NOT NULL UNIQUE,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE haircuts ADD COLUMN notes TEXT');
      } catch (e) {} // Ignore if exists
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE worker_deposits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_number TEXT NOT NULL UNIQUE,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      } catch (e) {}
      
      try {
        await db.execute('UPDATE barber_services SET name = "صنفرة" WHERE name = "تنظيف" OR name = "تنضيف"');
      } catch (e) {}
    }
  }

  // Helper method to close the database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
