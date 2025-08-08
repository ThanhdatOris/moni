import 'package:flutter/material.dart';

/// Enhanced navigation service for seamless assistant module switching
class AssistantNavigationService {
  static final AssistantNavigationService _instance =
      AssistantNavigationService._internal();
  factory AssistantNavigationService() => _instance;
  AssistantNavigationService._internal();

  // Navigation state
  int _currentTabIndex = 0;
  String _activeModule = 'budget';
  final Map<String, dynamic> _moduleContext = {};
  final List<VoidCallback> _navigationListeners = [];

  // Getters
  int get currentTabIndex => _currentTabIndex;
  String get activeModule => _activeModule;
  Map<String, dynamic> get moduleContext => Map.unmodifiable(_moduleContext);

  // Available modules
  static const List<AssistantModule> modules = [
    AssistantModule(
      id: 'budget',
      name: 'Ngân sách',
      icon: Icons.account_balance_wallet_outlined,
      route: '/assistant/budget',
      description: 'Tạo và quản lý ngân sách thông minh',
    ),
    AssistantModule(
      id: 'reports',
      name: 'Báo cáo',
      icon: Icons.assessment_outlined,
      route: '/assistant/reports',
      description: 'Tạo báo cáo tài chính chi tiết',
    ),
    AssistantModule(
      id: 'chatbot',
      name: 'AI Chat',
      icon: Icons.smart_toy_outlined,
      route: '/assistant/chatbot',
      description: 'Trò chuyện thông minh với AI trợ lý',
    ),
  ];

  /// Navigate to specific module
  void navigateToModule(String moduleId, {Map<String, dynamic>? context}) {
    final moduleIndex = modules.indexWhere((m) => m.id == moduleId);
    if (moduleIndex != -1) {
      _currentTabIndex = moduleIndex;
      _activeModule = moduleId;

      // Update context
      if (context != null) {
        _moduleContext.addAll(context);
      }

      // Notify listeners
      _notifyListeners();
    }
  }

  /// Navigate to specific tab index
  void navigateToTab(int index) {
    if (index >= 0 && index < modules.length) {
      _currentTabIndex = index;
      _activeModule = modules[index].id;
      _notifyListeners();
    }
  }

  /// Add navigation listener
  void addNavigationListener(VoidCallback listener) {
    _navigationListeners.add(listener);
  }

  /// Remove navigation listener
  void removeNavigationListener(VoidCallback listener) {
    _navigationListeners.remove(listener);
  }

  /// Set context for specific module
  void setModuleContext(String moduleId, Map<String, dynamic> context) {
    _moduleContext[moduleId] = context;
    _notifyListeners();
  }

  /// Get context for specific module
  Map<String, dynamic>? getModuleContext(String moduleId) {
    return _moduleContext[moduleId];
  }

  /// Clear context for specific module
  void clearModuleContext(String moduleId) {
    _moduleContext.remove(moduleId);
    _notifyListeners();
  }

  /// Clear all context
  void clearAllContext() {
    _moduleContext.clear();
    _notifyListeners();
  }

  /// Share data between modules
  void shareDataBetweenModules(
      String fromModule, String toModule, Map<String, dynamic> data) {
    final sharedData = {
      'source': fromModule,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };

    setModuleContext('shared_$toModule', sharedData);
  }

  /// Get shared data for module
  Map<String, dynamic>? getSharedData(String moduleId) {
    return getModuleContext('shared_$moduleId');
  }

  /// Navigate with animation and context
  Future<void> navigateWithAnimation(
    BuildContext context,
    String moduleId, {
    Map<String, dynamic>? moduleContext,
    Duration animationDuration = const Duration(milliseconds: 300),
  }) async {
    // Set context first
    if (moduleContext != null) {
      setModuleContext(moduleId, moduleContext);
    }

    // Perform navigation with animation
    navigateToModule(moduleId);

    // Add subtle haptic feedback
    // HapticFeedback.selectionClick();
  }

  /// Get current module
  AssistantModule get currentModule {
    return modules.firstWhere((m) => m.id == _activeModule,
        orElse: () => modules.first);
  }

  /// Check if module has context
  bool hasModuleContext(String moduleId) {
    return _moduleContext.containsKey(moduleId);
  }

  /// Get navigation history
  List<String> getNavigationHistory() {
    // Simple implementation - could be enhanced with actual history tracking
    return [_activeModule];
  }

  /// Reset navigation state
  void reset() {
    _currentTabIndex = 0;
    _activeModule = modules.first.id;
    _moduleContext.clear();
    _notifyListeners();
  }

  void _notifyListeners() {
    for (final listener in _navigationListeners) {
      listener();
    }
  }

  /// Dispose resources
  void dispose() {
    _navigationListeners.clear();
    _moduleContext.clear();
  }
}

/// Assistant module configuration
class AssistantModule {
  final String id;
  final String name;
  final IconData icon;
  final String route;
  final String description;

  const AssistantModule({
    required this.id,
    required this.name,
    required this.icon,
    required this.route,
    required this.description,
  });
}

/// Enhanced navigation widget for smooth module transitions
class AssistantNavigationBar extends StatefulWidget {
  final Function(int)? onTabChanged;
  final int? currentIndex;

  const AssistantNavigationBar({
    super.key,
    this.onTabChanged,
    this.currentIndex,
  });

  @override
  State<AssistantNavigationBar> createState() => _AssistantNavigationBarState();
}

class _AssistantNavigationBarState extends State<AssistantNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _selectedIndex =
        widget.currentIndex ?? AssistantNavigationService().currentTabIndex;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                AssistantNavigationService.modules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              final isSelected = index == _selectedIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTap(index),
                  onTapDown: (_) => _animationController.forward(),
                  onTapUp: (_) => _animationController.reverse(),
                  onTapCancel: () => _animationController.reverse(),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected ? _scaleAnimation.value : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange.withValues(alpha: 0.3),
                                      Colors.orange.withValues(alpha: 0.1),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.orange.withValues(alpha: 0.5),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                module.icon,
                                color: isSelected
                                    ? Colors.orange
                                    : Colors.white.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                module.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.orange
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _onTabTap(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      // Update navigation service
      AssistantNavigationService().navigateToTab(index);

      // Call callback
      widget.onTabChanged?.call(index);
    }
  }
}
