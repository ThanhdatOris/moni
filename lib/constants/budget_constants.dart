/// Constants cho Budget module - Đảm bảo tính nhất quán với Category và Transaction
class BudgetConstants {
  BudgetConstants._();

  // ============================================================================
  // FIRESTORE FIELD NAMES (snake_case - nhất quán với Transaction và Category)
  // ============================================================================
  static const String userId = 'user_id';
  static const String categoryId = 'category_id';
  static const String categoryName = 'category_name';
  static const String monthlyLimit = 'monthly_limit';
  static const String currentSpending = 'current_spending';
  static const String startDate = 'start_date';
  static const String endDate = 'end_date';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // ============================================================================
  // BUSINESS LOGIC CONSTANTS
  // ============================================================================
  
  /// Tỷ lệ cảnh báo khi gần hết ngân sách (80%)
  static const double warningThreshold = 0.8;
  
  /// Tỷ lệ phân bổ budget cho priority categories (60%)
  static const double priorityBudgetRatio = 0.6;
  
  /// Tỷ lệ phân bổ budget cho các category khác (40%)
  static const double otherBudgetRatio = 0.4;
  
  /// Hệ số chuyển đổi weekly income sang monthly (4.33 tuần/tháng)
  static const double weeklyToMonthlyFactor = 4.33;
  
  /// Hệ số chuyển đổi yearly income sang monthly (12 tháng/năm)
  static const double yearlyToMonthlyFactor = 12.0;
  
  /// Hệ số estimate budget từ spending (1.2 = thêm 20% buffer)
  static const double budgetEstimateFactor = 1.2;
  
  /// Mục tiêu tiết kiệm mặc định (%)
  static const double defaultSavingsGoal = 20.0;

  // ============================================================================
  // VALIDATION CONSTANTS
  // ============================================================================
  
  /// Giới hạn tối thiểu cho monthly limit
  static const double minMonthlyLimit = 0.0;
  
  /// Giới hạn tối đa cho monthly limit (để tránh overflow)
  static const double maxMonthlyLimit = 999999999999.0;
}

/// Budget allocation configuration
class BudgetAllocationConfig {
  final double priorityRatio;
  final double otherRatio;
  final double savingsGoal;

  const BudgetAllocationConfig({
    this.priorityRatio = BudgetConstants.priorityBudgetRatio,
    this.otherRatio = BudgetConstants.otherBudgetRatio,
    this.savingsGoal = BudgetConstants.defaultSavingsGoal,
  });

  /// Validate ratios sum to 1.0
  bool get isValid => (priorityRatio + otherRatio - 1.0).abs() < 0.01;
}

