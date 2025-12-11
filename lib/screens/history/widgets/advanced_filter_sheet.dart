import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/config/app_config.dart';
import 'package:moni/models/category_model.dart';
import 'package:moni/models/transaction_filter_model.dart';
import 'package:moni/services/providers/providers.dart';
import 'package:moni/utils/formatting/currency_formatter.dart';
import 'package:moni/utils/formatting/date_formatter.dart';
import 'package:moni/utils/helpers/category_icon_helper.dart';

/// Advanced Filter Bottom Sheet
class AdvancedFilterSheet extends ConsumerStatefulWidget {
  final TransactionFilter currentFilter;

  const AdvancedFilterSheet({
    super.key,
    required this.currentFilter,
  });

  @override
  ConsumerState<AdvancedFilterSheet> createState() =>
      _AdvancedFilterSheetState();

  /// Show filter sheet
  static Future<TransactionFilter?> show(
    BuildContext context,
    TransactionFilter currentFilter,
  ) {
    return showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterSheet(currentFilter: currentFilter),
    );
  }
}

class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
  late TransactionType? _selectedType;
  late List<String> _selectedCategoryIds;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late double? _minAmount;
  late double? _maxAmount;
  late String? _searchQuery;
  late TransactionSortBy _sortBy;
  late bool _ascending;

  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentFilter.type;
    _selectedCategoryIds = widget.currentFilter.categoryIds ?? [];
    _startDate = widget.currentFilter.startDate;
    _endDate = widget.currentFilter.endDate;
    _minAmount = widget.currentFilter.minAmount;
    _maxAmount = widget.currentFilter.maxAmount;
    _searchQuery = widget.currentFilter.searchQuery;
    _sortBy = widget.currentFilter.sortBy;
    _ascending = widget.currentFilter.ascending;

    if (_minAmount != null) {
      _minAmountController.text =
          CurrencyFormatter.formatDisplay(_minAmount!.toInt());
    }
    if (_maxAmount != null) {
      _maxAmountController.text =
          CurrencyFormatter.formatDisplay(_maxAmount!.toInt());
    }
    if (_searchQuery != null) {
      _searchController.text = _searchQuery!;
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filter = TransactionFilter(
      categoryIds:
          _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      searchQuery:
          _searchQuery?.trim().isEmpty ?? true ? null : _searchQuery,
      sortBy: _sortBy,
      ascending: _ascending,
    );
    Navigator.pop(context, filter);
  }

  void _clearAll() {
    setState(() {
      _selectedType = null;
      _selectedCategoryIds = [];
      _startDate = null;
      _endDate = null;
      _minAmount = null;
      _maxAmount = null;
      _searchQuery = null;
      _sortBy = TransactionSortBy.date;
      _ascending = false;
      _minAmountController.clear();
      _maxAmountController.clear();
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final allCategories = categoriesAsync.value ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Bộ lọc nâng cao',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Xóa hết'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type
                    _buildSectionTitle('Loại giao dịch'),
                    _buildTypeSelector(),
                    const SizedBox(height: 20),

                    // Categories
                    _buildSectionTitle('Danh mục'),
                    _buildCategorySelector(allCategories),
                    const SizedBox(height: 20),

                    // Date Range
                    _buildSectionTitle('Khoảng thời gian'),
                    _buildDateRangeSelector(),
                    const SizedBox(height: 20),

                    // Amount Range
                    _buildSectionTitle('Khoảng số tiền'),
                    _buildAmountRangeSelector(),
                    const SizedBox(height: 20),

                    // Search
                    _buildSectionTitle('Tìm kiếm trong ghi chú'),
                    _buildSearchField(),
                    const SizedBox(height: 20),

                    // Sort
                    _buildSectionTitle('Sắp xếp'),
                    _buildSortSelector(),
                    const SizedBox(height: 32),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeChip(
            label: 'Tất cả',
            icon: Icons.all_inclusive,
            isSelected: _selectedType == null,
            onTap: () => setState(() => _selectedType = null),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTypeChip(
            label: 'Thu nhập',
            icon: Icons.trending_up,
            color: Colors.green,
            isSelected: _selectedType == TransactionType.income,
            onTap: () => setState(() => _selectedType = TransactionType.income),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTypeChip(
            label: 'Chi tiêu',
            icon: Icons.trending_down,
            color: Colors.red,
            isSelected: _selectedType == TransactionType.expense,
            onTap: () =>
                setState(() => _selectedType = TransactionType.expense),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Không có danh mục',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategoryIds.contains(category.categoryId);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategoryIds.remove(category.categoryId);
              } else {
                _selectedCategoryIds.add(category.categoryId);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(category.color).withValues(alpha: 0.2)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Color(category.color)
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryIconHelper.buildIcon(
                  category,
                  size: 14,
                  color: Color(category.color),
                  isCompact: true,
                ),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Color(category.color)
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            label: 'Từ ngày',
            date: _startDate,
            onTap: () async {
              final date = await _pickDate(_startDate);
              if (date != null) {
                setState(() => _startDate = date);
              }
            },
            onClear: () => setState(() => _startDate = null),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateField(
            label: 'Đến ngày',
            date: _endDate,
            onTap: () async {
              final date = await _pickDate(_endDate);
              if (date != null) {
                setState(() => _endDate = date);
              }
            },
            onClear: () => setState(() => _endDate = null),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? DateFormatter.formatDate(date)
                        : 'Chọn ngày',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                      color: date != null ? Colors.black : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? initialDate) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _buildAmountRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Từ',
              hintText: '0',
              prefixText: '₫ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              final parsed = CurrencyFormatter.parseFormattedAmount(value);
              setState(() => _minAmount = parsed > 0 ? parsed : null);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _maxAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Đến',
              hintText: '∞',
              prefixText: '₫ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              final parsed = CurrencyFormatter.parseFormattedAmount(value);
              setState(() => _maxAmount = parsed > 0 ? parsed : null);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm trong ghi chú...',
        prefixIcon: Icon(Icons.search, color: AppColors.primary),
        suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = null);
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }

  Widget _buildSortSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSortOption(TransactionSortBy.date),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSortOption(TransactionSortBy.amount),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSortOption(TransactionSortBy.category),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOrderChip(
                label: 'Tăng dần',
                icon: Icons.arrow_upward,
                isSelected: _ascending,
                onTap: () => setState(() => _ascending = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOrderChip(
                label: 'Giảm dần',
                icon: Icons.arrow_downward,
                isSelected: !_ascending,
                onTap: () => setState(() => _ascending = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOption(TransactionSortBy sortBy) {
    final isSelected = _sortBy == sortBy;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = sortBy),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              sortBy.icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              sortBy.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

