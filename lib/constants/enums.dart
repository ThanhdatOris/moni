// =============================================================================
// CENTRALIZED ENUMERATIONS FOR MONI APP
// =============================================================================
// This file contains all enum definitions used across the application.
// Organized by category for better maintainability.
// =============================================================================

// =============================================================================
// MODEL ENUMS
// =============================================================================

/// Enum cho loại giao dịch
enum TransactionType {
  income,
  expense;

  String get value {
    switch (this) {
      case TransactionType.income:
        return 'INCOME';
      case TransactionType.expense:
        return 'EXPENSE';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INCOME':
        return TransactionType.income;
      case 'EXPENSE':
        return TransactionType.expense;
      default:
        throw ArgumentError('Loại giao dịch không hợp lệ: $value');
    }
  }
}

/// Enum cho loại báo cáo
enum ReportType {
  byTime,
  byCategory;

  String get value {
    switch (this) {
      case ReportType.byTime:
        return 'BY_TIME';
      case ReportType.byCategory:
        return 'BY_CATEGORY';
    }
  }

  static ReportType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BY_TIME':
        return ReportType.byTime;
      case 'BY_CATEGORY':
        return ReportType.byCategory;
      default:
        throw ArgumentError('Loại báo cáo không hợp lệ: $value');
    }
  }
}

/// Enum cho khoảng thời gian báo cáo
enum TimePeriod {
  monthly,
  quarterly,
  yearly;

  String get value {
    switch (this) {
      case TimePeriod.monthly:
        return 'MONTHLY';
      case TimePeriod.quarterly:
        return 'QUARTERLY';
      case TimePeriod.yearly:
        return 'YEARLY';
    }
  }

  static TimePeriod fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MONTHLY':
        return TimePeriod.monthly;
      case 'QUARTERLY':
        return TimePeriod.quarterly;
      case 'YEARLY':
        return TimePeriod.yearly;
      default:
        throw ArgumentError('Khoảng thời gian báo cáo không hợp lệ: $value');
    }
  }
}

/// Enum định nghĩa các loại icon cho danh mục
enum CategoryIconType {
  material('material'),
  emoji('emoji'),
  custom('custom');

  const CategoryIconType(this.value);
  final String value;

  static CategoryIconType fromString(String value) {
    switch (value) {
      case 'material':
        return CategoryIconType.material;
      case 'emoji':
        return CategoryIconType.emoji;
      case 'custom':
        return CategoryIconType.custom;
      default:
        return CategoryIconType.material;
    }
  }
}

/// Budget status enum
enum BudgetStatus {
  good,
  warning,
  overBudget,
}

/// Budget alert type enum
enum BudgetAlertType {
  nearLimit,
  overBudget,
  reset,
}

/// Response types for the Global Agent API
enum AgentResponseType {
  text,
  analytics,
  budget,
  report,
  error,
}

/// Response status for the Global Agent API
enum AgentResponseStatus {
  success,
  error,
  pending,
}

/// Request types for the Global Agent API
enum AgentRequestType {
  chat,
  analytics,
  budget,
  report,
}

// =============================================================================
// SERVICE ENUMS
// =============================================================================

/// Enum định nghĩa loại lỗi
enum ErrorType {
  network,
  authentication,
  validation,
  permission,
  firestore,
  unknown,
}

/// Enum định nghĩa mức độ log
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Enum định nghĩa loại thông báo
enum NotificationType {
  success,
  info,
  warning,
  error,
}

/// Tần suất recurring
/// Mức độ rủi ro trùng lặp
enum DuplicateRiskLevel {
  none,
  low,
  medium,
  high,
}

/// Loại hành động xử lý trùng lặp
enum DuplicateActionType {
  proceed,
  warn,
  block,
  review,
}

/// Loại giới hạn
enum LimitType {
  daily,
  weekly,
  monthly,
}

/// Mức độ cảnh báo
enum WarningSeverity {
  low,
  medium,
  high,
  critical,
}

/// Cache priority levels
enum CachePriority {
  high,   // Categories, frequent queries
  medium, // Insights, analysis
  low,    // Chat history
}

/// Password strength levels
enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
  veryStrong,
}

/// Extension for PasswordStrength
extension PasswordStrengthExtension on PasswordStrength {
  String get displayName {
    switch (this) {
      case PasswordStrength.none:
        return 'Chưa nhập';
      case PasswordStrength.weak:
        return 'Yếu';
      case PasswordStrength.medium:
        return 'Trung bình';
      case PasswordStrength.strong:
        return 'Mạnh';
      case PasswordStrength.veryStrong:
        return 'Rất mạnh';
    }
  }

  /// Note: Color getter is in input_validator.dart to avoid Flutter dependency here
}

// =============================================================================
// UI/WIDGET ENUMS
// =============================================================================

/// Loading types for different content scenarios
enum LoadingType {
  chart,
  list,
  form,
  aiResponse,
  generic,
}

/// Button types for assistant actions
enum ButtonType {
  primary,
  secondary,
  outline,
}

/// Report categories
enum ReportCategory {
  financial,
  spending,
  budget,
  investment,
  custom,
}

/// Export types
enum ExportType {
  pdf,
  excel,
  word,
  csv,
  image,
}

/// Chart types (consolidated from multiple files)
enum ChartType {
  bar,
  line,
  pie,
  donut,
  area,
  scatter,
  candlestick,
  radar,
  combination,
  combined;

  String get displayName {
    switch (this) {
      case ChartType.bar:
        return 'Biểu đồ cột';
      case ChartType.line:
        return 'Biểu đồ đường';
      case ChartType.pie:
        return 'Biểu đồ tròn';
      case ChartType.donut:
        return 'Biểu đồ vòng';
      case ChartType.area:
        return 'Biểu đồ vùng';
      case ChartType.scatter:
        return 'Biểu đồ phân tán';
      case ChartType.candlestick:
        return 'Biểu đồ nến';
      case ChartType.radar:
        return 'Biểu đồ radar';
      case ChartType.combination:
      case ChartType.combined:
        return 'Biểu đồ kết hợp';
    }
  }
}

/// Report section types
enum ReportSectionType {
  chart,
  table,
  summary,
  analysis,
}

/// Budget period enumeration
enum BudgetPeriod {
  weekly('Tuần'),
  monthly('Tháng'),
  yearly('Năm');

  const BudgetPeriod(this.displayName);
  final String displayName;
}

/// Budget tip categories
enum BudgetTipCategory {
  saving,
  spending,
  investment,
  general,
}

/// Kết quả advanced validation dialog
enum AdvancedValidationResult {
  proceed,
  cancel,
}

// =============================================================================
// CHART SYSTEM ENUMS
// =============================================================================

/// Chart time period enumeration
enum ChartTimePeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom;

  String get displayName {
    switch (this) {
      case ChartTimePeriod.daily:
        return 'Hàng ngày';
      case ChartTimePeriod.weekly:
        return 'Hàng tuần';
      case ChartTimePeriod.monthly:
        return 'Hàng tháng';
      case ChartTimePeriod.quarterly:
        return 'Hàng quý';
      case ChartTimePeriod.yearly:
        return 'Hàng năm';
      case ChartTimePeriod.custom:
        return 'Tùy chỉnh';
    }
  }
}

/// Chart animation type enumeration
enum ChartAnimationType {
  none,
  fade,
  slide,
  scale,
  bounce,
  elastic;

  String get displayName {
    switch (this) {
      case ChartAnimationType.none:
        return 'Không có';
      case ChartAnimationType.fade:
        return 'Mờ dần';
      case ChartAnimationType.slide:
        return 'Trượt';
      case ChartAnimationType.scale:
        return 'Thu phóng';
      case ChartAnimationType.bounce:
        return 'Nảy';
      case ChartAnimationType.elastic:
        return 'Đàn hồi';
    }
  }
}

/// Legend position enumeration
enum LegendPosition {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  String get displayName {
    switch (this) {
      case LegendPosition.top:
        return 'Trên';
      case LegendPosition.bottom:
        return 'Dưới';
      case LegendPosition.left:
        return 'Trái';
      case LegendPosition.right:
        return 'Phải';
      case LegendPosition.topLeft:
        return 'Trên trái';
      case LegendPosition.topRight:
        return 'Trên phải';
      case LegendPosition.bottomLeft:
        return 'Dưới trái';
      case LegendPosition.bottomRight:
        return 'Dưới phải';
    }
  }
}

/// Income expense chart modes
enum IncomeExpenseChartMode {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  comparison;

  String get displayName {
    switch (this) {
      case IncomeExpenseChartMode.daily:
        return 'Hàng ngày';
      case IncomeExpenseChartMode.weekly:
        return 'Hàng tuần';
      case IncomeExpenseChartMode.monthly:
        return 'Hàng tháng';
      case IncomeExpenseChartMode.quarterly:
        return 'Hàng quý';
      case IncomeExpenseChartMode.yearly:
        return 'Hàng năm';
      case IncomeExpenseChartMode.comparison:
        return 'So sánh';
    }
  }
}

/// Income expense display modes
enum IncomeExpenseDisplayMode {
  bar,
  line,
  area,
  combined;

  String get displayName {
    switch (this) {
      case IncomeExpenseDisplayMode.bar:
        return 'Cột';
      case IncomeExpenseDisplayMode.line:
        return 'Đường';
      case IncomeExpenseDisplayMode.area:
        return 'Vùng';
      case IncomeExpenseDisplayMode.combined:
        return 'Kết hợp';
    }
  }
}

/// Analysis insight types
enum InsightType {
  info,
  positive,
  warning,
  negative,
  critical;

  String get displayName {
    switch (this) {
      case InsightType.info:
        return 'Thông tin';
      case InsightType.positive:
        return 'Tích cực';
      case InsightType.warning:
        return 'Cảnh báo';
      case InsightType.negative:
        return 'Tiêu cực';
      case InsightType.critical:
        return 'Nghiêm trọng';
    }
  }
}

/// Chart export formats
enum ChartExportFormat {
  png,
  jpg,
  pdf,
  svg,
  csv,
  xlsx;

  String get displayName {
    switch (this) {
      case ChartExportFormat.png:
        return 'PNG Image';
      case ChartExportFormat.jpg:
        return 'JPG Image';
      case ChartExportFormat.pdf:
        return 'PDF Document';
      case ChartExportFormat.svg:
        return 'SVG Vector';
      case ChartExportFormat.csv:
        return 'CSV Data';
      case ChartExportFormat.xlsx:
        return 'Excel File';
    }
  }

  String get fileExtension {
    switch (this) {
      case ChartExportFormat.png:
        return '.png';
      case ChartExportFormat.jpg:
        return '.jpg';
      case ChartExportFormat.pdf:
        return '.pdf';
      case ChartExportFormat.svg:
        return '.svg';
      case ChartExportFormat.csv:
        return '.csv';
      case ChartExportFormat.xlsx:
        return '.xlsx';
    }
  }
}

/// Chart interaction modes
enum ChartInteractionMode {
  none,
  tap,
  longPress,
  pinchZoom,
  pan,
  all;

  String get displayName {
    switch (this) {
      case ChartInteractionMode.none:
        return 'Không tương tác';
      case ChartInteractionMode.tap:
        return 'Chạm';
      case ChartInteractionMode.longPress:
        return 'Chạm giữ';
      case ChartInteractionMode.pinchZoom:
        return 'Thu phóng';
      case ChartInteractionMode.pan:
        return 'Kéo';
      case ChartInteractionMode.all:
        return 'Tất cả';
    }
  }
}

/// Chart theme modes
enum ChartThemeMode {
  light,
  dark,
  auto,
  custom;

  String get displayName {
    switch (this) {
      case ChartThemeMode.light:
        return 'Sáng';
      case ChartThemeMode.dark:
        return 'Tối';
      case ChartThemeMode.auto:
        return 'Tự động';
      case ChartThemeMode.custom:
        return 'Tùy chỉnh';
    }
  }
}

/// Data aggregation types
enum DataAggregationType {
  sum,
  average,
  median,
  min,
  max,
  count;

  String get displayName {
    switch (this) {
      case DataAggregationType.sum:
        return 'Tổng';
      case DataAggregationType.average:
        return 'Trung bình';
      case DataAggregationType.median:
        return 'Trung vị';
      case DataAggregationType.min:
        return 'Nhỏ nhất';
      case DataAggregationType.max:
        return 'Lớn nhất';
      case DataAggregationType.count:
        return 'Số lượng';
    }
  }
}

/// Chart loading states
enum ChartLoadingState {
  idle,
  loading,
  loaded,
  error,
  empty;

  String get displayName {
    switch (this) {
      case ChartLoadingState.idle:
        return 'Chờ';
      case ChartLoadingState.loading:
        return 'Đang tải';
      case ChartLoadingState.loaded:
        return 'Đã tải';
      case ChartLoadingState.error:
        return 'Lỗi';
      case ChartLoadingState.empty:
        return 'Trống';
    }
  }
}

