import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moni/constants/app_colors.dart';
import 'package:moni/constants/enums.dart';
import 'package:moni/services/ai_services/ai_services.dart';

import '../../../assistant/services/real_data_service.dart' as real_data;
import 'widgets/budget_breakdown_chart.dart';
import 'widgets/budget_input_form.dart';
import 'widgets/budget_progress_indicator.dart';
import 'widgets/budget_recommendation_card.dart';

/// Simple budget category model
class BudgetCategory {
  final String name;
  final double amount;
  final String color;
  final String icon;

  BudgetCategory({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });
}

/// Budget AI Module Screen - Intelligent budget suggestions
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with TickerProviderStateMixin {
  final AIProcessorService _aiService = GetIt.instance<AIProcessorService>();
  final real_data.RealDataService _realDataService =
      GetIt.instance<real_data.RealDataService>();
  late TabController _tabController;
  bool _isLoading = false;

  // Real budget data
  real_data.BudgetData? _budgetData;
  List<BudgetTip> _budgetTips = [];
  List<real_data.CategoryBudgetProgress> _categoryProgress = [];
  String? _aiRecommendationText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);

    try {
      // Service already initialized via DI
      _budgetData = await _realDataService.getBudgetData();

      setState(() {
        _categoryProgress = _budgetData?.categoryProgress ?? [];
        _budgetTips = _generateBudgetTips();
      });
    } catch (e) {
      // Keep empty state on error
      setState(() {
        _categoryProgress = [];
        _budgetTips = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<BudgetTip> _generateBudgetTips() {
    return [
      BudgetTip(
        title: 'Áp dụng quy tắc 50/30/20',
        description:
            '50% cho chi phí thiết yếu, 30% cho giải trí, 20% để tiết kiệm',
        category: BudgetTipCategory.general,
        priority: 5,
      ),
      BudgetTip(
        title: 'Giảm chi tiêu ăn ngoài',
        description: 'Nấu ăn tại nhà có thể tiết kiệm đến 60% chi phí ăn uống',
        category: BudgetTipCategory.spending,
        priority: 4,
      ),
      BudgetTip(
        title: 'Thiết lập quỹ khẩn cấp',
        description: 'Dành ít nhất 3-6 tháng chi tiêu cho quỹ khẩn cấp',
        category: BudgetTipCategory.saving,
        priority: 5,
      ),
    ];
  }

  /// Convert real data CategoryBudgetProgress to widget CategoryBudgetProgress
  List<CategoryBudgetProgress> _convertCategoryProgress() {
    return _categoryProgress
        .map((realData) => CategoryBudgetProgress(
              name: realData.name,
              color: realData.color,
              budget: realData.budget,
              spent: realData.spent,
              icon: realData.icon,
            ))
        .toList();
  }

  List<BudgetAllocation> _mapAllocationsFromReal() {
    if (_budgetData == null || _budgetData!.categoryProgress.isEmpty) return [];
    final list = _budgetData!.categoryProgress
        .map((c) => BudgetAllocation(
              category: c.name,
              amount: c.budget,
              percentage:
                  c.budget > 0 ? (c.spent / (c.budget)).clamp(0, 1) * 100 : 0,
              icon: c.icon,
              color: c.color,
              description:
                  'Đã chi: ${c.spent.toStringAsFixed(0)} / Ngân sách: ${c.budget.toStringAsFixed(0)}',
            ))
        .toList();
    return list;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar only (no redundant header)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(11), // Giảm từ 12 xuống 11
              color: Colors
                  .green.shade600, // Solid xanh lá cây thay vì gradient primary
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade600
                      .withValues(alpha: 0.3), // Đổi màu shadow
                  blurRadius: 4, // Giảm từ 6 xuống 4
                  offset: const Offset(0, 1), // Giảm từ 2 xuống 1
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600), // Giảm từ 12 xuống 10
            unselectedLabelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: const [
              Tab(
                height: 32,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 14),
                      SizedBox(width: 4),
                      Text('Tạo mới'),
                    ],
                  ),
                ),
              ),
              Tab(
                height: 40,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14),
                      SizedBox(width: 4),
                      Text('Theo dõi'),
                    ],
                  ),
                ),
              ),
              Tab(
                height: 40,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 14),
                      SizedBox(width: 4),
                      Text('Gợi ý AI'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCreateBudgetTab(),
              _buildTrackBudgetTab(),
              _buildRecommendationTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateBudgetTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            BudgetInputForm(
              onBudgetGenerated: (budgetData) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ngân sách đã được tạo!')),
                );
                _tabController.animateTo(1);
              },
            ),
            const SizedBox(height: 16),
            BudgetBreakdownChart(
              allocations: _mapAllocationsFromReal(),
              totalBudget: _budgetData?.totalBudget ?? 0,
              isLoading: _isLoading,
            ),
            // Bottom spacing for menubar
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackBudgetTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            BudgetProgressIndicator(
              budgetPeriod: _budgetData?.budgetPeriod ?? 'Tháng này',
              totalBudget: _budgetData?.totalBudget ?? 0,
              totalSpent: _budgetData?.totalSpent ?? 0,
              categoryProgress: _convertCategoryProgress(),
              isLoading: _isLoading,
              onViewDetails: () {
                // Navigate to detailed budget tracking
              },
              onAdjustBudget: _showAdjustBudgetDialog,
            ),
            // Bottom spacing for menubar
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            BudgetRecommendationCard(
              recommendation: _aiRecommendationText ??
                  (_budgetData?.recommendations ?? const []).join('\n• '),
              tips: _budgetTips,
              isLoading: _isLoading,
              onRegenerateRecommendation: _generateNewRecommendation,
              onApplyBudget: _applyRecommendation,
            ),
            // Bottom spacing for menubar
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Future<void> _generateNewRecommendation() async {
    setState(() => _isLoading = true);

    try {
      // Direct AI call without wrapper layers
      final prompt =
          'Tạo gợi ý ngân sách chi tiết mới. Bao gồm: phân bổ theo danh mục, '
          'mục tiêu tiết kiệm, và lời khuyên thực tế cho việc quản lý tài chính.';

      final response = await _aiService.generateText(prompt);

      if (mounted) {
        if (response.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tạo gợi ý mới!')),
          );
          setState(() {
            _aiRecommendationText = response;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: Không thể tạo gợi ý')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAdjustBudgetDialog() {
    final totalController = TextEditingController(
      text: (_budgetData?.totalBudget ?? 0).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Điều chỉnh tổng ngân sách'),
          content: TextField(
            controller: totalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tổng ngân sách mới (VNĐ)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final newTotal = double.tryParse(totalController.text) ?? 0;
                if (newTotal <= 0 || _budgetData == null) {
                  Navigator.pop(context);
                  return;
                }
                final oldTotal = _budgetData!.totalBudget;
                final ratio = oldTotal > 0 ? newTotal / oldTotal : 1.0;
                final updated = _budgetData!.categoryProgress.map((c) {
                  return real_data.CategoryBudgetProgress(
                    categoryId: c.categoryId,
                    name: c.name,
                    color: c.color,
                    budget: (c.budget * ratio),
                    spent: c.spent,
                    icon: c.icon,
                    percentage: (c.budget * ratio) > 0
                        ? (c.spent / (c.budget * ratio)) * 100
                        : 0,
                  );
                }).toList();

                setState(() {
                  _budgetData = real_data.BudgetData(
                    totalBudget: newTotal,
                    totalSpent: _budgetData!.totalSpent,
                    categoryProgress: updated,
                    budgetPeriod: _budgetData!.budgetPeriod,
                    recommendations: _budgetData!.recommendations,
                  );
                  _categoryProgress = updated;
                });

                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _applyRecommendation() {
    if (_budgetData == null) return;
    final text = _aiRecommendationText ?? '';
    if (text.isEmpty) return;

    // Tăng ngân sách 10% cho các danh mục được nhắc đến trong gợi ý
    final updated = _budgetData!.categoryProgress.map((c) {
      final mentioned = text.toLowerCase().contains(c.name.toLowerCase());
      final newBudget = mentioned ? c.budget * 1.1 : c.budget;
      return real_data.CategoryBudgetProgress(
        categoryId: c.categoryId,
        name: c.name,
        color: c.color,
        budget: newBudget,
        spent: c.spent,
        icon: c.icon,
        percentage: newBudget > 0 ? (c.spent / newBudget) * 100 : 0,
      );
    }).toList();

    final newTotal = updated.fold(0.0, (total, c) => total + c.budget);

    setState(() {
      _budgetData = real_data.BudgetData(
        totalBudget: newTotal,
        totalSpent: _budgetData!.totalSpent,
        categoryProgress: updated,
        budgetPeriod: _budgetData!.budgetPeriod,
        recommendations: _budgetData!.recommendations,
      );
      _categoryProgress = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Đã áp dụng điều chỉnh ngân sách theo gợi ý AI')),
    );
  }
}
