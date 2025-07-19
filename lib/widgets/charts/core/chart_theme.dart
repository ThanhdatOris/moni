import 'package:flutter/material.dart';

import '../../../constants/enums.dart';
import '../models/chart_config_models.dart';

/// Base chart theme configuration
class ChartTheme {
  final ColorScheme colorScheme;
  final List<Color> primaryPalette;
  final List<Color> categoryColors;
  final TextTheme textTheme;
  final ChartStyleConfig defaultStyle;
  final Map<ChartType, ChartStyleConfig> typeSpecificStyles;

  const ChartTheme({
    required this.colorScheme,
    required this.primaryPalette,
    required this.categoryColors,
    required this.textTheme,
    required this.defaultStyle,
    required this.typeSpecificStyles,
  });

  /// Light theme configuration
  static ChartTheme light() {
    const colorScheme = ColorScheme.light();

    return ChartTheme(
      colorScheme: colorScheme,
      primaryPalette: _lightPrimaryPalette,
      categoryColors: _defaultCategoryColors,
      textTheme: _defaultTextTheme,
      defaultStyle: ChartStyleConfig(
        backgroundColor: Colors.white,
        gridColor: Colors.grey.shade200,
        axisColor: Colors.grey.shade600,
        colorPalette: _lightPrimaryPalette,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      typeSpecificStyles: _lightTypeSpecificStyles,
    );
  }

  /// Dark theme configuration
  static ChartTheme dark() {
    const colorScheme = ColorScheme.dark();

    return ChartTheme(
      colorScheme: colorScheme,
      primaryPalette: _darkPrimaryPalette,
      categoryColors: _defaultCategoryColors,
      textTheme: _defaultTextTheme.apply(bodyColor: Colors.white),
      defaultStyle: ChartStyleConfig(
        backgroundColor: Colors.grey.shade900,
        gridColor: Colors.grey.shade700,
        axisColor: Colors.grey.shade400,
        colorPalette: _darkPrimaryPalette,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      typeSpecificStyles: _darkTypeSpecificStyles,
    );
  }

  /// Get style for specific chart type
  ChartStyleConfig getStyleForType(ChartType type) {
    return typeSpecificStyles[type] ?? defaultStyle;
  }

  /// Get color for data series by index
  Color getSeriesColor(int index) {
    return primaryPalette[index % primaryPalette.length];
  }

  /// Get color for category by ID
  Color getCategoryColor(String categoryId, int fallbackIndex) {
    // In a real implementation, this would map category IDs to specific colors
    // For now, use the fallback index
    return categoryColors[fallbackIndex % categoryColors.length];
  }
}

/// Light theme color palette
const List<Color> _lightPrimaryPalette = [
  Color(0xFF2196F3), // Blue
  Color(0xFF4CAF50), // Green
  Color(0xFFFF9800), // Orange
  Color(0xFF9C27B0), // Purple
  Color(0xFFF44336), // Red
  Color(0xFF00BCD4), // Cyan
  Color(0xFFFFEB3B), // Yellow
  Color(0xFF795548), // Brown
  Color(0xFF607D8B), // Blue Grey
  Color(0xFFE91E63), // Pink
];

/// Dark theme color palette
const List<Color> _darkPrimaryPalette = [
  Color(0xFF64B5F6), // Light Blue
  Color(0xFF81C784), // Light Green
  Color(0xFFFFB74D), // Light Orange
  Color(0xFFBA68C8), // Light Purple
  Color(0xFFE57373), // Light Red
  Color(0xFF4DD0E1), // Light Cyan
  Color(0xFFFFF176), // Light Yellow
  Color(0xFFA1887F), // Light Brown
  Color(0xFF90A4AE), // Light Blue Grey
  Color(0xFFF06292), // Light Pink
];

/// Default category colors
const List<Color> _defaultCategoryColors = [
  Color(0xFFFF9800), // Orange - Food
  Color(0xFF2196F3), // Blue - Transport
  Color(0xFF9C27B0), // Purple - Shopping
  Color(0xFFE91E63), // Pink - Entertainment
  Color(0xFF607D8B), // Blue Grey - Bills
  Color(0xFF4CAF50), // Green - Health
  Color(0xFFF44336), // Red - Emergency
  Color(0xFF00BCD4), // Cyan - Travel
  Color(0xFFFFEB3B), // Yellow - Education
  Color(0xFF795548), // Brown - Home
];

/// Default text theme for charts
const TextTheme _defaultTextTheme = TextTheme(
  titleLarge: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
  titleMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
  titleSmall: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  ),
  bodyLarge: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  ),
  bodyMedium: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  ),
  bodySmall: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  ),
  labelSmall: TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.normal,
  ),
);

/// Light theme type-specific styles
final Map<ChartType, ChartStyleConfig> _lightTypeSpecificStyles = {
  ChartType.pie: ChartStyleConfig(
    backgroundColor: Colors.transparent,
    gridColor: Colors.transparent,
    axisColor: Colors.transparent,
    colorPalette: _lightPrimaryPalette,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  ChartType.bar: ChartStyleConfig(
    backgroundColor: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF757575),
    colorPalette: _lightPrimaryPalette,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  ),
  ChartType.line: ChartStyleConfig(
    backgroundColor: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    axisColor: Color(0xFF757575),
    colorPalette: _lightPrimaryPalette,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  ),
};

/// Dark theme type-specific styles
final Map<ChartType, ChartStyleConfig> _darkTypeSpecificStyles = {
  ChartType.pie: ChartStyleConfig(
    backgroundColor: Colors.transparent,
    gridColor: Colors.transparent,
    axisColor: Colors.transparent,
    colorPalette: _darkPrimaryPalette,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  ChartType.bar: ChartStyleConfig(
    backgroundColor: Color(0xFF212121),
    gridColor: Color(0xFF424242),
    axisColor: Color(0xFF9E9E9E),
    colorPalette: _darkPrimaryPalette,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  ),
  ChartType.line: ChartStyleConfig(
    backgroundColor: Color(0xFF212121),
    gridColor: Color(0xFF424242),
    axisColor: Color(0xFF9E9E9E),
    colorPalette: _darkPrimaryPalette,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  ),
};

/// Chart theme extensions for commonly used configurations
extension ChartThemeExtensions on ChartTheme {
  /// Get default chart configuration
  ChartConfiguration getDefaultConfig({
    required String title,
    ChartType type = ChartType.line,
    ChartTimePeriod timePeriod = ChartTimePeriod.monthly,
  }) {
    return ChartConfiguration(
      title: title,
      type: type,
      timePeriod: timePeriod,
    );
  }

  /// Get default legend configuration
  ChartLegendConfig getDefaultLegendConfig() {
    return ChartLegendConfig(
      textStyle: textTheme.bodyMedium,
    );
  }

  /// Get default tooltip configuration
  ChartTooltipConfig getDefaultTooltipConfig() {
    return ChartTooltipConfig(
      backgroundColor: colorScheme.surface,
      textColor: colorScheme.onSurface,
    );
  }

  /// Get primary color
  Color get primaryColor => colorScheme.primary;

  /// Get background color
  Color get backgroundColor => colorScheme.surface;

  /// Get grid color
  Color get gridColor => colorScheme.outline.withValues(alpha: 0.1);

  /// Get text color
  Color get textColor => colorScheme.onSurface;

  /// Get tooltip background color
  Color get tooltipBackgroundColor => colorScheme.surface;

  /// Get tooltip text color
  Color get tooltipTextColor => colorScheme.onSurface;

  /// Get income color
  Color get incomeColor => const Color(0xFF4CAF50);

  /// Get expense color
  Color get expenseColor => const Color(0xFFF44336);

  /// Get savings color
  Color get savingsColor => const Color(0xFF2196F3);

  /// Get warning color
  Color get warningColor => const Color(0xFFFF9800);

  /// Get success color
  Color get successColor => const Color(0xFF4CAF50);

  /// Get error color
  Color get errorColor => const Color(0xFFF44336);
}

/// Income vs Expense specific theme
class IncomeExpenseTheme {
  final Color incomeColor;
  final Color expenseColor;
  final Color savingsColor;
  final Color debtColor;
  final Gradient incomeGradient;
  final Gradient expenseGradient;

  const IncomeExpenseTheme({
    required this.incomeColor,
    required this.expenseColor,
    required this.savingsColor,
    required this.debtColor,
    required this.incomeGradient,
    required this.expenseGradient,
  });

  static const IncomeExpenseTheme light = IncomeExpenseTheme(
    incomeColor: Color(0xFF4CAF50),
    expenseColor: Color(0xFFF44336),
    savingsColor: Color(0xFF2196F3),
    debtColor: Color(0xFFFF5722),
    incomeGradient: LinearGradient(
      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    expenseGradient: LinearGradient(
      colors: [Color(0xFFF44336), Color(0xFFE57373)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const IncomeExpenseTheme dark = IncomeExpenseTheme(
    incomeColor: Color(0xFF81C784),
    expenseColor: Color(0xFFE57373),
    savingsColor: Color(0xFF64B5F6),
    debtColor: Color(0xFFFF8A65),
    incomeGradient: LinearGradient(
      colors: [Color(0xFF81C784), Color(0xFFA5D6A7)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    expenseGradient: LinearGradient(
      colors: [Color(0xFFE57373), Color(0xFFEF9A9A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}

/// Chart theme provider widget
class ChartThemeProvider extends InheritedWidget {
  final ChartTheme theme;

  const ChartThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  static ChartTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ChartThemeProvider>();
    if (provider != null) {
      return provider.theme;
    }

    // Fallback to theme based on brightness
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? ChartTheme.dark()
        : ChartTheme.light();
  }

  @override
  bool updateShouldNotify(ChartThemeProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}
