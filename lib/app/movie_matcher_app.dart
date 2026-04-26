import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../presentation/pages/users_page.dart';
import 'providers.dart';
import 'theme.dart';
import 'workmanager_dispatcher.dart';

export 'app_bootstrap.dart';
export 'providers.dart' show repositoryProvider, appStateProvider, syncTaskName;

class MovieMatcherApp extends ConsumerStatefulWidget {
  const MovieMatcherApp({super.key});

  @override
  ConsumerState<MovieMatcherApp> createState() => _MovieMatcherAppState();
}

class _MovieMatcherAppState extends ConsumerState<MovieMatcherApp> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
    _initializeBackgroundSync();
  }

  Future<void> _initializeBackgroundSync() async {
    if (kIsWeb) return;
    try {
      if (!(Platform.isAndroid || Platform.isIOS)) return;
    } catch (_) {
      return;
    }
    try {
      await Workmanager().initialize(workmanagerDispatcher);
      await Workmanager().registerPeriodicTask(
        syncTaskName,
        syncTaskName,
        frequency: const Duration(hours: 1),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (_) {
      // Background sync is best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Matcher',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const UsersPage(),
    );
  }
}
