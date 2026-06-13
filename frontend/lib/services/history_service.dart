import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../models/history_entry.dart';

/// Manages local SQLite history of grammar corrections.
class HistoryService {
  static Database? _db;

  static Future<Database> _getDb() async {
    if (_db != null) return _db!;

    // Use ffi for Windows desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final docDir = _getAppDataDir();
    final dbPath = p.join(docDir, 'history.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            input_text TEXT NOT NULL,
            output_text TEXT NOT NULL,
            elapsed_ms INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  static String _getAppDataDir() {
    final appData = Platform.environment['APPDATA'] ?? '.';
    final dir = Directory('$appData\\GrammarAssistant');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  /// Inserts a new history entry.
  static Future<void> insert(HistoryEntry entry) async {
    final db = await _getDb();
    await db.insert('history', entry.toMap());
  }

  /// Returns the 50 most recent history entries.
  static Future<List<HistoryEntry>> getRecent({int limit = 50}) async {
    final db = await _getDb();
    final maps = await db.query(
      'history',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map(HistoryEntry.fromMap).toList();
  }

  /// Clears all history.
  static Future<void> clearAll() async {
    final db = await _getDb();
    await db.delete('history');
  }
}
