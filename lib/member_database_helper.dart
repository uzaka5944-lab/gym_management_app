// lib/member_database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'member_workout_screen.dart'; // We'll use the Exercise class from here

class MemberDatabaseHelper {
  static final MemberDatabaseHelper instance = MemberDatabaseHelper._init();
  static Database? _database;

  MemberDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('member_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE exercises ( 
        id $idType, 
        name $textType,
        target $textType,
        bodyPart $textType,
        gifUrl $textType
      )
    ''');
  }

  // Method to get all exercises from the local database
  Future<List<Exercise>> getExercises() async {
    final db = await instance.database;
    final maps = await db.query('exercises', orderBy: 'name ASC');

    if (maps.isNotEmpty) {
      return maps.map((json) => Exercise.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // Method to save a list of exercises from the API to the local database
  Future<void> cacheExercises(List<Exercise> exercises) async {
    final db = await instance.database;
    final batch = db.batch();

    // Clear old data first to ensure the library is up to date
    batch.delete('exercises');

    // Insert new data
    for (final exercise in exercises) {
      batch.insert('exercises', {
        'id': exercise.id,
        'name': exercise.name,
        'target': exercise.target,
        'bodyPart': exercise.bodyPart,
        'gifUrl': exercise.gifUrl,
      });
    }

    await batch.commit(noResult: true);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
