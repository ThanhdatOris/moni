import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transaction_calendar_screen.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/environment_service.dart';
import 'services/firebase_service.dart';
import 'services/service_locator.dart';
import 'widgets/expense_chart.dart';
import 'widgets/financial_overview.dart';
import 'widgets/home_header.dart';
import 'widgets/menubar.dart';
import 'widgets/recent_transactions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình màu thanh trạng thái
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Khởi tạo locale data cho date formatting
  await initializeDateFormatting('vi_VN', null);
  await initializeDateFormatting('en_US', null);

  // Khởi tạo Environment Service trước
  await EnvironmentService.initialize();

  // Log configuration nếu ở development mode
  if (EnvironmentService.isDevelopment) {
    EnvironmentService.logConfiguration();
  }

  // Khởi tạo Firebase
  await FirebaseService.initialize();

  // Tạo tài khoản test nếu cần
  try {
    await AuthServiceTest.createTestAccount();
    await AuthServiceTest.createBackupTestAccount();
  } catch (e) {
    //print('Lỗi tạo tài khoản test: $e');
  }

  // Setup dependency injection
  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: AppColors.primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // Tạo dữ liệu mẫu khi user đăng nhập
          _createSampleData();
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }

  Future<void> _createSampleData() async {
    try {
      final categoryService = serviceLocator<CategoryService>();

      // Tạo danh mục mặc định
      await categoryService.createDefaultCategories();

      // Đợi một chút để danh mục được tạo xong
      await Future.delayed(const Duration(seconds: 1));

      // Tạo giao dịch mẫu
      await categoryService.createSampleTransactions();
    } catch (e) {
      //print('Lỗi tạo dữ liệu mẫu: $e');
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeTabContent(),
    const TransactionCalendarScreen(),
    const Center(),
    const ChatbotPage(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Điều hướng đến màn hình thêm giao dịch mới
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
      );
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

class HomeTabContent extends StatelessWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section với gradient background
          const ModernHomeHeader(),

          const SizedBox(height: 20),

          // Financial Overview Cards
          const FinancialOverviewCards(),

          const SizedBox(height: 20),

          // Expense Chart
          const ExpenseChart(),

          const SizedBox(height: 20),

          // Recent Transactions
          const RecentTransactions(),

          const SizedBox(height: 100), // Space for bottom menu
        ],
      ),
    );
  }
}
