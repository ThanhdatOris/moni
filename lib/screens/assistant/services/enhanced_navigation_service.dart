import 'package:flutter/material.dart';

/// Enhanced Navigation Service with better state management
class EnhancedNavigationService extends ChangeNotifier {
  static final EnhancedNavigationService _instance =
      EnhancedNavigationService._internal();
  factory EnhancedNavigationService() => _instance;
  EnhancedNavigationService._internal();

  int _currentTabIndex = 0;
  String _activeModule = 'analytics';
  final Map<String, dynamic> _globalContext = {};
  final List<String> _navigationHistory = [];

  // Getters
  int get currentTabIndex => _currentTabIndex;
  String get activeModule => _activeModule;
  Map<String, dynamic> get globalContext => Map.unmodifiable(_globalContext);
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  // Module definitions with consistent theming
  static const List<AssistantModule> modules = [
    AssistantModule(
      id: 'analytics',
      name: 'Phân tích',
      icon: Icons.analytics_outlined,
      color: Color(0xFF2196F3), // Consistent blue
      description: 'Phân tích chi tiêu và xu hướng tài chính',
    ),
    AssistantModule(
      id: 'budget',
      name: 'Ngân sách',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF4CAF50), // Consistent green
      description: 'Tạo và quản lý ngân sách thông minh',
    ),
    AssistantModule(
      id: 'reports',
      name: 'Báo cáo',
      icon: Icons.assessment_outlined,
      color: Color(0xFFFF9800), // Consistent orange
      description: 'Tạo báo cáo tài chính chi tiết',
    ),
    AssistantModule(
      id: 'chatbot',
      name: 'AI Chat',
      icon: Icons.smart_toy_outlined,
      color: Color(0xFF009688), // Consistent teal
      description: 'Trò chuyện thông minh với AI trợ lý',
    ),
  ];

  /// Navigate to specific module with context
  Future<void> navigateToModule(String moduleId,
      {Map<String, dynamic>? context}) async {
    final moduleIndex = modules.indexWhere((m) => m.id == moduleId);
    if (moduleIndex == -1) return;

    _addToHistory(_activeModule);
    _currentTabIndex = moduleIndex;
    _activeModule = moduleId;

    if (context != null) {
      _globalContext.addAll(context);
    }

    notifyListeners();
  }

  /// Navigate to tab index
  void navigateToTab(int index) {
    if (index >= 0 && index < modules.length && index != _currentTabIndex) {
      _addToHistory(_activeModule);
      _currentTabIndex = index;
      _activeModule = modules[index].id;
      notifyListeners();
    }
  }

  /// Add context that can be shared between modules
  void setSharedContext(String key, dynamic value) {
    _globalContext[key] = value;
    notifyListeners();
  }

  /// Get shared context
  T? getSharedContext<T>(String key) {
    return _globalContext[key] as T?;
  }

  /// Clear specific context
  void clearContext(String key) {
    _globalContext.remove(key);
    notifyListeners();
  }

  /// Get current module info
  AssistantModule get currentModule {
    return modules.firstWhere(
      (m) => m.id == _activeModule,
      orElse: () => modules.first,
    );
  }

  /// Check if can navigate back
  bool get canGoBack => _navigationHistory.isNotEmpty;

  /// Navigate back to previous module
  void goBack() {
    if (_navigationHistory.isNotEmpty) {
      final previousModule = _navigationHistory.removeLast();
      final moduleIndex = modules.indexWhere((m) => m.id == previousModule);
      if (moduleIndex != -1) {
        _currentTabIndex = moduleIndex;
        _activeModule = previousModule;
        notifyListeners();
      }
    }
  }

  /// Reset to default state
  void reset() {
    _currentTabIndex = 0;
    _activeModule = 'analytics';
    _globalContext.clear();
    _navigationHistory.clear();
    notifyListeners();
  }

  void _addToHistory(String moduleId) {
    if (_navigationHistory.length >= 10) {
      _navigationHistory.removeAt(0);
    }
    if (_navigationHistory.isEmpty || _navigationHistory.last != moduleId) {
      _navigationHistory.add(moduleId);
    }
  }

  @override
  void dispose() {
    _globalContext.clear();
    _navigationHistory.clear();
    super.dispose();
  }
}

/// Enhanced module configuration
class AssistantModule {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const AssistantModule({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}
