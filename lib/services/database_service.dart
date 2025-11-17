import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/photo.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'obscura_sim.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos(
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        capturedAt TEXT NOT NULL,
        filter INTEGER NOT NULL,
        status INTEGER NOT NULL,
        motionBlur REAL,
        thumbnailData BLOB
      )
    ''');
  }

  Future<void> insertPhoto(Photo photo) async {
    final db = await database;
    await db.insert(
      'photos',
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Photo>> getAllPhotos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      orderBy: 'capturedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Photo.fromMap(maps[i]);
    });
  }

  Future<void> updatePhoto(Photo photo) async {
    final db = await database;
    await db.update(
      'photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}