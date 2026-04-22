import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/green_journal_entry.dart';

class JournalDbHelper {
  static final JournalDbHelper instance = JournalDbHelper._init();

  static Database? _database;

  JournalDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('green_journal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE green_journal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT NOT NULL,
        eco_points INTEGER NOT NULL,
        entry_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<GreenJournalEntry> insertEntry(GreenJournalEntry entry) async {
    final db = await database;
    final id = await db.insert('green_journal', entry.toMap());
    return entry.copyWith(id: id);
  }

  Future<List<GreenJournalEntry>> getAllEntries() async {
    final db = await database;
    final result = await db.query(
      'green_journal',
      orderBy: 'entry_date DESC, id DESC',
    );

    return result.map((map) => GreenJournalEntry.fromMap(map)).toList();
  }

  Future<int> updateEntry(GreenJournalEntry entry) async {
    final db = await database;
    return db.update(
      'green_journal',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete(
      'green_journal',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getTotalEntriesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM green_journal',
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getTotalEcoPoints() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(eco_points) as total FROM green_journal',
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> getThisWeekEntriesCount() async {
    final db = await database;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    ).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM green_journal WHERE entry_date >= ?',
      [start],
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}