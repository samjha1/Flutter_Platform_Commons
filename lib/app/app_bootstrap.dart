import '../data/app_repository.dart';
import '../data/local_store.dart';

class AppBootstrap {
  AppBootstrap(this.repository);
  final AppRepository repository;

  static Future<AppBootstrap> initialize() async {
    final db = await LocalStore.open();
    final repository = AppRepository(db: db);
    return AppBootstrap(repository);
  }
}
