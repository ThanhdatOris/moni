import 'package:flutter/material.dart';
import '../core/chart_theme.dart';
import '../models/chart_config_models.dart';
import '../../../constants/enums.dart';
import '../../../models/category_model.dart';

/// Chart filters component for time period and category selection
class ChartFilters extends StatefulWidget {
  final ChartFilterConfig currentFilter;
  final List<CategoryModel> availableCategories;
  final Function(ChartFilterConfig) onFilterChanged;
  final ChartTheme? theme;
  final bool showCategoryFilter;
  final bool showTimeFilter;

  const ChartFilters({
    super.key,
    required this.currentFilter,
    required this.availableCategories,
    required this.onFilterChanged,
    this.theme,
    this.showCategoryFilter = true,
    this.showTimeFilter = true,
  });

  @override
  State<ChartFilters> createState() => _ChartFiltersState();
}

class _ChartFiltersState extends State<ChartFilters> {
  late ChartFilterConfig _currentFilter;
  late List<CategoryModel> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.currentFilter;
    _selectedCategories = _getSelectedCategories();
  }

  @override
  void didUpdateWidget(ChartFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentFilter != widget.currentFilter) {
      _currentFilter = widget.currentFilter;
      _selectedCategories = _getSelectedCategories();
    }
  }

  List<CategoryModel> _getSelectedCategories() {
    if (_currentFilter.categoryIds?.isEmpty ?? true) {
      return widget.availableCategories;
    }
    return widget.availableCategories
        .where((cat) => _currentFilter.categoryIds?.contains(cat.id) ?? false)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? ChartThemeProvider.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTimeFilter) ...[
            _buildTimeFilter(theme),
            const SizedBox(height: 16),
          ],
          if (widget.showCategoryFilter) ...[
            _buildCategoryFilter(theme),
            const SizedBox(height: 16),
          ],
          _buildAmountFilter(theme),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(ChartTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khoảng thời gian',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ChartTimePeriod.values.map((period) {
            // Note: ChartFilterConfig doesn't have timePeriod, using a default
            final isSelected =
                period == ChartTimePeriod.monthly; // Default selection
            return FilterChip(
              label: Text(period.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateTimePeriod(period);
                }
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(ChartTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh mục',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: _toggleAllCategories,
              child: Text(
                _selectedCategories.length == widget.availableCategories.length
                    ? 'Bỏ chọn tất cả'
                    : 'Chọn tất cả',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconData(int.parse(category.icon),
                        fontFamily: 'MaterialIcons'),
                    size: 16,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : (category.color as Color),
                  ),
                  const SizedBox(width: 4),
                  Text(category.name),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                _toggleCategory(category, selected);
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountFilter(ChartTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lọc theo số tiền',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Từ',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0;
                  _updateMinAmount(amount);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Đến',
                  hintText: 'Không giới hạn',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  _updateMaxAmount(amount);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateTimePeriod(ChartTimePeriod period) {
    // Note: ChartFilterConfig doesn't support timePeriod
    // This would need to be handled at a higher level
    _notifyFilterChange();
  }

  void _toggleCategory(CategoryModel category, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategories.add(category);
      } else {
        _selectedCategories.remove(category);
      }
      _currentFilter = _currentFilter.copyWith(
        categoryIds: _selectedCategories.map((c) => c.id).toList(),
      );
    });
    _notifyFilterChange();
  }

  void _toggleAllCategories() {
    setState(() {
      if (_selectedCategories.length == widget.availableCategories.length) {
        _selectedCategories.clear();
      } else {
        _selectedCategories = List.from(widget.availableCategories);
      }
      _currentFilter = _currentFilter.copyWith(
        categoryIds: _selectedCategories.map((c) => c.id).toList(),
      );
    });
    _notifyFilterChange();
  }

  void _updateMinAmount(double amount) {
    setState(() {
      _currentFilter = _currentFilter.copyWith(minAmount: amount);
    });
    _notifyFilterChange();
  }

  void _updateMaxAmount(double? amount) {
    setState(() {
      _currentFilter = _currentFilter.copyWith(maxAmount: amount);
    });
    _notifyFilterChange();
  }

  void _notifyFilterChange() {
    widget.onFilterChanged(_currentFilter);
  }
}
