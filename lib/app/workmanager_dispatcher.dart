import 'package:workmanager/workmanager.dart';

import '../data/app_repository.dart';
import '../data/local_store.dart';

@pragma('vm:entry-point')
void workmanagerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = await LocalStore.open();
    final repository = AppRepository(db: db);
    await repository.syncPendingUsers();
    repository.dispose();
    return true;
  });
}
