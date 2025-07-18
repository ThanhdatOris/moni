import 'package:flutter/material.dart';

import '../widgets/anonymous_user_banner.dart';
import '../widgets/category_quick_access.dart';
import '../widgets/expense_chart.dart';
import '../widgets/financial_overview.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_header.dart';
import '../widgets/home_recent_transactions.dart';
import '../widgets/menubar.dart';
import '../widgets/simple_offline_status_banner.dart';
import 'chatbot_screen.dart';
import 'profile/profile_screen.dart';
import 'transaction/add_transaction_screen.dart';
import 'transaction_calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Key _homeTabKey = UniqueKey();

  List<Widget> get _widgetOptions => [
        HomeTabContent(key: _homeTabKey),
        const TransactionCalendarScreen(),
        const Center(),
        const ChatbotPage(),
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
            child: Menubar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  Key _financialOverviewKey = UniqueKey();
  Key _expenseChartKey = UniqueKey();
  Key _recentTransactionsKey = UniqueKey();

  @override
  void didUpdateWidget(HomeTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi widget được rebuild, tạo key mới để refresh các widget con
    _financialOverviewKey = UniqueKey();
    _expenseChartKey = UniqueKey();
    _recentTransactionsKey = UniqueKey();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section với gradient background
          const ModernHomeHeader(),

          // Offline Status Banner (hiển thị trạng thái kết nối)
          const SimpleOfflineStatusBanner(),

          // Anonymous User Banner (chỉ hiển thị cho anonymous user)
          const AnonymousUserBanner(),

          const SizedBox(height: 20),

          // Financial Overview Cards
          FinancialOverviewCards(key: _financialOverviewKey),

          const SizedBox(height: 20),

          // Expense Chart
          ExpenseChart(key: _expenseChartKey),

          const SizedBox(height: 20),

          // Category Quick Access
          const CategoryQuickAccess(),

          const SizedBox(height: 20),

          // Recent Transactions
          HomeRecentTransactions(key: _recentTransactionsKey),

          const SizedBox(height: 20),

          // Home Banner Slider
          const HomeBanner(),

          const SizedBox(height: 120), // Space for bottom menu
        ],
      ),
    );
  }
}
