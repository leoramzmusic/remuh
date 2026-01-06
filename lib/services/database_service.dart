import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/utils/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'remuh.db');

    Logger.info('Initializing database at $path');

    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        Logger.info('Creating database tables...');

        // Table for playlists
        await db.execute('''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            coverUrl TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        // Table for playlist-track relationship
        await db.execute('''
          CREATE TABLE playlist_tracks (
            playlistId INTEGER NOT NULL,
            trackId TEXT NOT NULL,
            position INTEGER NOT NULL,
            PRIMARY KEY (playlistId, trackId),
            FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE
          )
        ''');

        // Table for track statistics
        await db.execute('''
          CREATE TABLE track_stats (
            trackId TEXT PRIMARY KEY,
            isFavorite INTEGER DEFAULT 0,
            playCount INTEGER DEFAULT 0,
            lastPlayedAt TEXT
          )
        ''');

        // Table for track metadata overrides
        await db.execute('''
          CREATE TABLE track_overrides (
            trackId TEXT PRIMARY KEY,
            title TEXT,
            artist TEXT,
            album TEXT,
            genre TEXT,
            trackNumber INTEGER,
            discNumber INTEGER,
            artworkPath TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE track_stats (
              trackId TEXT PRIMARY KEY,
              isFavorite INTEGER DEFAULT 0,
              playCount INTEGER DEFAULT 0,
              lastPlayedAt TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE track_overrides (
              trackId TEXT PRIMARY KEY,
              title TEXT,
              artist TEXT,
              album TEXT,
              genre TEXT,
              trackNumber INTEGER,
              discNumber INTEGER
            )
          ''');
        }
        if (oldVersion < 4) {
          try {
            await db.execute(
              'ALTER TABLE track_overrides ADD COLUMN artworkPath TEXT',
            );
          } catch (e) {
            // Ignore if column already exists
            Logger.warning('Error adding artworkPath column: $e');
          }
        }
        if (oldVersion < 5) {
          try {
            await db.execute(
              'ALTER TABLE playlists ADD COLUMN description TEXT',
            );
            await db.execute('ALTER TABLE playlists ADD COLUMN coverUrl TEXT');
          } catch (e) {
            Logger.warning('Error adding playlist extra columns: $e');
          }
        }
      },
    );
  }
}
