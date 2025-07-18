import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/custom_page_header.dart';

class TransactionCalendarScreen extends StatefulWidget {
  const TransactionCalendarScreen({super.key});

  @override
  State<TransactionCalendarScreen> createState() =>
      _TransactionCalendarScreenState();
}

class _TransactionCalendarScreenState extends State<TransactionCalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final GetIt _getIt = GetIt.instance;
  late final TransactionService _transactionService;

  Map<DateTime, List<TransactionModel>> _transactions = {};
  List<TransactionModel> _selectedDayTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _transactionService = _getIt<TransactionService>();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy giao dịch của tháng hiện tại
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
    } catch (e) {
      // Error loading transactions
      setState(() {
        _isLoading = false;
      });
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
              icon: Icons.calendar_month,
              title: 'Lịch giao dịch',
              subtitle: 'Xem lịch sử giao dịch theo ngày',
            ),
            
            // Simple Calendar Grid
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

            // Transactions list
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
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat('MMMM yyyy', 'vi_VN').format(now),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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

                final day = DateTime(now.year, now.month, dayNumber);
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có giao dịch nào',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd/MM/yyyy').format(_selectedDay),
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
