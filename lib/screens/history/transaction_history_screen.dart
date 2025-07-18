import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_page_header.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final GetIt _getIt = GetIt.instance;
  late final TransactionService _transactionService;

  Map<DateTime, List<TransactionModel>> _transactions = {};
  List<TransactionModel> _selectedDayTransactions = [];
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;
  TransactionType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _transactionService = _getIt<TransactionService>();
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy giao dịch của tháng được chọn cho calendar view
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      _transactionService
          .getTransactions(
        startDate: startOfMonth,
        endDate: endOfMonth,
      )
          .listen((transactions) {
        if (mounted) {
          setState(() {
            _transactions = _groupTransactionsByDay(transactions);
            _selectedDayTransactions = _getTransactionsForDay(_selectedDay);
            _isLoading = false;
          });
        }
      });

      // Lấy tất cả giao dịch cho list view
      _transactionService.getTransactions().listen((transactions) {
        if (mounted) {
          setState(() {
            _allTransactions = transactions;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      // Reset selected day to first of new month
      _selectedDay = _focusedDay;
      _selectedDayTransactions = [];
    });
    _loadTransactions();
  }

  Future<void> _showMonthYearPicker() async {
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

    if (selectedDate != null) {
      setState(() {
        _focusedDay = DateTime(selectedDate.year, selectedDate.month, 1);
        _selectedDay = _focusedDay;
        _selectedDayTransactions = [];
      });
      _loadTransactions();
    }
  }

  Map<DateTime, List<TransactionModel>> _groupTransactionsByDay(
      List<TransactionModel> transactions) {
    Map<DateTime, List<TransactionModel>> data = {};
    for (var transaction in transactions) {
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

  List<TransactionModel> _getTransactionsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _transactions[normalizedDay] ?? [];
  }

  List<TransactionModel> _getFilteredTransactions() {
    if (_filterType == null) return _allTransactions;
    return _allTransactions.where((t) => t.type == _filterType).toList();
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate(
      List<TransactionModel> transactions) {
    Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    // Sort by date descending
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }

  String _getDateGroupHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate.isAtSameMomentAs(today)) {
      return 'Hôm nay';
    } else if (transactionDate.isAtSameMomentAs(yesterday)) {
      return 'Hôm qua';
    } else if (now.difference(transactionDate).inDays < 7) {
      return DateFormat('EEEE', 'vi_VN').format(date);
    } else {
      return DateFormat('dd/MM/yyyy', 'vi_VN').format(date);
    }
  }

  void _navigateToTransactionDetail(TransactionModel transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );

    // If transaction was deleted or updated, refresh the view
    if (result == true) {
      _loadTransactions();
    }
  }

  double _getDayTotal(DateTime day, TransactionType type) {
    final transactions = _getTransactionsForDay(day);
    return transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
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
    return Column(
      children: [
        const SizedBox(height: 16),

        // Calendar Grid
        _buildCalendarGrid(),

        // Selected day summary
        if (_selectedDayTransactions.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Thu nhập',
                    _formatCurrency(
                        _getDayTotal(_selectedDay, TransactionType.income)),
                    Icons.trending_up,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Chi tiêu',
                    _formatCurrency(
                        _getDayTotal(_selectedDay, TransactionType.expense)),
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ),

        // Transactions list for selected day
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedDayTransactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _selectedDayTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(
                            _selectedDayTransactions[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        // Filter Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<TransactionType?>(
            value: _filterType,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _getFilteredTransactions().isEmpty
                  ? _buildEmptyListState()
                  : _buildGroupedTransactionsList(),
        ),
      ],
    );
  }

  Widget _buildGroupedTransactionsList() {
    final transactions = _getFilteredTransactions();
    final groupedTransactions = _groupTransactionsByDate(transactions);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entries = groupedTransactions.entries.toList();
                final entry = entries[index];
                final dateKey = entry.key;
                final dayTransactions = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    _buildDateHeader(dateKey, dayTransactions),

                    // Transactions for this date
                    ...dayTransactions.map((transaction) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildTransactionListItem(transaction),
                      );
                    }),

                    // Add spacing after each group except the last
                    if (index < entries.length - 1) const SizedBox(height: 20),
                  ],
                );
              },
              childCount: groupedTransactions.length,
            ),
          ),
        ),
        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

    Widget _buildDateHeader(String dateKey, List<TransactionModel> transactions) {
    final headerText = _getDateGroupHeader(dateKey);
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netAmount = totalIncome - totalExpense;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Header row  
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      headerText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${transactions.length} giao dịch',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Summary row
          if (totalIncome > 0 || totalExpense > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (totalIncome > 0)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.formatAmountWithCurrency(
                                  totalIncome),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (totalIncome > 0 && totalExpense > 0)
                  const SizedBox(width: 8),
                if (totalExpense > 0)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.formatAmountWithCurrency(
                                  totalExpense),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (totalIncome > 0 && totalExpense > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: netAmount >= 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${netAmount >= 0 ? '+' : ''}${CurrencyFormatter.formatAmountWithCurrency(netAmount.abs())}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: netAmount >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;
    final now = DateTime.now();
    final isCurrentMonth =
        _focusedDay.year == now.year && _focusedDay.month == now.month;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Header with Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Previous Month Button
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.all(8),
                  ),
                ),

                // Month/Year Display (Clickable)
                Expanded(
                  child: GestureDetector(
                    onTap: _showMonthYearPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy', 'vi_VN')
                                .format(_focusedDay),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Next Month Button
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          // Month Stats & Quick Actions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                // Current Month Indicator
                if (isCurrentMonth)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tháng hiện tại',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Transaction Count
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_transactions.values.fold(0, (sum, list) => sum + list.length)} giao dịch',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Today Button
                if (!isCurrentMonth)
                  GestureDetector(
                    onTap: () {
                      final today = DateTime.now();
                      setState(() {
                        _focusedDay = DateTime(today.year, today.month, 1);
                        _selectedDay = today;
                        _selectedDayTransactions = [];
                      });
                      _loadTransactions();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.primaryDark.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.today,
                            size: 12,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hôm nay',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Weekday headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                  .map((day) => Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Calendar days
          Container(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 42, // 6 weeks
              itemBuilder: (context, index) {
                final dayNumber = index - firstWeekday + 2;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox();
                }

                final day =
                    DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
                return _buildCalendarDay(day);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day) {
    final income = _getDayTotal(day, TransactionType.income);
    final expense = _getDayTotal(day, TransactionType.expense);
    final hasTransactions = income > 0 || expense > 0;
    final isSelected = day.day == _selectedDay.day &&
        day.month == _selectedDay.month &&
        day.year == _selectedDay.year;
    final isToday = day.day == DateTime.now().day &&
        day.month == DateTime.now().month &&
        day.year == DateTime.now().year;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _selectedDayTransactions = _getTransactionsForDay(day);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : hasTransactions
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : null,
          borderRadius: BorderRadius.circular(8),
          border: hasTransactions
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected || isToday
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
            if (hasTransactions) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (income > 0)
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (income > 0 && expense > 0) const SizedBox(width: 2),
                  if (expense > 0)
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    return GestureDetector(
      onTap: () => _navigateToTransactionDetail(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (transaction.type == TransactionType.income
                        ? AppColors.success
                        : AppColors.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                transaction.type == TransactionType.income
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: transaction.type == TransactionType.income
                    ? AppColors.success
                    : AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note ?? 'Không có ghi chú',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(transaction.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.type == TransactionType.income ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == TransactionType.income
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionListItem(TransactionModel transaction) {
    return GestureDetector(
      onTap: () => _navigateToTransactionDetail(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (transaction.type == TransactionType.income
                        ? AppColors.success
                        : AppColors.error)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                transaction.type == TransactionType.income
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                color: transaction.type == TransactionType.income
                    ? AppColors.success
                    : AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note ?? 'Không có ghi chú',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.type == TransactionType.income ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == TransactionType.income
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isToday = _selectedDay.day == DateTime.now().day &&
        _selectedDay.month == DateTime.now().month &&
        _selectedDay.year == DateTime.now().year;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isToday ? Icons.today_outlined : Icons.event_note_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isToday ? 'Chưa có giao dịch hôm nay' : 'Không có giao dịch nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd/MM/yyyy').format(_selectedDay),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 16),
            Text(
              'Hãy thêm giao dịch đầu tiên của bạn!',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyListState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm giao dịch đầu tiên của bạn!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatAmountWithCurrency(amount);
  }
}
