import 'package:flutter/material.dart';
import 'package:moni/config/app_config.dart';

import '../../widgets/custom_page_header.dart';
import 'modules/budget/budget_screen.dart';
import 'modules/chatbot/chatbot_screen.dart';
import 'modules/reports/reports_screen.dart';
import 'services/ui_optimization_service.dart';

/// Module definition
class AssistantModule {
  final String id;
  final String name;
  final IconData icon;

  const AssistantModule({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// Enhanced Main Assistant Screen with Cross-Module Integration
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _iconAnimationController;
  final UIOptimizationService _uiOptimization = UIOptimizationService();

  // Define modules inline
  static const List<AssistantModule> modules = [
    AssistantModule(id: 'chatbot', name: 'Chat AI', icon: Icons.chat_bubble),
    AssistantModule(
        id: 'budget', name: 'Ngân sách', icon: Icons.account_balance_wallet),
    AssistantModule(id: 'reports', name: 'Báo cáo', icon: Icons.analytics),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: modules.length,
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Sync tab controller
    _tabController.addListener(_onTabChanged);

    // Đồng bộ trạng thái menubar theo tab hiện tại sau frame đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatbotIndex = modules.indexWhere((m) => m.id == 'chatbot');
      final isInChatbotModule = _tabController.index == chatbotIndex;
      // Đồng bộ active module để các widget con biết trạng thái hiện tại
      _uiOptimization.setActiveModule(modules[_tabController.index].id);
      if (isInChatbotModule) {
        _uiOptimization.enterAssistantChatMode();
      } else {
        _uiOptimization.exitAssistantChatMode();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _iconAnimationController.dispose();
    // Đảm bảo hiện lại menubar khi rời AssistantScreen
    // Deferred để tránh setState() khi widget tree locked
    _uiOptimization.exitAssistantChatMode(deferred: true);
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Cập nhật active module và trạng thái menubar theo module hiện tại.
    final chatbotIndex = modules.indexWhere((m) => m.id == 'chatbot');
    final currentModuleId = modules[_tabController.index].id;
    _uiOptimization.setActiveModule(currentModuleId);
    if (_tabController.index != chatbotIndex) {
      _uiOptimization.exitAssistantChatMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header using CustomPageHeader
            CustomPageHeader(
              title: 'Trợ lý Tài chính AI',
              subtitle: 'Quản lý thông minh với AI',
              icon: Icons.psychology,
            ),

            // Enhanced Tab Bar - Flexible Layout with Dynamic Weights
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, child) {
                  return Row(
                    children: modules.asMap().entries.map((entry) {
                      final index = entry.key;
                      final module = entry.value;
                      final animValue = _tabController.animation!.value;

                      // Tính toán flex weight dựa trên animation (3:1:1:1 ratio)
                      int flexWeight;
                      final distanceFromSelected = (animValue - index).abs();

                      if (distanceFromSelected < 0.5) {
                        // Tab đang được chọn hoặc đang animate tới: weight từ 1 → 3
                        final progress =
                            1.0 - (distanceFromSelected * 2); // 0 to 1
                        flexWeight = (1 + (2 * progress)).round(); // 1 to 3
                      } else {
                        // Tab không được chọn: weight = 1
                        flexWeight = 1;
                      }

                      final isSelected = _tabController.index == index;
                      final isAnimatingTo = distanceFromSelected < 0.5;
                      final shouldShowText = isSelected || isAnimatingTo;

                      return Flexible(
                        flex: flexWeight,
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(index),
                            child: AnimatedBuilder(
                              animation: _tabController.animation!,
                              builder: (context, child) {
                                final iconScale = isSelected ? 1.0 : 1.0;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.all(1),
                                  decoration: isSelected
                                      ? BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primary
                                                  .withValues(alpha: 0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        )
                                      : null,
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      transitionBuilder: (child, animation) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.2, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: shouldShowText && isSelected
                                          ? Row(
                                              key: ValueKey('text_$index'),
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Transform.scale(
                                                  scale: iconScale,
                                                  child: Icon(
                                                    module.icon,
                                                    size: 20,
                                                    color: Colors.white,
                                                    key: ValueKey(
                                                        'icon_text_$index'),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    module.name,
                                                    key:
                                                        ValueKey('name_$index'),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Transform.scale(
                                              key: ValueKey('icon_$index'),
                                              scale: iconScale,
                                              child: Icon(
                                                module.icon,
                                                size: isSelected ? 24 : 20,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // Tabbed Interface for seamless navigation
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const ChatbotScreen(), // Chat AI screen
                  const BudgetScreen(),
                  const ReportsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
