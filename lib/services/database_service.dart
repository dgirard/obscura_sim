import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/photo.dart';
import 'logger_service.dart';

class DatabaseService {
  static Database? _database;

  // Version actuelle de la base de données
  static const int _currentVersion = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'obscura_sim.db');
    return await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos(
        id INTEGER PRIMARY KEY,
        path TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        filter INTEGER NOT NULL,
        status INTEGER NOT NULL,
        motion_blur REAL,
        is_portrait INTEGER DEFAULT 0,
        thumbnail BLOB
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.gallery('Database migration: $oldVersion -> $newVersion');

    // Migration incrémentale préservant les données
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(db, version);
    }
  }

  Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 2:
        // Migration v1 -> v2: Ajout de motion_blur (si non existant)
        await _addColumnIfNotExists(db, 'photos', 'motion_blur', 'REAL');
        break;
      case 3:
        // Migration v2 -> v3: Ajout de is_portrait
        await _addColumnIfNotExists(db, 'photos', 'is_portrait', 'INTEGER DEFAULT 0');
        break;
      case 4:
        // Migration v3 -> v4: Ajout de thumbnail pour le cache
        await _addColumnIfNotExists(db, 'photos', 'thumbnail', 'BLOB');
        break;
    }
  }

  /// Ajoute une colonne si elle n'existe pas déjà.
  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    try {
      // Vérifier si la colonne existe
      final result = await db.rawQuery('PRAGMA table_info($table)');
      final columnExists = result.any((row) => row['name'] == column);

      if (!columnExists) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
        AppLogger.gallery('Added column $column to $table');
      }
    } catch (e) {
      AppLogger.error('Migration error for column $column', e);
    }
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
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Photo.fromMap(maps[i]);
    });
  }

  /// Récupère les photos avec pagination.
  ///
  /// [limit] : nombre de photos à récupérer
  /// [offset] : position de départ
  /// [status] : filtrer par statut (optionnel)
  Future<List<Photo>> getPhotosPaginated({
    required int limit,
    required int offset,
    PhotoStatus? status,
  }) async {
    final db = await database;

    String? where;
    List<dynamic>? whereArgs;

    if (status != null) {
      where = 'status = ?';
      whereArgs = [status.index];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return Photo.fromMap(maps[i]);
    });
  }

  /// Compte le nombre total de photos.
  Future<int> getPhotosCount({PhotoStatus? status}) async {
    final db = await database;

    String query = 'SELECT COUNT(*) as count FROM photos';
    List<dynamic>? args;

    if (status != null) {
      query += ' WHERE status = ?';
      args = [status.index];
    }

    final result = await db.rawQuery(query, args);
    return result.first['count'] as int;
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

  Future<void> deletePhoto(int id) async {
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