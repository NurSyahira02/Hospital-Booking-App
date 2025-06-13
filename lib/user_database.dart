import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'hash_helper.dart'; // ✅ Import the hashing helper

class UserDatabase {
  static final UserDatabase _instance = UserDatabase._internal();
  factory UserDatabase() => _instance;
  UserDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hospital_users.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    password TEXT,
    age TEXT,
    gender TEXT,
    address TEXT
  )
''');

      },
    );
  }

  // ✅ Registration: Hash password before storing
  Future<int> registerUser(Map<String, dynamic> user) async {
    final db = await database;

    // Hash the password before inserting
    final secureUser = Map<String, dynamic>.from(user);
    secureUser['password'] = HashHelper.hashPassword(user['password']);

    return await db.insert(
      'users',
      secureUser,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ✅ Login: Hash the input password before comparing
  Future<Map<String, dynamic>?> authenticate(
    String email,
    String password,
  ) async {
    final db = await database;

    final hashedPassword = HashHelper.hashPassword(password);

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }
}
