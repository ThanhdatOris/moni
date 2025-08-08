/// Chart system enumerations
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

/// Chart type enumeration
enum ChartType {
  bar,
  line,
  pie,
  area,
  scatter,
  candlestick,
  radar,
  combination;

  String get displayName {
    switch (this) {
      case ChartType.bar:
        return 'Biểu đồ cột';
      case ChartType.line:
        return 'Biểu đồ đường';
      case ChartType.pie:
        return 'Biểu đồ tròn';
      case ChartType.area:
        return 'Biểu đồ vùng';
      case ChartType.scatter:
        return 'Biểu đồ phân tán';
      case ChartType.candlestick:
        return 'Biểu đồ nến';
      case ChartType.radar:
        return 'Biểu đồ radar';
      case ChartType.combination:
        return 'Biểu đồ kết hợp';
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

