import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'menubar.dart';
import 'screens/analytics_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transaction_input_screen.dart';
import 'widgets/financial_overview.dart'; // Import the new widget
import 'widgets/home_header.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Cập nhật danh sách widget cho 5 tab
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeTabContent(), // Index 0: Trang chủ
    const TransactionListScreen(), // Index 1: Danh sách giao dịch
    const Center(child: Text('Trang Thêm mới')), // Index 2 (Nút giữa, nội dung không hiển thị)
    const ChatbotPage(), // Index 3: Trang Chatbot
    const ProfileScreen(), // Index 4: Trang cá nhân
  ];

  void _onItemTapped(int index) {
    // Xử lý sự kiện nhấn nút ở giữa (index 2) riêng
    if (index == 2) {
      // Ví dụ: hiển thị một dialog, hoặc điều hướng đến màn hình thêm mới
      showModalBottomSheet(context: context, builder: (context) => const Center(child: Text("Chức năng thêm mới")));
      return; // Không thay đổi tab đang chọn
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bỏ AppBar ở đây vì mỗi trang con (như HomeTabContent) sẽ tự quản lý AppBar của riêng nó
      body: Stack(
        children: <Widget>[
          // Nội dung chính sẽ thay đổi theo tab được chọn
          _widgetOptions.elementAt(_selectedIndex),

          // Thanh điều hướng tùy chỉnh luôn ở dưới cùng
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

// Widget để hiển thị biểu đồ tròn
class TransactionPieChart extends StatelessWidget {
  const TransactionPieChart({super.key});

  final Map<String, double> dataMap = const {
    "Ăn uống": 500000,
    "Mua sắm": 300000,
    "Di chuyển": 150000,
    "Giải trí": 200000,
    "Hóa đơn": 250000,
  };

  final List<Color> colorList = const [
    AppColors.food,
    AppColors.shopping,
    AppColors.transport,
    AppColors.entertainment,
    AppColors.bills,
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PieChart(
        dataMap: dataMap,
        animationDuration: const Duration(milliseconds: 800),
        chartLegendSpacing: 48,
        chartRadius: MediaQuery.of(context).size.width / 2.2,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 40,
        centerText: "CHI TIÊU",
        legendOptions: const LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        chartValuesOptions: const ChartValuesOptions(
          showChartValueBackground: true,
          showChartValues: true,
          showChartValuesInPercentage: true,
          showChartValuesOutside: false,
          decimalPlaces: 1,
        ),
      ),
    );
  }
}

class HomeTabContent extends StatelessWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const HomeHeaderSection(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinancialOverviewCards(), // Use the new widget
                const SizedBox(height: 24),
                const _ExpenseChartSection(),
                const SizedBox(height: 24),
                const _QuickActionsSection(),
                const SizedBox(height: 24),
                const _RecentTransactionsSection(),
              ],
            ),
          ),
          const SizedBox(height: 120), // Khoảng cách để tránh overlap với navigation
        ],
      ),
    );
  }
}

class _ExpenseChartSection extends StatelessWidget {
  const _ExpenseChartSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phân tích chi tiêu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Tháng này',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.bar_chart,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const TransactionPieChart(),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thao tác nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Thu nhập',
                Icons.add_circle,
                const Color(0xFF4CAF50),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionInputScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Chi tiêu',
                Icons.remove_circle,
                const Color(0xFFE53E3E),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionInputScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Phân tích',
                Icons.analytics,
                const Color(0xFF3182CE),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giao dịch gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTransactionItem(
          context,
          Icons.restaurant,
          'Sườn bì chả trứng',
          'Ăn uống • Hôm nay 14:30',
          '-30.000đ',
          const Color(0xFFE53E3E),
          const Color(0xFFFF6B35),
        ),
        const SizedBox(height: 12),
        _buildTransactionItem(
          context,
          Icons.local_mall,
          'Lẩu cua đồng',
          'Ăn uống • 02/12',
          '-180.000đ',
          const Color(0xFFE53E3E),
          const Color(0xFFFF6B35),
        ),
        const SizedBox(height: 12),
        _buildTransactionItem(
          context,
          Icons.local_gas_station,
          'Xăng xe máy',
          'Di chuyển • 01/12',
          '-200.000đ',
          const Color(0xFFE53E3E),
          const Color(0xFF3182CE),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String amount,
    Color amountColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Temporary screens for navigation
class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: AppColors.textLight),
          SizedBox(height: 16),
          Text(
            'Danh sách giao dịch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Chức năng đang phát triển'),
        ],
      ),
    );
  }
}

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy, size: 64, color: AppColors.textLight),
          SizedBox(height: 16),
          Text(
            'Trợ lý AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Chức năng đang phát triển'),
        ],
      ),
    );
  }
}
