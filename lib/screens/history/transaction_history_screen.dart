import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/config/app_config.dart';

import '../../models/models.dart';
import '../../services/providers/providers.dart';
import '../../utils/formatting/currency_formatter.dart';
import '../../widgets/custom_page_header.dart';
import 'transaction_detail_screen.dart';
import 'widgets/active_filters_bar.dart';
import 'widgets/advanced_filter_sheet.dart';
import 'widgets/history_calendar_grid.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_grouped_transactions_list.dart';
import 'widgets/history_summary_item.dart';
import 'widgets/history_transaction_item.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  // Backward compatibility parameters
  final String? categoryId;
  final TransactionType? filterType;
  final DateTime? filterDate;

  // New filter parameter
  final TransactionFilter? initialFilter;

  // Tab control
  final int? initialTabIndex; // 0 = Calendar, 1 = List

  const TransactionHistoryScreen({
    super.key,
    this.categoryId,
    this.filterType,
    this.filterDate,
    this.initialFilter,
    this.initialTabIndex,
  });

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late TransactionFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0, // Default = Calendar
    );

    // Initialize dates
    _selectedDay = widget.filterDate ?? DateTime.now();
    _focusedDay = widget.filterDate ?? DateTime.now();

    // Initialize filter (backward compatibility)
    if (widget.initialFilter != null) {
      _currentFilter = widget.initialFilter!;
    } else if (widget.categoryId != null || widget.filterType != null) {
      // Support old constructor parameters
      _currentFilter = TransactionFilter(
        categoryIds: widget.categoryId != null ? [widget.categoryId!] : null,
        type: widget.filterType,
      );
    } else {
      _currentFilter = TransactionFilter.empty();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    if (!mounted) return;

    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      _selectedDay = _focusedDay;
    });
  }

  Future<void> _showMonthYearPicker() async {
    if (!mounted) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
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

    if (mounted && selectedDate != null) {
      setState(() {
        _focusedDay = DateTime(selectedDate.year, selectedDate.month, 1);
        _selectedDay = _focusedDay;
      });
    }
  }

  Future<void> _showAdvancedFilter() async {
    final newFilter = await AdvancedFilterSheet.show(context, _currentFilter);
    if (newFilter != null && mounted) {
      setState(() {
        _currentFilter = newFilter;
      });
    }
  }

  void _updateFilter(TransactionFilter newFilter) {
    if (!mounted) return;
    setState(() {
      _currentFilter = newFilter;
    });
  }

  Map<DateTime, List<TransactionModel>> _groupTransactionsByDay(
    List<TransactionModel> transactions,
  ) {
    Map<DateTime, List<TransactionModel>> data = {};
    for (var transaction in transactions) {
      if (transaction.isDeleted) continue;
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      if (data[date] != null) {
        data[date]!.add(transaction);
      } else {
        data[date] = [transaction];
      }
    }
    return data;
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> allTransactions) {
    var filtered = allTransactions.where((t) => !t.isDeleted).toList();

    // Category filter
    if (_currentFilter.categoryIds != null &&
        _currentFilter.categoryIds!.isNotEmpty) {
      filtered = filtered
          .where((t) => _currentFilter.categoryIds!.contains(t.categoryId))
          .toList();
    }

    // Type filter
    if (_currentFilter.type != null) {
      filtered = filtered.where((t) => t.type == _currentFilter.type).toList();
    }

    // Date range filter
    if (_currentFilter.startDate != null) {
      filtered = filtered
          .where(
            (t) =>
                t.date.isAfter(_currentFilter.startDate!) ||
                t.date.isAtSameMomentAs(_currentFilter.startDate!),
          )
          .toList();
    }
    if (_currentFilter.endDate != null) {
      filtered = filtered
          .where(
            (t) =>
                t.date.isBefore(_currentFilter.endDate!) ||
                t.date.isAtSameMomentAs(_currentFilter.endDate!),
          )
          .toList();
    }

    // Amount range filter
    if (_currentFilter.minAmount != null) {
      filtered = filtered
          .where((t) => t.amount >= _currentFilter.minAmount!)
          .toList();
    }
    if (_currentFilter.maxAmount != null) {
      filtered = filtered
          .where((t) => t.amount <= _currentFilter.maxAmount!)
          .toList();
    }

    // Search filter
    if (_currentFilter.searchQuery != null &&
        _currentFilter.searchQuery!.isNotEmpty) {
      final query = _currentFilter.searchQuery!.toLowerCase();
      filtered = filtered
          .where((t) => t.note?.toLowerCase().contains(query) ?? false)
          .toList();
    }

    // Apply sorting
    _applySorting(filtered);

    return filtered;
  }

  void _applySorting(List<TransactionModel> transactions) {
    switch (_currentFilter.sortBy) {
      case TransactionSortBy.date:
        transactions.sort(
          (a, b) => _currentFilter.ascending
              ? a.date.compareTo(b.date)
              : b.date.compareTo(a.date),
        );
        break;
      case TransactionSortBy.amount:
        transactions.sort(
          (a, b) => _currentFilter.ascending
              ? a.amount.compareTo(b.amount)
              : b.amount.compareTo(a.amount),
        );
        break;
      case TransactionSortBy.category:
        transactions.sort(
          (a, b) => _currentFilter.ascending
              ? a.categoryId.compareTo(b.categoryId)
              : b.categoryId.compareTo(a.categoryId),
        );
        break;
    }
  }

  List<TransactionModel> _getTransactionsForDay(
    DateTime day,
    Map<DateTime, List<TransactionModel>> transactions,
  ) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return transactions[normalizedDay] ?? [];
  }

  double _getDayTotal(
    DateTime day,
    TransactionType type,
    Map<DateTime, List<TransactionModel>> transactions,
  ) {
    final dayTransactions = _getTransactionsForDay(day, transactions);
    return dayTransactions
        .where((t) => t.type == type)
        .fold(0.0, (total, t) => total + t.amount);
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatAmountWithCurrency(amount);
  }

  void _navigateToTransactionDetail(TransactionModel transaction) async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );

    // If transaction was deleted or updated, invalidate cache
    if (mounted && result == true) {
      ref.invalidate(allTransactionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            CustomPageHeader(
              icon: Icons.history,
              title: 'Lịch sử giao dịch',
              subtitle: 'Xem và quản lý lịch sử giao dịch',
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                labelPadding: const EdgeInsets.symmetric(vertical: 6),
                tabs: const [
                  Tab(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, size: 18),
                        SizedBox(width: 8),
                        Text('Lịch'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list, size: 18),
                        SizedBox(width: 8),
                        Text('Danh sách'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters Bar
            ActiveFiltersBar(
              filter: _currentFilter,
              onFilterChanged: _updateFilter,
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildCalendarView(), _buildListView()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Tránh menubar
        child: FloatingActionButton(
          onPressed: _showAdvancedFilter,
          backgroundColor: AppColors.primary,
          child: Stack(
            children: [
              const Center(child: Icon(Icons.filter_list, color: Colors.white)),
              if (_currentFilter.hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_currentFilter.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final allTransactions = transactionsAsync.value ?? [];
    final filteredTransactions = _applyFilters(allTransactions);

    // Get transactions for current month
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final monthTransactions = filteredTransactions
        .where(
          (t) =>
              t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              t.date.isBefore(endOfMonth.add(const Duration(days: 1))),
        )
        .toList();

    final transactionsByDay = _groupTransactionsByDay(monthTransactions);
    final selectedDayTransactions = _getTransactionsForDay(
      _selectedDay,
      transactionsByDay,
    );

    final isLoading = transactionsAsync.isLoading;

    return CustomScrollView(
      slivers: [
        // Calendar Grid
        SliverToBoxAdapter(
          child: HistoryCalendarGrid(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            transactions: transactionsByDay,
            onMonthChanged: _changeMonth,
            onMonthYearPicker: _showMonthYearPicker,
            onDaySelected: (day) {
              if (!mounted) return;
              setState(() {
                _selectedDay = day;
              });
            },
          ),
        ),

        // Selected day summary
        if (selectedDayTransactions.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: HistorySummaryItem(
                      title: 'Thu nhập',
                      amount: _formatCurrency(
                        _getDayTotal(
                          _selectedDay,
                          TransactionType.income,
                          transactionsByDay,
                        ),
                      ),
                      icon: Icons.trending_up,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: HistorySummaryItem(
                      title: 'Chi tiêu',
                      amount: _formatCurrency(
                        _getDayTotal(
                          _selectedDay,
                          TransactionType.expense,
                          transactionsByDay,
                        ),
                      ),
                      icon: Icons.trending_down,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Loading indicator
        if (isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),

        // Empty state
        if (!isLoading && selectedDayTransactions.isEmpty)
          SliverFillRemaining(
            child: HistoryEmptyState(selectedDay: _selectedDay),
          ),

        // Transactions list for selected day
        if (!isLoading && selectedDayTransactions.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return HistoryTransactionItem(
                  transaction: selectedDayTransactions[index],
                  onTap: () => _navigateToTransactionDetail(
                    selectedDayTransactions[index],
                  ),
                );
              }, childCount: selectedDayTransactions.length),
            ),
          ),

        // Bottom spacing
        if (!isLoading && selectedDayTransactions.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildListView() {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final allTransactions = transactionsAsync.value ?? [];
    final filteredTransactions = _applyFilters(allTransactions);
    final isLoading = transactionsAsync.isLoading;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : filteredTransactions.isEmpty
        ? const HistoryEmptyState(isListView: true)
        : HistoryGroupedTransactionsList(
            transactions: filteredTransactions,
            onTransactionTap: _navigateToTransactionDetail,
          );
  }
}
