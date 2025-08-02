import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/custom_page_header.dart';
import 'modules/analytics/analytics_screen.dart';
import 'modules/budget/budget_screen.dart';
import 'modules/chatbot/chatbot_screen.dart';
import 'modules/reports/reports_screen.dart';
import 'services/assistant_navigation_service.dart';

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
  final AssistantNavigationService _navigationService =
      AssistantNavigationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AssistantNavigationService.modules.length,
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Listen to navigation changes
    _navigationService.addNavigationListener(_onNavigationChanged);

    // Sync tab controller with navigation service
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _navigationService.removeNavigationListener(_onNavigationChanged);
    _tabController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _onNavigationChanged() {
    if (mounted) {
      final newIndex = _navigationService.currentTabIndex;
      if (_tabController.index != newIndex) {
        _tabController.animateTo(newIndex);
      }
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _navigationService.navigateToTab(_tabController.index);
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
                    children: AssistantNavigationService.modules
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final module = entry.value;
                      final animValue = _tabController.animation!.value;
                      
                      // Tính toán flex weight dựa trên animation (3:1:1:1 ratio)
                      int flexWeight;
                      final distanceFromSelected = (animValue - index).abs();
                      
                      if (distanceFromSelected < 0.5) {
                        // Tab đang được chọn hoặc đang animate tới: weight từ 1 → 3
                        final progress = 1.0 - (distanceFromSelected * 2); // 0 to 1
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
                                          borderRadius: BorderRadius.circular(12),
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
                                      duration: const Duration(milliseconds: 200),
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
                                                    key: ValueKey('name_$index'),
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
                  const AnalyticsScreen(),
                  const BudgetScreen(),
                  const ReportsScreen(),
                  const ChatbotScreen(), // New chatbot screen
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
