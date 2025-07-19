import 'package:flutter/material.dart';

import '../../../constants/enums.dart';
import 'chart_data_models.dart';

/// Chart configuration model
class ChartConfiguration {
  final String title;
  final String? subtitle;
  final ChartType type;
  final ChartTimePeriod timePeriod;
  final bool showLegend;
  final bool showAxis;
  final bool showGrid;
  final bool showTooltips;
  final bool isInteractive;
  final ChartAnimationType animationType;
  final Duration animationDuration;
  final EdgeInsets padding;
  final double aspectRatio;

  const ChartConfiguration({
    required this.title,
    this.subtitle,
    required this.type,
    this.timePeriod = ChartTimePeriod.monthly,
    this.showLegend = true,
    this.showAxis = true,
    this.showGrid = true,
    this.showTooltips = true,
    this.isInteractive = true,
    this.animationType = ChartAnimationType.fade,
    this.animationDuration = const Duration(milliseconds: 800),
    this.padding = const EdgeInsets.all(16),
    this.aspectRatio = 16 / 9,
  });

  ChartConfiguration copyWith({
    String? title,
    String? subtitle,
    ChartType? type,
    ChartTimePeriod? timePeriod,
    bool? showLegend,
    bool? showAxis,
    bool? showGrid,
    bool? showTooltips,
    bool? isInteractive,
    ChartAnimationType? animationType,
    Duration? animationDuration,
    EdgeInsets? padding,
    double? aspectRatio,
  }) {
    return ChartConfiguration(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      timePeriod: timePeriod ?? this.timePeriod,
      showLegend: showLegend ?? this.showLegend,
      showAxis: showAxis ?? this.showAxis,
      showGrid: showGrid ?? this.showGrid,
      showTooltips: showTooltips ?? this.showTooltips,
      isInteractive: isInteractive ?? this.isInteractive,
      animationType: animationType ?? this.animationType,
      animationDuration: animationDuration ?? this.animationDuration,
      padding: padding ?? this.padding,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }
}

/// Chart filter configuration
class ChartFilterConfig {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? categoryIds;
  final List<String>? excludeCategoryIds;
  final double? minAmount;
  final double? maxAmount;
  final bool includeIncome;
  final bool includeExpense;

  const ChartFilterConfig({
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.excludeCategoryIds,
    this.minAmount,
    this.maxAmount,
    this.includeIncome = true,
    this.includeExpense = true,
  });

  ChartFilterConfig copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    List<String>? excludeCategoryIds,
    double? minAmount,
    double? maxAmount,
    bool? includeIncome,
    bool? includeExpense,
  }) {
    return ChartFilterConfig(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryIds: categoryIds ?? this.categoryIds,
      excludeCategoryIds: excludeCategoryIds ?? this.excludeCategoryIds,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      includeIncome: includeIncome ?? this.includeIncome,
      includeExpense: includeExpense ?? this.includeExpense,
    );
  }

  /// Check if the filter has any active filters
  bool get hasActiveFilters {
    return startDate != null ||
        endDate != null ||
        categoryIds?.isNotEmpty == true ||
        excludeCategoryIds?.isNotEmpty == true ||
        minAmount != null ||
        maxAmount != null ||
        !includeIncome ||
        !includeExpense;
  }
}

/// Chart axis configuration
class ChartAxisConfig {
  final String? title;
  final bool showTitle;
  final bool showLabels;
  final bool showTicks;
  final double? minValue;
  final double? maxValue;
  final double? interval;
  final String Function(double)? labelFormatter;

  const ChartAxisConfig({
    this.title,
    this.showTitle = true,
    this.showLabels = true,
    this.showTicks = true,
    this.minValue,
    this.maxValue,
    this.interval,
    this.labelFormatter,
  });

  ChartAxisConfig copyWith({
    String? title,
    bool? showTitle,
    bool? showLabels,
    bool? showTicks,
    double? minValue,
    double? maxValue,
    double? interval,
    String Function(double)? labelFormatter,
  }) {
    return ChartAxisConfig(
      title: title ?? this.title,
      showTitle: showTitle ?? this.showTitle,
      showLabels: showLabels ?? this.showLabels,
      showTicks: showTicks ?? this.showTicks,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      interval: interval ?? this.interval,
      labelFormatter: labelFormatter ?? this.labelFormatter,
    );
  }
}

/// Chart legend configuration
class ChartLegendConfig {
  final bool show;
  final LegendPosition position;
  final int maxColumns;
  final EdgeInsets padding;
  final double iconSize;
  final TextStyle? textStyle;

  const ChartLegendConfig({
    this.show = true,
    this.position = LegendPosition.bottom,
    this.maxColumns = 2,
    this.padding = const EdgeInsets.all(8),
    this.iconSize = 12,
    this.textStyle,
  });

  ChartLegendConfig copyWith({
    bool? show,
    LegendPosition? position,
    int? maxColumns,
    EdgeInsets? padding,
    double? iconSize,
    TextStyle? textStyle,
  }) {
    return ChartLegendConfig(
      show: show ?? this.show,
      position: position ?? this.position,
      maxColumns: maxColumns ?? this.maxColumns,
      padding: padding ?? this.padding,
      iconSize: iconSize ?? this.iconSize,
      textStyle: textStyle ?? this.textStyle,
    );
  }
}



/// Chart tooltip configuration
class ChartTooltipConfig {
  final bool enabled;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final List<BoxShadow>? shadows;
  final String Function(ChartDataPoint)? formatter;

  const ChartTooltipConfig({
    this.enabled = true,
    this.backgroundColor = Colors.black87,
    this.textColor = Colors.white,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.shadows,
    this.formatter,
  });

  ChartTooltipConfig copyWith({
    bool? enabled,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    String Function(ChartDataPoint)? formatter,
  }) {
    return ChartTooltipConfig(
      enabled: enabled ?? this.enabled,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      shadows: shadows ?? this.shadows,
      formatter: formatter ?? this.formatter,
    );
  }
}

/// Chart style configuration
class ChartStyleConfig {
  final Color backgroundColor;
  final Color gridColor;
  final Color axisColor;
  final double gridStrokeWidth;
  final double axisStrokeWidth;
  final List<Color> colorPalette;
  final BorderRadius borderRadius;
  final List<BoxShadow>? shadows;

  const ChartStyleConfig({
    this.backgroundColor = Colors.transparent,
    this.gridColor = const Color(0xFFE0E0E0),
    this.axisColor = const Color(0xFF757575),
    this.gridStrokeWidth = 1.0,
    this.axisStrokeWidth = 2.0,
    required this.colorPalette,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shadows,
  });

  ChartStyleConfig copyWith({
    Color? backgroundColor,
    Color? gridColor,
    Color? axisColor,
    double? gridStrokeWidth,
    double? axisStrokeWidth,
    List<Color>? colorPalette,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return ChartStyleConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      axisColor: axisColor ?? this.axisColor,
      gridStrokeWidth: gridStrokeWidth ?? this.gridStrokeWidth,
      axisStrokeWidth: axisStrokeWidth ?? this.axisStrokeWidth,
      colorPalette: colorPalette ?? this.colorPalette,
      borderRadius: borderRadius ?? this.borderRadius,
      shadows: shadows ?? this.shadows,
    );
  }
}

/// Complete chart configuration combining all aspects
class CompleteChartConfig {
  final ChartConfiguration chart;
  final ChartFilterConfig filter;
  final ChartAxisConfig? xAxis;
  final ChartAxisConfig? yAxis;
  final ChartLegendConfig legend;
  final ChartTooltipConfig tooltip;
  final ChartStyleConfig style;

  const CompleteChartConfig({
    required this.chart,
    required this.filter,
    this.xAxis,
    this.yAxis,
    required this.legend,
    required this.tooltip,
    required this.style,
  });

  CompleteChartConfig copyWith({
    ChartConfiguration? chart,
    ChartFilterConfig? filter,
    ChartAxisConfig? xAxis,
    ChartAxisConfig? yAxis,
    ChartLegendConfig? legend,
    ChartTooltipConfig? tooltip,
    ChartStyleConfig? style,
  }) {
    return CompleteChartConfig(
      chart: chart ?? this.chart,
      filter: filter ?? this.filter,
      xAxis: xAxis ?? this.xAxis,
      yAxis: yAxis ?? this.yAxis,
      legend: legend ?? this.legend,
      tooltip: tooltip ?? this.tooltip,
      style: style ?? this.style,
    );
  }
}
