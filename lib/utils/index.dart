// =============================================================================
// UTILS EXPORT FILE
// =============================================================================

// Extension methods
export 'extensions/date_extensions.dart';
export 'extensions/list_extensions.dart';
export 'extensions/string_extensions.dart';
// =============================================================================
// LEGACY EXPORTS (for backward compatibility)
// =============================================================================

// Re-export specific classes for backward compatibility
export 'formatting/currency_formatter.dart' show CurrencyFormatter;
// Formatting utilities
export 'formatting/currency_formatter.dart';
export 'formatting/date_formatter.dart' show DateFormatter, DateRange;
export 'formatting/date_formatter.dart';
// Helper utilities
export 'helpers/category_icon_helper.dart';
export 'helpers/category_icon_helper.dart' show CategoryIconHelper;
// date_helper.dart is deprecated - use DateFormatter instead
// export 'helpers/date_helper.dart' hide DateRange; // DEPRECATED: Use DateFormatter
export 'helpers/list_helper.dart';
export 'helpers/string_helper.dart';
// Logging utilities
export 'logging/logging_utils.dart';
// Validation utilities
export 'validation/input_validator.dart';
