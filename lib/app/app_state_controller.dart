import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/app_repository.dart';

class AppStateController extends ChangeNotifier {
  AppStateController(this.repo) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      final online = !result.contains(ConnectivityResult.none);
      if (online) {
        await repo.syncPendingUsers();
        await refreshUsers();
      }
    });
    unawaited(init());
  }

  final AppRepository repo;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> movies = [];
  int userPage = 1;
  int moviePage = 1;
  bool loadingUsers = true;
  bool loadingMovies = false;
  bool initialMoviesLoaded = false;
  bool hasMoreMovies = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> init() async {
    await refreshUsers();
    await fetchNextMovies(reset: true);
  }

  Future<void> refreshUsers() async {
    loadingUsers = true;
    notifyListeners();
    userPage = 1;
    users = await repo.fetchUsersPage(userPage);
    loadingUsers = false;
    notifyListeners();
  }

  Future<void> loadMoreUsers() async {
    if (userPage >= repo.totalUserPages) return;
    userPage++;
    final next = await repo.fetchUsersPage(userPage);
    users = next;
    notifyListeners();
  }

  Future<void> fetchNextMovies({bool reset = false}) async {
    if (loadingMovies) return;
    if (!reset && !hasMoreMovies) return;
    loadingMovies = true;
    if (reset) {
      movies = [];
      moviePage = 1;
      initialMoviesLoaded = false;
      hasMoreMovies = true;
    }
    notifyListeners();

    final pageRows = await repo.fetchTrendingMovies(page: moviePage);
    if (pageRows.isEmpty) {
      hasMoreMovies = false;
    } else {
      final existingIds = movies.map((e) => e['id']).toSet();
      var addedAny = false;
      if (reset) {
        movies = pageRows;
        addedAny = true;
      } else {
        for (final row in pageRows) {
          if (!existingIds.contains(row['id'])) {
            movies.add(row);
            addedAny = true;
          }
        }
      }
      if (addedAny) {
        moviePage++;
      } else {
        hasMoreMovies = false;
      }
    }

    initialMoviesLoaded = true;
    loadingMovies = false;
    notifyListeners();
  }

  Future<void> addUser({required String name, required String taste}) async {
    await repo.addUser(name: name, movieTaste: taste);
    users = await repo.getUsersWithCounts();
    notifyListeners();
  }

  Future<void> toggleSave({
    required int userLocalId,
    required Map<String, dynamic> movie,
  }) async {
    await repo.toggleSavedMovie(userLocalId: userLocalId, movie: movie);
    users = await repo.getUsersWithCounts();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
