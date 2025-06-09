//database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'order.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'hospital_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medication_orders (
        id TEXT PRIMARY KEY,
        patientName TEXT,
        medications TEXT,
        pickupLocation TEXT,
        pickupDateTime TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        patientName TEXT,
        dateTime TEXT
      )
    ''');
  }

  Future<void> insertAppointment(
    String id,
    String patientName,
    DateTime dateTime,
  ) async {
    final db = await database;
    await db.insert('appointments', {
      'id': id,
      'patientName': patientName,
      'dateTime': dateTime.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchPastAppointments(
    String patientName,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.query(
      'appointments',
      where: 'patientName = ? AND dateTime < ?',
      whereArgs: [patientName, now],
      orderBy: 'dateTime DESC',
    );
  }

  // existing medication order methods remain unchanged...
}
