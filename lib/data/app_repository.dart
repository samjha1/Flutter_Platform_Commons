import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../core/env.dart';
import '../domain/models/movie_model.dart';
import '../domain/models/reqres_models.dart';

const _reqresBase = 'https://reqres.in/api';
const _omdbBase = 'https://www.omdbapi.com';
const _omdbSearchTerms = <String>[
  'movie',
  'love',
  'star',
  'night',
  'world',
  'life',
  'man',
  'war',
  'home',
  'time',
];

class AppRepository {
  AppRepository({required this.db});

  final Database db;
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 12)));
  final StreamController<bool> reconnecting = StreamController<bool>.broadcast();
  final StreamController<int> dataChanged = StreamController<int>.broadcast();

  bool weakConnectionMode = false;
  double failureRate = 0.3;
  int totalUserPages = 1;

  Future<T> _safeRequest<T>(Future<T> Function() request) async {
    var attempt = 0;
    Object? lastError;
    while (attempt < 4) {
      try {
        if (weakConnectionMode && Random().nextDouble() < failureRate) {
          throw DioException(
            requestOptions: RequestOptions(path: 'simulated-error'),
            type: DioExceptionType.connectionError,
            message: 'Simulated weak network failure',
          );
        }
        final result = await request();
        if (attempt > 0) reconnecting.add(false);
        return result;
      } catch (error) {
        lastError = error;
        attempt += 1;
        if (attempt >= 4) break;
        reconnecting.add(true);
        await Future<void>.delayed(Duration(milliseconds: 400 * (1 << (attempt - 1))));
      }
    }
    reconnecting.add(false);
    throw lastError ?? Exception('Unknown network error');
  }

  Future<List<Map<String, dynamic>>> fetchUsersPage(int page) async {
    try {
      final response = await _safeRequest(
        () => _dio.get(
          '$_reqresBase/users',
          queryParameters: {'page': page},
          options: Options(headers: {'x-api-key': Env.reqresApiKey}),
        ),
      );
      final pageData = ReqresUsersPage.fromJson((response.data as Map).cast<String, dynamic>());
      totalUserPages = pageData.totalPages;
      for (final user in pageData.users) {
        final exists = await db.query('users', where: 'server_id = ?', whereArgs: [user.serverId]);
        if (exists.isEmpty) {
          await db.insert('users', user.toDb());
        } else {
          await db.update(
            'users',
            {
              'first_name': user.firstName,
              'last_name': user.lastName,
              'avatar': user.avatar,
            },
            where: 'server_id = ?',
            whereArgs: [user.serverId],
          );
        }
      }
    } catch (_) {
      // Keep using local data on failure.
    }
    return getUsersWithCounts();
  }

  Future<List<Map<String, dynamic>>> getUsersWithCounts() {
    return db.rawQuery('''
      SELECT u.*, COUNT(sm.movie_id) AS saved_count
      FROM users u
      LEFT JOIN saved_movies sm ON sm.user_local_id = u.local_id
      GROUP BY u.local_id
      ORDER BY u.local_id ASC
    ''');
  }

  Future<void> addUser({
    required String name,
    required String movieTaste,
  }) async {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    final firstName = parts.isEmpty ? 'Unknown' : parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final online = !(await Connectivity().checkConnectivity()).contains(ConnectivityResult.none);

    final localId = await db.insert('users', {
      'first_name': firstName,
      'last_name': lastName,
      'movie_taste': movieTaste.trim(),
      'avatar': null,
      'pending_sync': online ? 0 : 1,
    });

    if (online) {
      try {
        final response = await _safeRequest(
          () => _dio.post(
            '$_reqresBase/users',
            data: {'name': name, 'job': movieTaste},
            options: Options(headers: {'x-api-key': Env.reqresApiKey}),
          ),
        );
        final created = ReqresCreateUserResponse.fromJson((response.data as Map).cast<String, dynamic>());
        await db.update(
          'users',
          {'server_id': created.parsedId ?? localId, 'pending_sync': 0},
          where: 'local_id = ?',
          whereArgs: [localId],
        );
      } catch (_) {
        await db.update(
          'users',
          {'pending_sync': 1},
          where: 'local_id = ?',
          whereArgs: [localId],
        );
      }
    }
    dataChanged.add(DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> syncPendingUsers() async {
    final online = !(await Connectivity().checkConnectivity()).contains(ConnectivityResult.none);
    if (!online) return;

    final pending = await db.query('users', where: 'pending_sync = 1');
    for (final user in pending) {
      try {
        final fullName = '${user['first_name']} ${user['last_name']}'.trim();
        final response = await _safeRequest(
          () => _dio.post(
            '$_reqresBase/users',
            data: {'name': fullName, 'job': user['movie_taste']},
            options: Options(headers: {'x-api-key': Env.reqresApiKey}),
          ),
        );
        final created = ReqresCreateUserResponse.fromJson((response.data as Map).cast<String, dynamic>());
        await db.update(
          'users',
          {'server_id': created.parsedId ?? user['local_id'], 'pending_sync': 0},
          where: 'local_id = ?',
          whereArgs: [user['local_id']],
        );
      } catch (_) {
        // Keep record pending for the next attempt.
      }
    }
    dataChanged.add(DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>> fetchTrendingMovies({required int page}) async {
    final searchTerm = _omdbSearchTerms[(page - 1) % _omdbSearchTerms.length];
    final omdbPage = ((page - 1) ~/ _omdbSearchTerms.length) + 1;
    try {
      final response = await _safeRequest(
        () => _dio.get(
          _omdbBase,
          queryParameters: {
            's': searchTerm,
            'page': omdbPage,
            'apikey': Env.omdbApiKey,
          },
        ),
      );
      final body = (response.data as Map).cast<String, dynamic>();
      if (body['Response'] == 'True') {
        final list = (body['Search'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((e) => MovieModel.fromOmdbList(e.cast<String, dynamic>()))
            .toList();
        if (list.isEmpty) return _moviesForLogicalPage(page);
        final ids = <int>[];
        for (final movie in list) {
          await _upsertMovie(movie.toDb());
          ids.add(movie.id);
        }
        final placeholders = List.filled(ids.length, '?').join(',');
        final rows = await db.rawQuery(
          'SELECT * FROM movies WHERE id IN ($placeholders)',
          ids,
        );
        final byId = <int, Map<String, dynamic>>{
          for (final row in rows) row['id'] as int: row,
        };
        return ids
            .map((id) => byId[id])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
    } catch (_) {
      // Fall back to local cache when offline / API down.
    }
    return _moviesForLogicalPage(page);
  }

  Future<List<Map<String, dynamic>>> _moviesForLogicalPage(int page) async {
    const pageSize = 10;
    return db.query(
      'movies',
      orderBy: 'release_date DESC, title ASC',
      limit: pageSize,
      offset: (page - 1) * pageSize,
    );
  }

  Future<void> _upsertMovie(Map<String, dynamic> movie) async {
    await db.insert('movies', movie, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>> getMovieDetail(Map<String, dynamic> movie) async {
    final imdbId = movie['imdb_id'] as String?;
    if (imdbId == null || imdbId.isEmpty || Env.omdbApiKey.isEmpty) return movie;
    try {
      final response = await _safeRequest(
        () => _dio.get(
          _omdbBase,
          queryParameters: {'apikey': Env.omdbApiKey, 'i': imdbId},
        ),
      );
      final body = (response.data as Map).cast<String, dynamic>();
      if (body['Response'] != 'True') return movie;
      final omdbMovie = MovieModel.fromOmdbDetail(
        json: body,
        id: movie['id'] as int,
        fallbackTitle: movie['title'] as String?,
        fallbackOverview: movie['overview'] as String?,
        fallbackReleaseDate: movie['release_date'] as String?,
        fallbackPosterPath: movie['poster_path'] as String?,
        fallbackImdbId: imdbId,
      );
      await _upsertMovie(omdbMovie.toDb());
      return omdbMovie.toDb();
    } catch (_) {
      return movie;
    }
  }

  Future<bool> isMovieSaved({
    required int userLocalId,
    required int movieId,
  }) async {
    final rows = await db.query(
      'saved_movies',
      where: 'user_local_id = ? AND movie_id = ?',
      whereArgs: [userLocalId, movieId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> toggleSavedMovie({
    required int userLocalId,
    required Map<String, dynamic> movie,
  }) async {
    await _upsertMovie({
      'id': movie['id'],
      'imdb_id': movie['imdb_id'],
      'title': movie['title'],
      'overview': movie['overview'],
      'release_date': movie['release_date'],
      'poster_path': movie['poster_path'],
    });
    final alreadySaved = await isMovieSaved(userLocalId: userLocalId, movieId: movie['id'] as int);
    if (alreadySaved) {
      await db.delete(
        'saved_movies',
        where: 'user_local_id = ? AND movie_id = ?',
        whereArgs: [userLocalId, movie['id']],
      );
    } else {
      await db.insert('saved_movies', {
        'user_local_id': userLocalId,
        'movie_id': movie['id'],
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    dataChanged.add(DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>> getSavedMoviesForUser(int userLocalId) {
    return db.rawQuery('''
      SELECT m.*
      FROM saved_movies sm
      INNER JOIN movies m ON m.id = sm.movie_id
      WHERE sm.user_local_id = ?
      ORDER BY sm.created_at DESC
    ''', [userLocalId]);
  }

  Future<int> movieSaveCount(int movieId) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM saved_movies WHERE movie_id = ?', [movieId]);
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> usersForMovie(int movieId) {
    return db.rawQuery('''
      SELECT u.*
      FROM saved_movies sm
      INNER JOIN users u ON u.local_id = sm.user_local_id
      WHERE sm.movie_id = ?
    ''', [movieId]);
  }

  Future<List<Map<String, dynamic>>> matches() {
    return db.rawQuery('''
      SELECT m.*, COUNT(sm.user_local_id) AS save_count
      FROM saved_movies sm
      INNER JOIN movies m ON m.id = sm.movie_id
      GROUP BY m.id
      HAVING COUNT(sm.user_local_id) >= 2
      ORDER BY save_count DESC, m.title ASC
    ''');
  }

  Future<int> userCount() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM users');
    return (rows.first['c'] as int?) ?? 0;
  }

  void dispose() {
    reconnecting.close();
    dataChanged.close();
  }
}
