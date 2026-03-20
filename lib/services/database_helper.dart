import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calendar.db');
    return await openDatabase(
      path,
      version: 2, // 升级版本到 2 以触发字段迁移
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // 为旧版本数据库添加缺失的字段
          await db.execute('ALTER TABLE schedules ADD COLUMN groupId TEXT');
          await db.execute('ALTER TABLE schedules ADD COLUMN creatorName TEXT');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE schedules(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dateTime TEXT NOT NULL,
        location TEXT,
        groupId TEXT,      -- 新增字段
        creatorName TEXT   -- 新增字段
      )
    ''');
  }

  Future<int> insertSchedule(Schedule schedule) async {
    Database db = await database;
    return await db.insert('schedules', schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Schedule>> getSchedules() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('schedules');
    return List.generate(maps.length, (i) {
      return Schedule.fromMap(maps[i]);
    });
  }

  Future<int> updateSchedule(Schedule schedule) async {
    Database db = await database;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(String id) async {
    Database db = await database;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 新增：清空所有数据（用于同步云端数据时覆盖本地）
  Future<void> clearAllSchedules() async {
    Database db = await database;
    await db.delete('schedules');
  }
}
