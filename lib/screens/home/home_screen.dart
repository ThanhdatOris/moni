import 'package:flutter/material.dart';

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
  final UIOptimizationService _uiOptimization = UIOptimizationService();

  void _navigateToHistoryTab() {
    setState(() {
      _selectedIndex = 3; // Tab History (đã chuyển từ index 1 sang 3)
    });
  }

  List<Widget> get _widgetOptions => [
        HomeTabContent(
          key: _homeTabKey,
          onNavigateToHistory: _navigateToHistoryTab,
        ),
        const AssistantScreen(),
        const Center(),
        const TransactionHistoryScreen(),
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

  const HomeTabContent({
    super.key,
    this.onNavigateToHistory,
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

  /// Handle category tap
  void _onCategoryTap() {
    // Có thể thêm navigation hoặc action khác ở đây
    debugPrint('Category tapped from home screen');
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
            onCategoryTap: _onCategoryTap,
            onRefresh: _onRefresh,
          ),

          const SizedBox(height: 20),

          // Global AI Insight cho trang chủ (phục vụ phân tích tổng quan)
          const GlobalInsightPanel(
            moduleId: 'home',
            title: 'AI Insights tổng quan',
          ),

          // Category Quick Access
          const CategoryQuickAccess(),

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
