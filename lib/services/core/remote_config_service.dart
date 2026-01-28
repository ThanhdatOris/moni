import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:moni/services/core/environment_service.dart';
import '../core/logging_service.dart';

/// Service quản lý cấu hình từ xa (Firebase Remote Config)
/// Giúp thay đổi logic/params mà không cần update app store
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Keys
  static const String _keyAiModelName = 'ai_model_name';
  static const String _keyAiApiKey =
      'ai_custom_api_key'; // Optional: Backup key
  static const String _keyAiPromptTemplate = 'ai_prompt_template';
  static const String _keyMaintenanceMode = 'maintenance_mode';
  static const String _keyMinVersion = 'min_app_version';

  // Defaults
  final Map<String, dynamic> _defaults = {
    _keyAiModelName: 'gemini-2.5-flash',
    _keyAiApiKey: EnvironmentService.geminiApiKey,
    _keyAiPromptTemplate: 'Bạn là chuyên gia tài chính cá nhân...',
    _keyMaintenanceMode: false,
    _keyMinVersion: '1.0.0',
  };

  /// Khởi tạo và fetch config
  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(_defaults);

      // Dev mode: fetch timeout thấp để test nhanh
      // Prod mode: nên để cao hơn (ví dụ 12h) để tiết kiệm request
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(
            minutes: 5,
          ), // 5 phút check 1 lần
        ),
      );

      await _fetchAndActivate();
      logInfo('✅ Remote Config initialized');
    } catch (e) {
      logError('❌ Lỗi khởi tạo Remote Config', error: e);
    }
  }

  Future<void> _fetchAndActivate() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        logInfo('🔄 Remote Config params updated from server');
      }
    } catch (e) {
      logError('⚠️ Lỗi fetch remote config (sử dụng defaults)', error: e);
    }
  }

  // --- Getters ---

  String get aiModelName => _remoteConfig.getString(_keyAiModelName);

  String get aiPromptTemplate => _remoteConfig.getString(_keyAiPromptTemplate);

  String get aiCustomApiKey => _remoteConfig.getString(_keyAiApiKey);

  bool get isMaintenanceMode => _remoteConfig.getBool(_keyMaintenanceMode);

  String get minAppVersion => _remoteConfig.getString(_keyMinVersion);

  /// Force fetch config mới nhất (dùng khi user pull-to-refresh hoặc sự kiện đặc biệt)
  Future<void> forceFetch() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await _remoteConfig.fetchAndActivate();
      logInfo('🔄 Forced Remote Config fetch completed');
    } catch (e) {
      logError('❌ Force fetch failed', error: e);
    }
  }
}
