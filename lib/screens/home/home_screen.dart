import 'package:flutter/material.dart';

import '../../models/transaction_filter_model.dart';
import '../../widgets/menubar.dart';
import '../assistant/assistant_screen.dart';
import '../assistant/services/ui_optimization_service.dart';
import '../assistant/widgets/global_insight_panel.dart';
import '../history/transaction_history_screen.dart';
import '../profile/profile_screen.dart';
import '../transaction/add_transaction_screen.dart';
import 'widgets/anonymous_user_banner.dart';
import 'widgets/category_quick_access.dart';
import 'widgets/home_banner.dart';
import 'widgets/home_chart_section.dart';
import 'widgets/home_header.dart';
import 'widgets/home_recent_transactions.dart';
import 'widgets/simple_offline_status_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Key _homeTabKey = UniqueKey();
  Key _historyTabKey = UniqueKey();
  final UIOptimizationService _uiOptimization = UIOptimizationService();
  
  // Filter để pass vào History tab
  TransactionFilter? _historyFilter;
  int _historyInitialTabIndex = 1; // Default: List view

  void _navigateToHistoryTab() {
    setState(() {
      _historyFilter = null; // Clear filter khi navigate thủ công
      _historyInitialTabIndex = 0; // Default: Calendar view
      _selectedIndex = 3; // Tab History (đã chuyển từ index 1 sang 3)
    });
  }

  /// Navigate to History tab with filter
  void _navigateToHistoryWithFilter(TransactionFilter filter) {
    debugPrint('🔥 NAVIGATE WITH FILTER: $filter');
    debugPrint('🔥 Category IDs: ${filter.categoryIds}');
    debugPrint('🔥 Type: ${filter.type}');
    
    setState(() {
      _historyFilter = filter;
      _historyInitialTabIndex = 1; // Luôn mở List view khi có filter
      _historyTabKey = UniqueKey(); // Force rebuild History tab
      _selectedIndex = 3; // Switch to History tab
      
      debugPrint('🔥 Switched to History tab (index: $_selectedIndex)');
    });
  }

  List<Widget> get _widgetOptions => [
        HomeTabContent(
          key: _homeTabKey,
          onNavigateToHistory: _navigateToHistoryTab,
          onNavigateToHistoryWithFilter: _navigateToHistoryWithFilter,
        ),
        const AssistantScreen(),
        const Center(),
        TransactionHistoryScreen(
          key: _historyTabKey,
          initialFilter: _historyFilter,
          initialTabIndex: _historyInitialTabIndex,
        ),
        const ProfileScreen(),
      ];

  void _onItemTapped(int index) async {
    if (index == 2) {
      // Điều hướng đến màn hình thêm giao dịch mới
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
      );

      // Nếu có giao dịch được thêm, refresh màn hình
      if (result != null) {
        setState(() {
          // Tạo key mới để force rebuild HomeTabContent
          _homeTabKey = UniqueKey();
        });
      }
      return;
    }
    
    // Clear filter nếu user tự tap vào History tab
    if (index == 3 && _selectedIndex != 3) {
      _historyFilter = null;
      _historyInitialTabIndex = 0; // Default: Calendar view
      _historyTabKey = UniqueKey(); // Force rebuild
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _widgetOptions.elementAt(_selectedIndex),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _uiOptimization,
              builder: (context, child) {
                return AnimatedSlide(
                  offset: _uiOptimization.shouldHideMenubar
                      ? const Offset(0, 1.2) // Slide down để ẩn
                      : Offset.zero, // Vị trí bình thường
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: _uiOptimization.shouldHideMenubar ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Menubar(
                      selectedIndex: _selectedIndex,
                      onItemTapped: _onItemTapped,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTabContent extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;
  final Function(TransactionFilter)? onNavigateToHistoryWithFilter;

  const HomeTabContent({
    super.key,
    this.onNavigateToHistory,
    this.onNavigateToHistoryWithFilter,
  });

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  Key _recentTransactionsKey = UniqueKey();

  @override
  void didUpdateWidget(HomeTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi widget được rebuild, tạo key mới để refresh các widget con
    _recentTransactionsKey = UniqueKey();
  }

  /// Handle category tap from chart - Show percentage only, NO navigate
  void _onChartCategoryTap(String categoryId) {
    debugPrint('📊 Chart category tapped (show % only): $categoryId');
    // Không làm gì - chart tự hiển thị % trong state
  }
  
  /// Handle category tap from list - Navigate to history with filter
  void _onCategoryListTap(String categoryId) {
    debugPrint('📝 Category list tapped (navigate): $categoryId');
    if (widget.onNavigateToHistoryWithFilter != null) {
      // Use tab system (Option B)
      widget.onNavigateToHistoryWithFilter!(
        TransactionFilter.byCategory(categoryId),
      );
    } else {
      // Fallback: push new screen (Option A)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionHistoryScreen(
            categoryId: categoryId,
            initialTabIndex: 1, // Mở tab List
          ),
        ),
      );
    }
  }

  /// Handle refresh
  void _onRefresh() {
    // Refresh các widget khác nếu cần
    setState(() {
      _recentTransactionsKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Combined Header and Financial Cards
          const HomeHeaderWithCards(),

          // Offline Status Banner (hiển thị trạng thái kết nối)
          const SimpleOfflineStatusBanner(),

          // Anonymous User Banner (chỉ hiển thị cho anonymous user)
          const AnonymousUserBanner(),

          // Expense Chart Section
          ExpenseChartSection(
            onChartCategoryTap: _onChartCategoryTap, // Chart: show % only
            onCategoryListTap: _onCategoryListTap,   // List: navigate
            onRefresh: _onRefresh,
            onNavigateToHistory: widget.onNavigateToHistory,
            onNavigateToHistoryWithFilter: widget.onNavigateToHistoryWithFilter,
          ),

          const SizedBox(height: 20),

          // Global AI Insight cho trang chủ (phục vụ phân tích tổng quan)
          const GlobalInsightPanel(
            moduleId: 'home',
            title: 'AI Insights tổng quan',
          ),

          // Category Quick Access
          CategoryQuickAccess(
            onNavigateToHistoryWithFilter: widget.onNavigateToHistoryWithFilter,
          ),

          const SizedBox(height: 20),

          // Recent Transactions
          HomeRecentTransactions(
            key: _recentTransactionsKey,
            onNavigateToHistory: widget.onNavigateToHistory,
          ),

          const SizedBox(height: 20),

          // Home Banner Slider
          const HomeBanner(),

          const SizedBox(height: 120), // Space for bottom menu
        ],
      ),
    );
  }
}
