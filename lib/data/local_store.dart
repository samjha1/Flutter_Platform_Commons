import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalStore {
  static Future<Database> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'movie_matcher.db');
    return openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            movie_taste TEXT NOT NULL,
            avatar TEXT,
            pending_sync INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE movies (
            id INTEGER PRIMARY KEY,
            imdb_id TEXT,
            title TEXT NOT NULL,
            overview TEXT,
            release_date TEXT,
            poster_path TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE saved_movies (
            user_local_id INTEGER NOT NULL,
            movie_id INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY(user_local_id, movie_id),
            FOREIGN KEY(user_local_id) REFERENCES users(local_id),
            FOREIGN KEY(movie_id) REFERENCES movies(id)
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumn(db, 'ALTER TABLE users ADD COLUMN first_name TEXT');
          await _addColumn(db, 'ALTER TABLE users ADD COLUMN last_name TEXT');
          await _addColumn(db, 'ALTER TABLE users ADD COLUMN avatar TEXT');
          await _addColumn(db, 'ALTER TABLE users ADD COLUMN pending_sync INTEGER NOT NULL DEFAULT 0');
          await _backfillUserNames(db);
        }
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS saved_movies');
          await db.execute('DROP TABLE IF EXISTS movies');
          await db.execute('''
            CREATE TABLE movies (
              id INTEGER PRIMARY KEY,
              imdb_id TEXT,
              title TEXT NOT NULL,
              overview TEXT,
              release_date TEXT,
              poster_path TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE saved_movies (
              user_local_id INTEGER NOT NULL,
              movie_id INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              PRIMARY KEY(user_local_id, movie_id),
              FOREIGN KEY(user_local_id) REFERENCES users(local_id),
              FOREIGN KEY(movie_id) REFERENCES movies(id)
            );
          ''');
        }
      },
    );
  }

  static Future<void> _addColumn(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (_) {
      // Column may already exist on partial upgrades.
    }
  }

  static Future<void> _backfillUserNames(Database db) async {
    final rows = await db.query('users');
    for (final row in rows) {
      final firstName = '${row['first_name'] ?? ''}'.trim();
      final lastName = '${row['last_name'] ?? ''}'.trim();
      if (firstName.isNotEmpty || lastName.isNotEmpty) continue;

      final legacyName = '${row['name'] ?? ''}'.trim();
      final parts = legacyName.split(' ').where((e) => e.isNotEmpty).toList();
      final firstNameValue = parts.isEmpty ? 'Unknown' : parts.first;
      final lastNameValue = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      await db.update(
        'users',
        {'first_name': firstNameValue, 'last_name': lastNameValue},
        where: 'local_id = ?',
        whereArgs: [row['local_id']],
      );
    }
  }
}
