import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/enums.dart';
import '../../../models/category_model.dart';
import '../models/chart_config_models.dart';

/// Factory class để tạo chart configurations một cách nhất quán
/// Giảm code duplication và đảm bảo consistency
class ChartConfigFactory {
  /// Tạo expense analysis chart config với category colors
  static CompleteChartConfig createExpenseAnalysisConfig({
    required String title,
    required ChartTimePeriod timePeriod,
    required DateTime startDate,
    required List<CategoryModel> categories,
    DateTime? endDate,
    LegendPosition legendPosition = LegendPosition.right,
    int legendMaxColumns = 1,
  }) {
    return CompleteChartConfig(
      chart: ChartConfiguration(
        title: title,
        type: ChartType.pie,
        timePeriod: timePeriod,
        showLegend: true,
        isInteractive: true,
        animationType: ChartAnimationType.fade,
        animationDuration: const Duration(milliseconds: 800),
      ),
      filter: ChartFilterConfig(
        startDate: startDate,
        endDate: endDate ?? DateTime.now(),
        includeIncome: false,
        includeExpense: true,
      ),
      legend: ChartLegendConfig(
        show: true,
        position: legendPosition,
        maxColumns: legendMaxColumns,
      ),
      tooltip: const ChartTooltipConfig(
        enabled: true,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      ),
      style: ChartStyleConfig(
        backgroundColor: Colors.transparent,
        colorPalette: _generateColorPalette(categories),
      ),
    );
  }

  /// Tạo income vs expense chart config với category colors
  static CompleteChartConfig createIncomeExpenseConfig({
    required String title,
    required ChartTimePeriod timePeriod,
    required DateTime startDate,
    required List<CategoryModel> categories,
    DateTime? endDate,
    ChartType chartType = ChartType.bar,
    LegendPosition legendPosition = LegendPosition.bottom,
    int legendMaxColumns = 2,
  }) {
    return CompleteChartConfig(
      chart: ChartConfiguration(
        title: title,
        type: chartType,
        timePeriod: timePeriod,
        showLegend: true,
        isInteractive: true,
        animationType: ChartAnimationType.fade,
        animationDuration: const Duration(milliseconds: 800),
      ),
      filter: ChartFilterConfig(
        startDate: startDate,
        endDate: endDate ?? DateTime.now(),
        includeIncome: true,
        includeExpense: true,
      ),
      legend: ChartLegendConfig(
        show: true,
        position: legendPosition,
        maxColumns: legendMaxColumns,
      ),
      tooltip: const ChartTooltipConfig(
        enabled: true,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      ),
      style: ChartStyleConfig(
        backgroundColor: Colors.transparent,
        colorPalette: _generateColorPalette(categories),
      ),
    );
  }

  /// Tạo category analysis chart config với category colors
  static CompleteChartConfig createCategoryAnalysisConfig({
    required String title,
    required ChartTimePeriod timePeriod,
    required DateTime startDate,
    required List<CategoryModel> categories,
    DateTime? endDate,
    ChartType chartType = ChartType.pie,
    LegendPosition legendPosition = LegendPosition.right,
    int legendMaxColumns = 1,
  }) {
    return CompleteChartConfig(
      chart: ChartConfiguration(
        title: title,
        type: chartType,
        timePeriod: timePeriod,
        showLegend: true,
        isInteractive: true,
        animationType: ChartAnimationType.fade,
        animationDuration: const Duration(milliseconds: 800),
      ),
      filter: ChartFilterConfig(
        startDate: startDate,
        endDate: endDate ?? DateTime.now(),
        includeIncome: false,
        includeExpense: true,
      ),
      legend: ChartLegendConfig(
        show: true,
        position: legendPosition,
        maxColumns: legendMaxColumns,
      ),
      tooltip: const ChartTooltipConfig(
        enabled: true,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      ),
      style: ChartStyleConfig(
        backgroundColor: Colors.transparent,
        colorPalette: _generateColorPalette(categories),
      ),
    );
  }

  /// Tạo trend analysis chart config với category colors
  static CompleteChartConfig createTrendAnalysisConfig({
    required String title,
    required ChartTimePeriod timePeriod,
    required DateTime startDate,
    required List<CategoryModel> categories,
    DateTime? endDate,
    ChartType chartType = ChartType.line,
    LegendPosition legendPosition = LegendPosition.bottom,
    int legendMaxColumns = 2,
  }) {
    return CompleteChartConfig(
      chart: ChartConfiguration(
        title: title,
        type: chartType,
        timePeriod: timePeriod,
        showLegend: true,
        isInteractive: true,
        animationType: ChartAnimationType.fade,
        animationDuration: const Duration(milliseconds: 800),
      ),
      filter: ChartFilterConfig(
        startDate: startDate,
        endDate: endDate ?? DateTime.now(),
        includeIncome: true,
        includeExpense: true,
      ),
      legend: ChartLegendConfig(
        show: true,
        position: legendPosition,
        maxColumns: legendMaxColumns,
      ),
      tooltip: const ChartTooltipConfig(
        enabled: true,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      ),
      style: ChartStyleConfig(
        backgroundColor: Colors.transparent,
        colorPalette: _generateColorPalette(categories),
      ),
    );
  }

  /// Utility method để chuyển đổi period string thành ChartTimePeriod
  static ChartTimePeriod getTimePeriodFromString(String period) {
    switch (period) {
      case 'Tuần này':
        return ChartTimePeriod.weekly;
      case '30 ngày':
        return ChartTimePeriod.monthly;
      case 'Quý này':
        return ChartTimePeriod.quarterly;
      case 'Năm nay':
        return ChartTimePeriod.yearly;
      case 'Tháng này':
      default:
        return ChartTimePeriod.monthly;
    }
  }

  /// Utility method để tính start date từ period
  static DateTime getStartDateFromPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Tuần này':
        return now.subtract(Duration(days: now.weekday - 1));
      case '30 ngày':
        return now.subtract(const Duration(days: 30));
      case 'Quý này':
        final quarter = ((now.month - 1) / 3).floor();
        return DateTime(now.year, quarter * 3 + 1, 1);
      case 'Năm nay':
        return DateTime(now.year, 1, 1);
      case 'Tháng này':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  /// Generate color palette từ categories với fallback colors
  static List<Color> _generateColorPalette(List<CategoryModel> categories) {
    final colors = <Color>[];
    final fallbackColors = [
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.primaryLight,
      AppColors.food,
      AppColors.transport,
      AppColors.shopping,
      AppColors.entertainment,
      AppColors.bills,
      AppColors.health,
      AppColors.income,
      AppColors.expense,
    ];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      if (category.color != 0) {
        // Convert int color to Color object
        colors.add(Color(category.color));
      } else {
        // Use fallback color nếu category không có màu
        colors.add(fallbackColors[i % fallbackColors.length]);
      }
    }

    return colors;
  }
}
