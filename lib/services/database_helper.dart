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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE schedules ADD COLUMN groupId TEXT');
          await db.execute('ALTER TABLE schedules ADD COLUMN creatorName TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE schedules ADD COLUMN updatedAt TEXT');
          await db.execute('ALTER TABLE schedules ADD COLUMN isDeleted INTEGER DEFAULT 0');
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
        groupId TEXT,
        creatorName TEXT,
        updatedAt TEXT,
        isDeleted INTEGER DEFAULT 0
      )
    ''');
  }

  // 1. 插入或更新
  Future<int> insertSchedule(Schedule schedule) async {
    Database db = await database;
    return await db.insert('schedules', schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 2. 获取所有活跃日程 - 【核心修复】：增加强制过滤
  Future<List<Schedule>> getActiveSchedules() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'isDeleted = 0 OR isDeleted IS NULL',
    );
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  // 3. 物理删除
  Future<int> physicalDelete(String id) async {
    Database db = await database;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // 4. 获取特定小组的日程 - 【核心修复】：必须过滤已删除记录
  Future<List<Schedule>> getSchedulesByGroupId(String groupId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'groupId = ? AND (isDeleted = 0 OR isDeleted IS NULL)',
      whereArgs: [groupId],
    );
    return maps.map((e) => Schedule.fromMap(e)).toList();
  }

  // 5. 获取脏数据用于同步
  Future<List<Schedule>> getDirtySchedules(DateTime lastSyncTime) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'updatedAt > ?',
      whereArgs: [lastSyncTime.toUtc().toIso8601String()],
    );
    return maps.map((e) => Schedule.fromMap(e)).toList();
  }

  // 6. 逻辑删除标记
  Future<int> markAsDeleted(String id) async {
    Database db = await database;
    return await db.update(
      'schedules',
      {
        'isDeleted': 1,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllSchedules() async {
    Database db = await database;
    await db.delete('schedules');
  }
}
