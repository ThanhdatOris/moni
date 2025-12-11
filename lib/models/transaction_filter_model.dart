import 'package:flutter/material.dart';
import 'package:moni/constants/enums.dart';

/// Model quản lý bộ lọc giao dịch
/// Thiết kế để dễ dàng navigation từ charts, categories, home
class TransactionFilter {
  final List<String>? categoryIds; // Filter theo nhiều categories
  final TransactionType? type; // Thu nhập / Chi tiêu
  final DateTime? startDate; // Ngày bắt đầu
  final DateTime? endDate; // Ngày kết thúc
  final double? minAmount; // Số tiền tối thiểu
  final double? maxAmount; // Số tiền tối đa
  final String? searchQuery; // Tìm kiếm trong note
  final TransactionSortBy sortBy; // Sắp xếp
  final bool ascending; // Tăng/giảm dần

  const TransactionFilter({
    this.categoryIds,
    this.type,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.sortBy = TransactionSortBy.date,
    this.ascending = false,
  });

  /// Empty filter - không lọc gì
  factory TransactionFilter.empty() {
    return const TransactionFilter();
  }

  /// Filter by category (dùng khi click category trong charts/home)
  factory TransactionFilter.byCategory(String categoryId) {
    return TransactionFilter(categoryIds: [categoryId]);
  }

  /// Filter by categories (multiple)
  factory TransactionFilter.byCategories(List<String> categoryIds) {
    return TransactionFilter(categoryIds: categoryIds);
  }

  /// Filter by type
  factory TransactionFilter.byType(TransactionType type) {
    return TransactionFilter(type: type);
  }

  /// Filter by date range
  factory TransactionFilter.byDateRange(DateTime start, DateTime end) {
    return TransactionFilter(startDate: start, endDate: end);
  }

  /// Filter by month (từ charts)
  factory TransactionFilter.byMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return TransactionFilter(startDate: startOfMonth, endDate: endOfMonth);
  }

  /// Có filter active không?
  bool get hasActiveFilters {
    return categoryIds != null ||
        type != null ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Số lượng filters active
  int get activeFilterCount {
    int count = 0;
    if (categoryIds != null && categoryIds!.isNotEmpty) count++;
    if (type != null) count++;
    if (startDate != null || endDate != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    return count;
  }

  /// Copy with new values
  TransactionFilter copyWith({
    List<String>? categoryIds,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    TransactionSortBy? sortBy,
    bool? ascending,
    bool clearCategoryIds = false,
    bool clearType = false,
    bool clearDates = false,
    bool clearAmounts = false,
    bool clearSearch = false,
  }) {
    return TransactionFilter(
      categoryIds: clearCategoryIds ? null : (categoryIds ?? this.categoryIds),
      type: clearType ? null : (type ?? this.type),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  /// Clear all filters
  TransactionFilter clearAll() {
    return TransactionFilter.empty();
  }

  @override
  String toString() {
    return 'TransactionFilter('
        'categoryIds: $categoryIds, '
        'type: $type, '
        'startDate: $startDate, '
        'endDate: $endDate, '
        'minAmount: $minAmount, '
        'maxAmount: $maxAmount, '
        'searchQuery: $searchQuery, '
        'sortBy: $sortBy, '
        'ascending: $ascending)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransactionFilter &&
        _listEquals(other.categoryIds, categoryIds) &&
        other.type == type &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.searchQuery == searchQuery &&
        other.sortBy == sortBy &&
        other.ascending == ascending;
  }

  @override
  int get hashCode {
    return Object.hash(
      categoryIds,
      type,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      searchQuery,
      sortBy,
      ascending,
    );
  }

  bool _listEquals(List? a, List? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Sort options
enum TransactionSortBy {
  date,
  amount,
  category,
}

extension TransactionSortByExtension on TransactionSortBy {
  String get displayName {
    switch (this) {
      case TransactionSortBy.date:
        return 'Ngày';
      case TransactionSortBy.amount:
        return 'Số tiền';
      case TransactionSortBy.category:
        return 'Danh mục';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionSortBy.date:
        return Icons.calendar_today;
      case TransactionSortBy.amount:
        return Icons.attach_money;
      case TransactionSortBy.category:
        return Icons.category;
    }
  }
}

