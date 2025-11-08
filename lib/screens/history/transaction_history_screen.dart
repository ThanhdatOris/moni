import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/constants/app_colors.dart';

import '../../models/transaction_model.dart';
import '../../services/providers/providers.dart';
import '../../utils/formatting/currency_formatter.dart';
import '../../utils/formatting/date_formatter.dart';
import '../../widgets/custom_page_header.dart';
import 'transaction_detail_screen.dart';
import 'widgets/history_calendar_grid.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_grouped_transactions_list.dart';
import 'widgets/history_summary_item.dart';
import 'widgets/history_transaction_item.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final TransactionType? filterType;
  final DateTime? filterDate;

  const TransactionHistoryScreen({
    super.key,
    this.categoryId,
    this.filterType,
    this.filterDate,
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
  TransactionType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with filter data or defaults
    _selectedDay = widget.filterDate ?? DateTime.now();
    _focusedDay = widget.filterDate ?? DateTime.now();
    _filterType = widget.filterType;
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
      // Reset selected day to first of new month
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

  Map<DateTime, List<TransactionModel>> _groupTransactionsByDay(
      List<TransactionModel> transactions) {
    Map<DateTime, List<TransactionModel>> data = {};
    for (var transaction in transactions) {
      if (transaction.isDeleted) continue;
      final date = DateTime(
          transaction.date.year, transaction.date.month, transaction.date.day);
      if (data[date] != null) {
        data[date]!.add(transaction);
      } else {
        data[date] = [transaction];
      }
    }
    return data;
  }

  List<TransactionModel> _getFilteredTransactions(
      List<TransactionModel> allTransactions) {
    var filtered = allTransactions;

    // Filter by category if provided
    if (widget.categoryId != null) {
      filtered =
          filtered.where((t) => t.categoryId == widget.categoryId).toList();
    }

    // Filter by type
    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    return filtered;
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
                tabs: [
                  Tab(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, size: 18),
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
                        Text('Danh sách'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCalendarView(),
                  _buildListView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    // Watch providers for calendar view
    final transactionsAsync = ref.watch(allTransactionsProvider);

    // Get transactions for current month
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final monthRange = DateRange(start: startOfMonth, end: endOfMonth);
    final monthTransactions =
        ref.watch(transactionsByDateRangeProvider(monthRange));

    // Group transactions by day
    final transactionsByDay = _groupTransactionsByDay(monthTransactions);
    final selectedDayTransactions =
        _getTransactionsForDay(_selectedDay, transactionsByDay);

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
                      amount: _formatCurrency(_getDayTotal(_selectedDay,
                          TransactionType.income, transactionsByDay)),
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
                      amount: _formatCurrency(_getDayTotal(_selectedDay,
                          TransactionType.expense, transactionsByDay)),
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return HistoryTransactionItem(
                    transaction: selectedDayTransactions[index],
                    onTap: () => _navigateToTransactionDetail(
                        selectedDayTransactions[index]),
                  );
                },
                childCount: selectedDayTransactions.length,
              ),
            ),
          ),

        // Bottom spacing for calendar view when transactions exist
        if (!isLoading && selectedDayTransactions.isNotEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
      ],
    );
  }

  Widget _buildListView() {
    // Watch providers for list view
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final allTransactions = transactionsAsync.value ?? [];
    final filteredTransactions = _getFilteredTransactions(allTransactions);
    final isLoading = transactionsAsync.isLoading;

    return Column(
      children: [
        // Filter Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<TransactionType?>(
            initialValue: _filterType,
            decoration: InputDecoration(
              labelText: 'Lọc theo loại giao dịch',
              prefixIcon: Icon(Icons.filter_list, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
            ),
            items: const [
              DropdownMenuItem(
                value: null,
                child: Text('Tất cả giao dịch'),
              ),
              DropdownMenuItem(
                value: TransactionType.income,
                child: Text('Thu nhập'),
              ),
              DropdownMenuItem(
                value: TransactionType.expense,
                child: Text('Chi tiêu'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _filterType = value;
              });
            },
          ),
        ),

        // Grouped Transactions List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredTransactions.isEmpty
                  ? const HistoryEmptyState(isListView: true)
                  : HistoryGroupedTransactionsList(
                      transactions: filteredTransactions,
                      onTransactionTap: _navigateToTransactionDetail,
                    ),
        ),
      ],
    );
  }
}
