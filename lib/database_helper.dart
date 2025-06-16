import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'hospital_app.db');
    return await openDatabase(
      path,
      version: 3, // ✅ Updated version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        phone TEXT,
        gender TEXT,
        password TEXT,
        age TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_email TEXT,
        doctor TEXT,
        dateTime TEXT,
        reason TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_orders(
        id TEXT PRIMARY KEY,
        patient_name TEXT,
        patient_email TEXT,
        medications TEXT,
        quantity INTEGER,
        is_child BOOLEAN,
        delivery_method TEXT,
        address TEXT,
        pickup_location TEXT,
        pickup_datetime TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE feedback(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT,
        rating INTEGER,
        comment TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // You can add specific upgrade logic if needed later
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE appointments ADD COLUMN reason TEXT");
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS medication_orders');
      await db.execute('''
        CREATE TABLE medication_orders(
          id TEXT PRIMARY KEY,
          patient_name TEXT,
          patient_email TEXT,
          medications TEXT,
          quantity INTEGER,
          is_child BOOLEAN,
          delivery_method TEXT,
          address TEXT,
          pickup_location TEXT,
          pickup_datetime TEXT,
          status TEXT
        )
      ''');
    }
  }

  Future<int> registerUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmailAndPassword(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    return await db.insert('appointments', appointment);
  }

  Future<List<Map<String, dynamic>>> getAppointmentsForPatient(String email) async {
    final db = await database;
    return await db.query(
      'appointments',
      where: 'patient_email = ?',
      whereArgs: [email],
    );
  }

  Future<int> insertMedicationOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('medication_orders', order);
  }

  Future<List<Map<String, dynamic>>> getAllMedicationOrders() async {
    final db = await database;
    return await db.query('medication_orders');
  }

  Future<int> deleteMedicationOrder(int id) async {
    final db = await database;
    return await db.delete(
      'medication_orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertFeedback(Map<String, dynamic> feedback) async {
    final db = await database;
    await db.insert('feedback', feedback);
  }
}
