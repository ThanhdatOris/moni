import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../constants/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_page_header.dart';
import 'widgets/history_calendar_grid.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_grouped_transactions_list.dart';
import 'widgets/history_summary_item.dart';
import 'widgets/history_transaction_item.dart';
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

  // Stream subscriptions
  StreamSubscription<List<TransactionModel>>? _monthlyTransactionsSubscription;
  StreamSubscription<List<TransactionModel>>? _allTransactionsSubscription;

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
    _monthlyTransactionsSubscription?.cancel();
    _allTransactionsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Cancel existing subscriptions
      await _monthlyTransactionsSubscription?.cancel();
      await _allTransactionsSubscription?.cancel();

      // Lấy giao dịch của tháng được chọn cho calendar view
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      _monthlyTransactionsSubscription = _transactionService
          .getTransactions(
        startDate: startOfMonth,
        endDate: endOfMonth,
      )
          .listen(
        (transactions) {
          if (mounted) {
            setState(() {
              _transactions = _groupTransactionsByDay(transactions);
              _selectedDayTransactions = _getTransactionsForDay(_selectedDay);
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );

      // Lấy tất cả giao dịch cho list view
      _allTransactionsSubscription =
          _transactionService.getTransactions().listen(
        (transactions) {
          if (mounted) {
            setState(() {
              _allTransactions = transactions;
            });
          }
        },
        onError: (error) {
          // Handle error silently for all transactions
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeMonth(int delta) {
    if (!mounted) return;

    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      // Reset selected day to first of new month
      _selectedDay = _focusedDay;
      _selectedDayTransactions = [];
    });
    _loadTransactions();
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

  List<TransactionModel> _getFilteredTransactions() {
    if (_filterType == null) return _allTransactions;
    return _allTransactions.where((t) => t.type == _filterType).toList();
  }

  List<TransactionModel> _getTransactionsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _transactions[normalizedDay] ?? [];
  }

  double _getDayTotal(DateTime day, TransactionType type) {
    final transactions = _getTransactionsForDay(day);
    return transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
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

    // If transaction was deleted or updated, refresh the view
    if (mounted && result == true) {
      _loadTransactions();
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
    return CustomScrollView(
      slivers: [
        // Calendar Grid
        SliverToBoxAdapter(
          child: HistoryCalendarGrid(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            transactions: _transactions,
            onMonthChanged: _changeMonth,
            onMonthYearPicker: _showMonthYearPicker,
            onDaySelected: (day) {
              if (!mounted) return;
              setState(() {
                _selectedDay = day;
                _selectedDayTransactions = _getTransactionsForDay(day);
              });
            },
          ),
        ),

        // Selected day summary
        if (_selectedDayTransactions.isNotEmpty)
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
                          _getDayTotal(_selectedDay, TransactionType.income)),
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
                          _getDayTotal(_selectedDay, TransactionType.expense)),
                      icon: Icons.trending_down,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Loading indicator
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),

        // Empty state
        if (!_isLoading && _selectedDayTransactions.isEmpty)
          SliverFillRemaining(
            child: HistoryEmptyState(selectedDay: _selectedDay),
          ),

        // Transactions list for selected day
        if (!_isLoading && _selectedDayTransactions.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return HistoryTransactionItem(
                    transaction: _selectedDayTransactions[index],
                    onTap: () => _navigateToTransactionDetail(
                        _selectedDayTransactions[index]),
                  );
                },
                childCount: _selectedDayTransactions.length,
              ),
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
                  ? const HistoryEmptyState(isListView: true)
                  : HistoryGroupedTransactionsList(
                      transactions: _getFilteredTransactions(),
                      onTransactionTap: _navigateToTransactionDetail,
                    ),
        ),
      ],
    );
  }
}
