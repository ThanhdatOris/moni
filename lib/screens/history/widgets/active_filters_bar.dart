import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/config/app_config.dart';
import 'package:moni/models/category_model.dart';
import 'package:moni/models/transaction_filter_model.dart';
import 'package:moni/services/providers/providers.dart';
import 'package:moni/utils/formatting/currency_formatter.dart';
import 'package:moni/utils/formatting/date_formatter.dart';

/// Active Filters Bar - hiển thị các filter đang active
class ActiveFiltersBar extends ConsumerWidget {
  final TransactionFilter filter;
  final Function(TransactionFilter) onFilterChanged;

  const ActiveFiltersBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!filter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final categoriesAsync = ref.watch(allCategoriesProvider);
    final allCategories = categoriesAsync.value ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bộ lọc (${filter.activeFilterCount})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onFilterChanged(TransactionFilter.empty()),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Xóa hết'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Type filter
              if (filter.type != null)
                _buildFilterChip(
                  label: filter.type == TransactionType.income
                      ? 'Thu nhập'
                      : 'Chi tiêu',
                  icon: filter.type == TransactionType.income
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: filter.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                  onRemove: () =>
                      onFilterChanged(filter.copyWith(clearType: true)),
                ),

              // Category filters
              ...?filter.categoryIds?.map((categoryId) {
                final category = allCategories.firstWhere(
                  (cat) => cat.categoryId == categoryId,
                  orElse: () => CategoryModel(
                    categoryId: '',
                    userId: '',
                    name: 'Unknown',
                    type: TransactionType.expense,
                    icon: 'category',
                    iconType: CategoryIconType.material,
                    color: AppColors.primary.toARGB32(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    isDefault: false,
                    isSuggested: false,
                    isDeleted: false,
                  ),
                );
                return _buildFilterChip(
                  label: category.name,
                  icon: Icons.category,
                  color: Color(category.color),
                  onRemove: () {
                    final newCategoryIds = List<String>.from(
                      filter.categoryIds!,
                    );
                    newCategoryIds.remove(categoryId);
                    onFilterChanged(
                      filter.copyWith(
                        categoryIds: newCategoryIds.isEmpty
                            ? null
                            : newCategoryIds,
                        clearCategoryIds: newCategoryIds.isEmpty,
                      ),
                    );
                  },
                );
              }),

              // Date range filter
              if (filter.startDate != null || filter.endDate != null)
                _buildFilterChip(
                  label: _formatDateRange(filter.startDate, filter.endDate),
                  icon: Icons.date_range,
                  color: AppColors.primary,
                  onRemove: () =>
                      onFilterChanged(filter.copyWith(clearDates: true)),
                ),

              // Amount range filter
              if (filter.minAmount != null || filter.maxAmount != null)
                _buildFilterChip(
                  label: _formatAmountRange(filter.minAmount, filter.maxAmount),
                  icon: Icons.attach_money,
                  color: Colors.orange,
                  onRemove: () =>
                      onFilterChanged(filter.copyWith(clearAmounts: true)),
                ),

              // Search filter
              if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty)
                _buildFilterChip(
                  label: '"${filter.searchQuery}"',
                  icon: Icons.search,
                  color: Colors.purple,
                  onRemove: () =>
                      onFilterChanged(filter.copyWith(clearSearch: true)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${DateFormatter.formatDate(start)} - ${DateFormatter.formatDate(end)}';
    } else if (start != null) {
      return 'Từ ${DateFormatter.formatDate(start)}';
    } else if (end != null) {
      return 'Đến ${DateFormatter.formatDate(end)}';
    }
    return '';
  }

  String _formatAmountRange(double? min, double? max) {
    if (min != null && max != null) {
      return '${CurrencyFormatter.formatAmountShort(min)} - ${CurrencyFormatter.formatAmountShort(max)}';
    } else if (min != null) {
      return '≥ ${CurrencyFormatter.formatAmountShort(min)}';
    } else if (max != null) {
      return '≤ ${CurrencyFormatter.formatAmountShort(max)}';
    }
    return '';
  }
}
