import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../models/usage_stats.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chat_app.db');
    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions(
            id TEXT PRIMARY KEY,
            title TEXT,
            lastUpdated TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            sessionId TEXT,
            role TEXT,
            content TEXT,
            timestamp TEXT,
            FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
          )
        ''');
        await _createUsageTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createUsageTable(db);
        }
      },
    );
  }

  Future<void> _createUsageTable(Database db) async {
    await db.execute('''
      CREATE TABLE usage(
        id TEXT PRIMARY KEY,
        model TEXT,
        cost REAL,
        promptTokens INTEGER,
        completionTokens INTEGER,
        timestamp TEXT
      )
    ''');
  }

  // Session Operations
  Future<void> insertSession(ChatSession session) async {
    final db = await database;
    await db.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatSession>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sessions', orderBy: 'lastUpdated DESC');
    return List.generate(maps.length, (i) => ChatSession.fromMap(maps[i]));
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    // Delete messages explicitly: the cascade only covers rows created while
    // foreign keys were enabled, and older installs may have orphans.
    await db.delete('messages', where: 'sessionId = ?', whereArgs: [id]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  // Message Operations
  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert('messages', message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  Future<void> deleteMessagesAfter(String sessionId, DateTime timestamp) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'sessionId = ? AND timestamp > ?',
      whereArgs: [sessionId, timestamp.toIso8601String()],
    );
  }

  // Usage Operations
  Future<void> insertUsage(UsageRecord record) async {
    final db = await database;
    await db.insert('usage', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UsageStats> getUsageStats({int topModelsLimit = 5}) async {
    final db = await database;

    final totals = (await db.rawQuery('''
      SELECT COUNT(*) AS requests,
             SUM(cost) AS cost,
             SUM(promptTokens) AS promptTokens,
             SUM(completionTokens) AS completionTokens
      FROM usage
    ''')).first;

    final topModels = (await db.rawQuery('''
      SELECT model,
             COUNT(*) AS requests,
             SUM(cost) AS cost,
             SUM(promptTokens) AS promptTokens,
             SUM(completionTokens) AS completionTokens
      FROM usage
      GROUP BY model
      ORDER BY cost DESC, requests DESC
      LIMIT ?
    ''', [topModelsLimit]))
        .map((row) => ModelUsage(
              model: row['model'] as String,
              requests: (row['requests'] as num).toInt(),
              cost: ((row['cost'] ?? 0) as num).toDouble(),
              promptTokens: ((row['promptTokens'] ?? 0) as num).toInt(),
              completionTokens: ((row['completionTokens'] ?? 0) as num).toInt(),
            ))
        .toList();

    return UsageStats(
      totalCost: ((totals['cost'] ?? 0) as num).toDouble(),
      totalRequests: (totals['requests'] as num).toInt(),
      promptTokens: ((totals['promptTokens'] ?? 0) as num).toInt(),
      completionTokens: ((totals['completionTokens'] ?? 0) as num).toInt(),
      topModels: topModels,
    );
  }
}
