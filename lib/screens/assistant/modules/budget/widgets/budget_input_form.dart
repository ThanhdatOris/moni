import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../constants/app_colors.dart';
import '../../../widgets/assistant_action_button.dart';
import '../../../widgets/assistant_base_card.dart';

/// Enhanced budget input form with step-by-step wizard
class BudgetInputForm extends StatefulWidget {
  final Function(BudgetInputData) onBudgetGenerated;
  final bool isLoading;

  const BudgetInputForm({
    super.key,
    required this.onBudgetGenerated,
    this.isLoading = false,
  });

  @override
  State<BudgetInputForm> createState() => _BudgetInputFormState();
}

class _BudgetInputFormState extends State<BudgetInputForm> {
  final PageController _pageController = PageController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _savingsGoalController = TextEditingController();
  
  int _currentStep = 0;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  final List<String> _selectedCategories = [];
  double _riskTolerance = 0.5; // 0 = conservative, 1 = aggressive
  
  final List<String> _availableCategories = [
    'Ăn uống', 'Di chuyển', 'Mua sắm', 'Giải trí',
    'Y tế', 'Học tập', 'Tiết kiệm', 'Đầu tư'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _incomeController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AssistantBaseCard(
      title: 'Tạo ngân sách thông minh',
      titleIcon: Icons.auto_awesome,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.success,
          AppColors.success.withValues(alpha: 0.8),
        ],
      ),
      child: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),
          const SizedBox(height: 20),
          
          // Form pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildIncomeStep(),
                _buildCategoriesStep(),
                _buildGoalsStep(),
                _buildSummaryStep(),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index <= _currentStep;
        final isCurrent = index == _currentStep;
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStepTitle(index),
                  style: TextStyle(
                    color: isCurrent 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIncomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thu nhập của bạn',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập thu nhập để AI tạo ngân sách phù hợp',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        
        // Income input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thu nhập hàng tháng',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '10,000,000',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  suffixText: 'VNĐ',
                  suffixStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Period selector
        Text(
          'Chu kỳ ngân sách',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: BudgetPeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = period),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ) : null,
                  ),
                  child: Text(
                    period.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.7),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ưu tiên chi tiêu',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn các danh mục quan trọng với bạn',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        
        // Categories grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _availableCategories.length,
            itemBuilder: (context, index) {
              final category = _availableCategories[index];
              final isSelected = _selectedCategories.contains(category);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(category);
                    } else {
                      _selectedCategories.add(category);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ) : null,
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.7),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mục tiêu tiết kiệm',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thiết lập mục tiêu và phong cách quản lý',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        
        // Savings goal
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mục tiêu tiết kiệm (% thu nhập)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _savingsGoalController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '20',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  suffixText: '%',
                  suffixStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Risk tolerance
        Text(
          'Phong cách quản lý: ${_getRiskToleranceLabel()}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _riskTolerance,
            onChanged: (value) => setState(() => _riskTolerance = value),
            min: 0,
            max: 1,
            divisions: 2,
          ),
        ),
        Text(
          _getRiskToleranceDescription(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xác nhận thông tin',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        
        // Summary items
        _buildSummaryItem('Thu nhập', '${_incomeController.text} VNĐ/${_selectedPeriod.displayName}'),
        _buildSummaryItem('Danh mục ưu tiên', '${_selectedCategories.length} danh mục'),
        _buildSummaryItem('Mục tiêu tiết kiệm', '${_savingsGoalController.text}%'),
        _buildSummaryItem('Phong cách', _getRiskToleranceLabel()),
        
        const Spacer(),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI sẽ tạo ngân sách phù hợp dựa trên thông tin của bạn',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: AssistantActionButton(
              text: 'Quay lại',
              type: ButtonType.outline,
              backgroundColor: Colors.white,
              textColor: Colors.white,
              onPressed: _previousStep,
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: AssistantActionButton(
            text: _currentStep == 3 ? 'Tạo ngân sách' : 'Tiếp theo',
            type: ButtonType.secondary,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            textColor: Colors.white,
            isLoading: widget.isLoading,
            onPressed: _currentStep == 3 ? _generateBudget : _nextStep,
          ),
        ),
      ],
    );
  }

  void _nextStep() {
    if (_canProceedToNextStep()) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _generateBudget() {
    final data = BudgetInputData(
      income: double.tryParse(_incomeController.text.replaceAll(',', '')) ?? 0,
      period: _selectedPeriod,
      priorityCategories: _selectedCategories,
      savingsGoal: double.tryParse(_savingsGoalController.text) ?? 20,
      riskTolerance: _riskTolerance,
    );
    
    widget.onBudgetGenerated(data);
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _incomeController.text.isNotEmpty;
      case 1:
        return _selectedCategories.isNotEmpty;
      case 2:
        return _savingsGoalController.text.isNotEmpty;
      default:
        return true;
    }
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0: return 'Thu nhập';
      case 1: return 'Ưu tiên';
      case 2: return 'Mục tiêu';
      case 3: return 'Xác nhận';
      default: return '';
    }
  }

  String _getRiskToleranceLabel() {
    if (_riskTolerance < 0.33) return 'Thận trọng';
    if (_riskTolerance < 0.67) return 'Cân bằng';
    return 'Tích cực';
  }

  String _getRiskToleranceDescription() {
    if (_riskTolerance < 0.33) return 'Ưu tiên an toàn, tiết kiệm nhiều hơn';
    if (_riskTolerance < 0.67) return 'Cân bằng giữa chi tiêu và tiết kiệm';
    return 'Chấp nhận rủi ro để đầu tư và phát triển';
  }
}

/// Budget input data model
class BudgetInputData {
  final double income;
  final BudgetPeriod period;
  final List<String> priorityCategories;
  final double savingsGoal;
  final double riskTolerance;

  BudgetInputData({
    required this.income,
    required this.period,
    required this.priorityCategories,
    required this.savingsGoal,
    required this.riskTolerance,
  });
}

/// Budget period enumeration
enum BudgetPeriod {
  weekly('Tuần'),
  monthly('Tháng'),
  yearly('Năm');

  const BudgetPeriod(this.displayName);
  final String displayName;
}
