import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('postboy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // NEW VERSION
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // --------------------------------------------------------
  // ---------------------- CREATE DB -----------------------
  // --------------------------------------------------------
  Future _createDB(Database db, int version) async {

    // ------------------ Environments ------------------
    await db.execute('''
    CREATE TABLE environments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        auth_type TEXT,
        username TEXT,
        password TEXT,
        token TEXT,
        custom_header_key TEXT,
        custom_header_value TEXT
        )
    ''');


    // ------------------ Requests ------------------
    await db.execute('''
      CREATE TABLE requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        method TEXT,
        url TEXT,
        headers TEXT,
        body TEXT,
        created_at TEXT,
        status_code INTEGER,
        is_saved INTEGER,


        environment_id INTEGER,
        auth_type TEXT,
        username TEXT,
        password TEXT,
        token TEXT,
        custom_header_key TEXT,
        custom_header_value TEXT,
        content_type TEXT,
        FOREIGN KEY (environment_id) REFERENCES environments(id) ON DELETE SET NULL
      )
    ''');

    // ------------------ Statistics ------------------
    await db.execute('''
      CREATE TABLE request_statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_requests INTEGER DEFAULT 0,
        successful INTEGER DEFAULT 0,
        failed INTEGER DEFAULT 0,
        last_updated TEXT
      )
    ''');

    await db.insert('request_statistics', {
      'total_requests': 0,
      'successful': 0,
      'failed': 0,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  // --------------------------------------------------------
  // ---------------------- UPGRADE DB ----------------------
  // --------------------------------------------------------
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {

    // v6 → Add environments + mapping
    if (oldVersion < 6) {
      await db.execute('''
      CREATE TABLE environments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          auth_type TEXT,
          username TEXT,
          password TEXT,
          token TEXT,
          custom_header_key TEXT,
          custom_header_value TEXT
      )
''');


    }

    // v7 → Add auth snapshot fields to requests (if missing)
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE requests ADD COLUMN environment_id INTEGER');
      await db.execute('ALTER TABLE requests ADD COLUMN username TEXT');
      await db.execute('ALTER TABLE requests ADD COLUMN password TEXT');
      await db.execute('ALTER TABLE requests ADD COLUMN token TEXT');
      await db.execute('ALTER TABLE requests ADD COLUMN custom_header_key TEXT');
      await db.execute('ALTER TABLE requests ADD COLUMN custom_header_value TEXT');
    }

    // Ensure statistics table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS request_statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_requests INTEGER DEFAULT 0,
        successful INTEGER DEFAULT 0,
        failed INTEGER DEFAULT 0,
        last_updated TEXT
      )
    ''');

    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM request_statistics')
    ) ?? 0;

    if (count == 0) {
      await db.insert('request_statistics', {
        'total_requests': 0,
        'successful': 0,
        'failed': 0,
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
  }

  // --------------------------------------------------------
  // ---------------------- STATISTICS ----------------------
  // --------------------------------------------------------
  Future<void> updateStatistics({bool? success}) async {
    final db = await database;
    final stats = await db.query('request_statistics', limit: 1);
    if (stats.isEmpty) return;

    int total = stats.first['total_requests'] as int;
    int successful = stats.first['successful'] as int;
    int failed = stats.first['failed'] as int;

    total += 1;
    if (success == true) successful += 1;
    if (success == false) failed += 1;

    await db.update(
      'request_statistics',
      {
        'total_requests': total,
        'successful': successful,
        'failed': failed,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [stats.first['id']],
    );
  }

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final stats = await db.query('request_statistics', limit: 1);

    if (stats.isEmpty) {
      return {'total_requests': 0, 'successful': 0, 'failed': 0};
    }

    final row = stats.first;
    return {
      'total_requests': row['total_requests'] as int,
      'successful': row['successful'] as int,
      'failed': row['failed'] as int,
    };
  }

  // --------------------------------------------------------
  // ------------------------ CLOSE -------------------------
  // --------------------------------------------------------
  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
