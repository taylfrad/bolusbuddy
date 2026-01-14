import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/models/meal_estimate.dart';

class MealHistoryDb {
  static const _dbName = 'bolusbuddy.db';
  static const _table = 'meal_history';
  static const _schemaVersion = 1;

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) {
      return _db!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(dir.path, _dbName);
    _db = await openDatabase(
      dbPath,
      version: _schemaVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            created_at INTEGER NOT NULL,
            image_hash TEXT NOT NULL,
            payload TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> insertMeal(MealEstimate meal) async {
    final db = await _open();
    await db.insert(
      _table,
      {
        'id': meal.imageHash,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'image_hash': meal.imageHash,
        'payload': jsonEncode(meal.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MealEstimate>> fetchMeals() async {
    final db = await _open();
    final rows = await db.query(
      _table,
      orderBy: 'created_at DESC',
    );
    return rows
        .map((row) =>
            MealEstimate.fromJson(jsonDecode(row['payload'] as String)))
        .toList();
  }

  Future<void> clear() async {
    final db = await _open();
    await db.delete(_table);
  }
}
