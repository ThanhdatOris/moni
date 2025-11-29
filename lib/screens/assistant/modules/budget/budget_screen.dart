import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moni/config/app_config.dart';
import 'package:moni/services/ai_services/ai_services.dart';
import 'package:moni/services/data/budget_allocation_service.dart';
import 'package:moni/services/data/budget_service.dart';
import 'package:moni/services/data/category_service.dart';
import 'package:moni/utils/formatting/currency_formatter.dart';
import 'package:moni/utils/helpers/category_icon_helper.dart';

import '../../../../models/category_model.dart';
import '../../../assistant/services/real_data_service.dart' as real_data;
import '../../widgets/assistant_module_tab_bar.dart';
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
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();
  final BudgetAllocationService _allocationService =
      BudgetAllocationService.instance;
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
    // Tab mặc định là "Theo dõi" (index 1) thay vì "Tạo mới" (index 0)
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);

    try {
      // Sync budgets với transactions trước khi load
      await _budgetService.syncBudgetsWithTransactions();

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

  /// Handle budget creation from form - Sử dụng BudgetAllocationService
  Future<void> _handleBudgetGenerated(BudgetInputData budgetData) async {
    setState(() => _isLoading = true);

    try {
      // QUAN TRỌNG: Chỉ lấy parent categories (không có parentId)
      // Budget chỉ được tạo cho parent categories và tự động gộp spending của children
      final allCategoriesStream = _categoryService.getCategories();
      final allCategories = await allCategoriesStream.first;

      // Filter chỉ lấy parent categories
      final categories = allCategories
          .where((c) => c.parentId == null || c.parentId!.isEmpty)
          .toList();

      // Sử dụng BudgetAllocationService để tính toán phân bổ
      final allocationResult = _allocationService.calculateBudgetAllocation(
        income: budgetData.income,
        period: budgetData.period,
        priorityCategories: budgetData.priorityCategories,
        savingsGoal: budgetData.savingsGoal,
        allCategories:
            allCategories, // Truyền allCategories để service có thể validate
      );

      // Tạo budgets cho từng parent category
      int successCount = 0;
      final errors = <String>[];

      for (final category in categories) {
        final budgetAmount =
            allocationResult.categoryBudgets[category.categoryId] ?? 0.0;

        // Chỉ tạo budget nếu amount > 0
        if (budgetAmount <= 0) continue;

        try {
          await _budgetService.createBudget(
            categoryId: category.categoryId,
            categoryName: category.name,
            monthlyLimit: budgetAmount,
          );
          successCount++;
        } catch (e) {
          // Log error nhưng tiếp tục với category khác
          errors.add('${category.name}: $e');
          debugPrint('Error creating budget for ${category.name}: $e');
        }
      }

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tạo $successCount ngân sách thành công!'),
              backgroundColor: AppColors.success,
            ),
          );

          // Reload budget data và sync với transactions
          await _loadBudgetData();

          // Switch to track tab để user thấy ngay kết quả
          _tabController.animateTo(1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tạo ngân sách. Vui lòng thử lại.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo ngân sách: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        .map(
          (realData) => CategoryBudgetProgress(
            name: realData.name,
            color: realData.color,
            budget: realData.budget,
            spent: realData.spent,
            icon: realData.icon,
          ),
        )
        .toList();
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
        AssistantModuleTabBar(
          controller: _tabController,
          indicatorColor: Colors.green.shade600,
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
              isLoading: _isLoading,
              onBudgetGenerated: _handleBudgetGenerated,
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
              onViewDetails: _showBudgetDetails,
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
              recommendation:
                  _aiRecommendationText ??
                  (_budgetData?.recommendations ?? const []).join('\n• '),
              tips: _budgetTips,
              isLoading: _isLoading,
              onRegenerateRecommendation: _generateNewRecommendation,
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã tạo gợi ý mới!')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
      builder: (dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTotal = double.tryParse(totalController.text) ?? 0;
                if (newTotal <= 0 || _budgetData == null) {
                  Navigator.pop(dialogContext);
                  return;
                }

                Navigator.pop(dialogContext);

                // Show loading
                setState(() => _isLoading = true);

                try {
                  final oldTotal = _budgetData!.totalBudget;
                  final ratio = oldTotal > 0 ? newTotal / oldTotal : 1.0;

                  // Tính toán budgets mới cho từng category
                  final updatedBudgets = <String, double>{};
                  for (final category in _budgetData!.categoryProgress) {
                    final newBudget = category.budget * ratio;
                    updatedBudgets[category.categoryId] = newBudget;
                  }

                  // Lưu từng budget vào database
                  int successCount = 0;
                  for (final entry in updatedBudgets.entries) {
                    try {
                      // Tìm category name từ categoryProgress
                      final category = _budgetData!.categoryProgress.firstWhere(
                        (c) => c.categoryId == entry.key,
                        orElse: () => _budgetData!.categoryProgress.first,
                      );

                      // createBudget sẽ tự động update nếu đã có budget cho tháng này
                      await _budgetService.createBudget(
                        categoryId: entry.key,
                        categoryName: category.name,
                        monthlyLimit: entry.value,
                      );
                      successCount++;
                    } catch (e) {
                      debugPrint(
                        'Error updating budget for category ${entry.key}: $e',
                      );
                    }
                  }

                  // Reload budget data từ database
                  await _loadBudgetData();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã điều chỉnh $successCount ngân sách thành công!',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi điều chỉnh ngân sách: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  /// Show budget details dialog
  /// Load categories để hiển thị icon đúng cách
  Future<void> _showBudgetDetails() async {
    if (_budgetData == null || _categoryProgress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có dữ liệu ngân sách')),
      );
      return;
    }

    // Load categories để lấy đầy đủ thông tin icon
    List<CategoryModel> categories = [];
    try {
      categories = await _categoryService.getCategories().first;
    } catch (e) {
      debugPrint('Error loading categories for budget details: $e');
    }

    // Tạo map để lookup category nhanh
    final categoryMap = <String, CategoryModel>{};
    for (final category in categories) {
      categoryMap[category.categoryId] = category;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Chi tiết ngân sách',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng quan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Tổng ngân sách',
                            _budgetData!.totalBudget,
                          ),
                          _buildDetailRow(
                            'Đã chi tiêu',
                            _budgetData!.totalSpent,
                          ),
                          _buildDetailRow(
                            'Còn lại',
                            _budgetData!.totalBudget - _budgetData!.totalSpent,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value:
                                (_budgetData!.totalSpent /
                                        _budgetData!.totalBudget)
                                    .clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _budgetData!.totalSpent > _budgetData!.totalBudget
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category details
                  Text(
                    'Chi tiết theo danh mục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._categoryProgress.map((categoryProgress) {
                    // Tìm category đầy đủ từ categoryMap
                    final category = categoryMap[categoryProgress.categoryId];
                    final categoryColor = Color(
                      int.parse(categoryProgress.color.replaceAll('#', '0xFF')),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: category != null
                                ? CategoryIconHelper.buildIcon(
                                    category,
                                    size: 20,
                                    color: categoryColor,
                                  )
                                : Text(
                                    categoryProgress.icon,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                          ),
                        ),
                        title: Text(
                          categoryProgress.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  (categoryProgress.budget > 0
                                          ? categoryProgress.spent /
                                                categoryProgress.budget
                                          : 0.0)
                                      .clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                categoryProgress.spent > categoryProgress.budget
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${CurrencyFormatter.formatAmountWithCurrency(categoryProgress.spent)} / ${CurrencyFormatter.formatAmountWithCurrency(categoryProgress.budget)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${categoryProgress.percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    categoryProgress.spent >
                                        categoryProgress.budget
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              color: AppColors.primary,
                              onPressed: () => _showEditBudgetDialog(
                                context,
                                categoryProgress,
                                category?.name ?? categoryProgress.name,
                              ),
                              tooltip: 'Chỉnh sửa ngân sách',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            CurrencyFormatter.formatAmountWithCurrency(amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog để chỉnh sửa budget cho category
  /// Cho phép chọn: chỉ update category này hoặc giữ tổng budget không đổi
  Future<void> _showEditBudgetDialog(
    BuildContext bottomSheetContext,
    real_data.CategoryBudgetProgress categoryProgress,
    String categoryName,
  ) async {
    final budgetController = TextEditingController(
      text: categoryProgress.budget.toStringAsFixed(0),
    );
    bool keepTotalBudget = false; // Mặc định: cho phép thay đổi tổng budget

    final result = await showDialog<Map<String, dynamic>>(
      context: bottomSheetContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Chỉnh sửa ngân sách: $categoryName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngân sách hiện tại: ${CurrencyFormatter.formatAmountWithCurrency(categoryProgress.budget)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng ngân sách: ${CurrencyFormatter.formatAmountWithCurrency(_budgetData?.totalBudget ?? 0)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ngân sách mới (VNĐ)',
                    hintText: 'Nhập số tiền',
                    border: OutlineInputBorder(),
                    prefixText: '₫ ',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã chi tiêu: ${CurrencyFormatter.formatAmountWithCurrency(categoryProgress.spent)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                // Option: Giữ tổng budget không đổi
                CheckboxListTile(
                  title: const Text('Giữ tổng ngân sách không đổi'),
                  subtitle: const Text(
                    'Điều chỉnh các danh mục khác theo tỷ lệ',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: keepTotalBudget,
                  onChanged: (value) {
                    setDialogState(() {
                      keepTotalBudget = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final newBudget = double.tryParse(
                  budgetController.text.replaceAll(',', ''),
                );
                if (newBudget == null || newBudget < 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập số tiền hợp lệ'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'budget': newBudget,
                  'keepTotal': keepTotalBudget,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final newBudget = result['budget'] as double;
      final keepTotal = result['keepTotal'] as bool;

      if (newBudget < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ngân sách không được âm'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Show loading
      setState(() => _isLoading = true);

      try {
        if (keepTotal && _budgetData != null) {
          // Mode: Giữ tổng budget không đổi
          // Tính sự thay đổi của category này
          final oldCategoryBudget = categoryProgress.budget;
          final budgetDiff = newBudget - oldCategoryBudget;

          // Tính budget mới cho các category khác (giữ tổng không đổi)
          final otherCategories = _budgetData!.categoryProgress
              .where((c) => c.categoryId != categoryProgress.categoryId)
              .toList();

          if (otherCategories.isNotEmpty) {
            // Phân bổ lại budget diff cho các category khác theo tỷ lệ
            final totalOtherBudgets = otherCategories.fold(
              0.0,
              (sum, c) => sum + c.budget,
            );

            if (totalOtherBudgets > 0) {
              // Update category này trước
              await _budgetService.createBudget(
                categoryId: categoryProgress.categoryId,
                categoryName: categoryName,
                monthlyLimit: newBudget,
              );

              // Update các category khác theo tỷ lệ
              for (final otherCategory in otherCategories) {
                final ratio = otherCategory.budget / totalOtherBudgets;
                final adjustment =
                    -budgetDiff * ratio; // Trừ đi để giữ tổng không đổi
                final newOtherBudget = (otherCategory.budget + adjustment)
                    .clamp(0.0, double.infinity);

                await _budgetService.createBudget(
                  categoryId: otherCategory.categoryId,
                  categoryName: otherCategory.name,
                  monthlyLimit: newOtherBudget,
                );
              }
            } else {
              // Nếu không có category khác, chỉ update category này
              await _budgetService.createBudget(
                categoryId: categoryProgress.categoryId,
                categoryName: categoryName,
                monthlyLimit: newBudget,
              );
            }
          } else {
            // Chỉ có 1 category, chỉ update nó
            await _budgetService.createBudget(
              categoryId: categoryProgress.categoryId,
              categoryName: categoryName,
              monthlyLimit: newBudget,
            );
          }
        } else {
          // Mode: Chỉ update category này, tổng budget thay đổi
          await _budgetService.createBudget(
            categoryId: categoryProgress.categoryId,
            categoryName: categoryName,
            monthlyLimit: newBudget,
          );
        }

        // Reload budget data
        await _loadBudgetData();

        // Đóng dialog chi tiết để user thấy data mới khi mở lại
        if (bottomSheetContext.mounted) {
          Navigator.pop(bottomSheetContext);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                keepTotal
                    ? 'Đã cập nhật ngân sách (giữ tổng không đổi)'
                    : 'Đã cập nhật ngân sách cho $categoryName',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi cập nhật ngân sách: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
