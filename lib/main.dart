import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import 'app/movie_matcher_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  runApp(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(bootstrap.repository)],
      child: const MovieMatcherApp(),
    ),
  );
}