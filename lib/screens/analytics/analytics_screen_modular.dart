/// Analytics Screen Modular - Phiên bản đã tách components
/// Được tái cấu trúc từ AnalyticsScreen để cải thiện maintainability

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/custom_page_header.dart';
import 'widgets/analytics_widgets.dart';

class AnalyticsScreenModular extends StatefulWidget {
  const AnalyticsScreenModular({super.key});

  @override
  State<AnalyticsScreenModular> createState() => _AnalyticsScreenModularState();
}

class _AnalyticsScreenModularState extends State<AnalyticsScreenModular>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Tháng này';

  final List<String> _periods = AnalyticsPeriods.defaultPeriods;

  final List<AnalyticsTab> _tabs = [
    AnalyticsTab('Tổng quan', Icons.dashboard),
    AnalyticsTab('Biểu đồ', Icons.bar_chart),
    AnalyticsTab('Báo cáo', Icons.description),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPeriodChanged(String newPeriod) {
    setState(() {
      _selectedPeriod = newPeriod;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomPageHeader(
            title: 'Phân tích',
            subtitle: 'Theo dõi và phân tích tài chính',
            icon: Icons.analytics,
          ),
          PeriodSelectorWidget(
            selectedPeriod: _selectedPeriod,
            periods: _periods,
            onPeriodChanged: _onPeriodChanged,
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AnalyticsOverviewTab(selectedPeriod: _selectedPeriod),
                AnalyticsChartsTab(selectedPeriod: _selectedPeriod),
                AnalyticsReportsTab(selectedPeriod: _selectedPeriod),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: AppColors.textWhite,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: _tabs.map((tab) {
          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.icon, size: 18),
                const SizedBox(width: 8),
                Text(tab.title),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AnalyticsTab {
  final String title;
  final IconData icon;

  AnalyticsTab(this.title, this.icon);
}

/// Demo version for testing the modular structure
class AnalyticsScreenDemo extends StatelessWidget {
  const AnalyticsScreenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: const AnalyticsScreenModular(),
    );
  }
}

/// Widget for comparing old vs new analytics screen
class AnalyticsComparison extends StatefulWidget {
  const AnalyticsComparison({super.key});

  @override
  State<AnalyticsComparison> createState() => _AnalyticsComparisonState();
}

class _AnalyticsComparisonState extends State<AnalyticsComparison> {
  bool _showModular = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showModular ? 'Analytics (Modular)' : 'Analytics (Original)'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          Switch(
            value: _showModular,
            onChanged: (value) {
              setState(() {
                _showModular = value;
              });
            },
            activeColor: AppColors.textWhite,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _showModular
          ? const AnalyticsScreenModular()
          : const Center(
              child: Text(
                'Original AnalyticsScreen\n(914 lines)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.backgroundLight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showModular
                  ? '✅ Modular: 12 files, ~350 lines each'
                  : '❌ Monolithic: 1 file, 914 lines',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _showModular ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showModular
                  ? 'Better maintainability, testability, and development experience'
                  : 'Difficult to maintain, test, and navigate',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 