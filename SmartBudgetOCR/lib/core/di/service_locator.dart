import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';

/// Simple service locator. No business logic in UI - inject services here.
class ServiceLocator {
  ServiceLocator._();

  // Lazy initialization - static fields created on first access
  static AuthService? _authService;
  static DatabaseService? _databaseService;
  static ApiClient? _apiClient;
  static SyncService? _syncService;

  static AuthService get auth {
    _authService ??= AuthService();
    return _authService!;
  }

  static DatabaseService get database {
    _databaseService ??= DatabaseService();
    return _databaseService!;
  }

  static ApiClient get api {
    _apiClient ??= ApiClient(authService: auth);
    return _apiClient!;
  }

  static SyncService get sync {
    _syncService ??= SyncService(
      authService: auth,
      apiClient: api,
      databaseService: database,
    );
    return _syncService!;
  }
}
