import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_repository.dart';
import 'app_state_controller.dart';

const syncTaskName = 'pending-user-sync';

final repositoryProvider = Provider<AppRepository>((ref) => throw UnimplementedError());
final appStateProvider = ChangeNotifierProvider<AppStateController>(
  (ref) => AppStateController(ref.read(repositoryProvider)),
);
