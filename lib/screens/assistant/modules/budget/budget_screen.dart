import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../constants/app_colors.dart';
import '../../../assistant/models/agent_request_model.dart';
import '../../../assistant/services/global_agent_service.dart';
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

class _BudgetScreenState extends State<BudgetScreen> with TickerProviderStateMixin {
  final GlobalAgentService _agentService = GetIt.instance<GlobalAgentService>();
  late TabController _tabController;
  bool _isLoading = false;
  
  final List<BudgetTip> _budgetTips = [
    BudgetTip(
      title: 'Áp dụng quy tắc 50/30/20',
      description: '50% cho chi phí thiết yếu, 30% cho giải trí, 20% để tiết kiệm',
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

  final List<CategoryBudgetProgress> _categoryProgress = [
    CategoryBudgetProgress(
      name: 'Ăn uống',
      color: '#FF7043',
      budget: 8000000,
      spent: 6500000,
      icon: 'restaurant',
    ),
    CategoryBudgetProgress(
      name: 'Di chuyển',
      color: '#42A5F5',
      budget: 3000000,
      spent: 2800000,
      icon: 'directions_car',
    ),
    CategoryBudgetProgress(
      name: 'Mua sắm',
      color: '#66BB6A',
      budget: 5000000,
      spent: 3200000,
      icon: 'shopping_bag',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(11), // Giảm từ 12 xuống 11
              color: Colors.green.shade600, // Solid xanh lá cây thay vì gradient primary
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade600.withValues(alpha: 0.3), // Đổi màu shadow
                  blurRadius: 4, // Giảm từ 6 xuống 4
                  offset: const Offset(0, 1), // Giảm từ 2 xuống 1
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), // Giảm từ 12 xuống 10
            unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: const [
              Tab(
                height: 32,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 14),
                    SizedBox(width: 4),
                    Text('Tạo ngân sách'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 14),
                    SizedBox(width: 4),
                    Text('Theo dõi'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, size: 14),
                    SizedBox(width: 4),
                    Text('Gợi ý AI'),
                  ],
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: BudgetInputForm(
              onBudgetGenerated: (budgetData) {
                // Handle budget generation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ngân sách đã được tạo!')),
                );
                _tabController.animateTo(1); // Switch to tracking tab
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: BudgetBreakdownChart(
              allocations: [
                BudgetAllocation(
                  category: 'Ăn uống',
                  amount: 8000000,
                  color: '#FF7043',
                  percentage: 32.0,
                  icon: 'restaurant',
                  description: 'Chi phí ăn uống hàng ngày',
                ),
                BudgetAllocation(
                  category: 'Di chuyển',
                  amount: 3000000,
                  color: '#42A5F5',
                  percentage: 12.0,
                  icon: 'directions_car',
                  description: 'Phí di chuyển và xăng xe',
                ),
                BudgetAllocation(
                  category: 'Mua sắm',
                  amount: 5000000,
                  color: '#66BB6A',
                  percentage: 20.0,
                  icon: 'shopping_bag',
                  description: 'Mua sắm và nhu yếu phẩm',
                ),
                BudgetAllocation(
                  category: 'Tiết kiệm',
                  amount: 7000000,
                  color: '#FFA726',
                  percentage: 28.0,
                  icon: 'savings',
                  description: 'Tiết kiệm cho tương lai',
                ),
                BudgetAllocation(
                  category: 'Giải trí',
                  amount: 2000000,
                  color: '#AB47BC',
                  percentage: 8.0,
                  icon: 'movie',
                  description: 'Giải trí và thư giãn',
                ),
              ],
              totalBudget: 25000000,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackBudgetTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: BudgetProgressIndicator(
        budgetPeriod: 'Tháng 12/2024',
        totalBudget: 25000000,
        totalSpent: 18500000,
        categoryProgress: _categoryProgress,
        isLoading: _isLoading,
        onViewDetails: () {
          // Navigate to detailed budget tracking
        },
        onAdjustBudget: () {
          _tabController.animateTo(0); // Go back to create budget
        },
      ),
    );
  }

  Widget _buildRecommendationTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: BudgetRecommendationCard(
        recommendation: 'Dựa trên mẫu chi tiêu hiện tại của bạn, chúng tôi khuyên bạn nên:'
                      '\n\n• Giảm 15% chi phí ăn uống bằng cách nấu ăn tại nhà nhiều hơn'
                      '\n• Tăng quỹ tiết kiệm lên 25% thu nhập để đạt mục tiêu dài hạn'
                      '\n• Thiết lập ngân sách 2 triệu cho giải trí và tuân thủ nghiêm ngặt'
                      '\n• Xem xét đầu tư một phần tiền tiết kiệm để tăng thu nhập thụ động',
        tips: _budgetTips,
        isLoading: _isLoading,
        onRegenerateRecommendation: _generateNewRecommendation,
        onApplyBudget: () {
          _tabController.animateTo(0); // Go to create budget with AI suggestions
        },
      ),
    );
  }

  Future<void> _generateNewRecommendation() async {
    setState(() => _isLoading = true);
    
    try {
      final request = AgentRequest.budget(
        message: 'Tạo gợi ý ngân sách chi tiết mới. Bao gồm: phân bổ theo danh mục, '
                'mục tiêu tiết kiệm, và lời khuyên thực tế cho việc quản lý tài chính.',
        parameters: {
          'analysis_type': 'budget_recommendation',
          'include_tips': true,
        },
      );
      
      final response = await _agentService.processRequest(request);
      
      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tạo gợi ý mới!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.error ?? "Không thể tạo gợi ý"}')),
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
}
