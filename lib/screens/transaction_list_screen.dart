import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/currency_formatter.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _selectedFilter = 'Tất cả';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Mock data
  final List<TransactionItem> _allTransactions = [
    TransactionItem(
      id: '1',
      title: 'Sườn bì chả trứng',
      category: 'Ăn uống',
      amount: -30000,
      date: DateTime.now(),
      icon: Icons.restaurant,
      color: Color(0xFFFF6B35),
    ),
    TransactionItem(
      id: '2',
      title: 'Lương tháng 12',
      category: 'Thu nhập',
      amount: 15000000,
      date: DateTime.now().subtract(Duration(days: 1)),
      icon: Icons.work,
      color: Color(0xFF4CAF50),
    ),
    TransactionItem(
      id: '3',
      title: 'Xăng xe máy',
      category: 'Di chuyển',
      amount: -200000,
      date: DateTime.now().subtract(Duration(days: 2)),
      icon: Icons.local_gas_station,
      color: Color(0xFF3182CE),
    ),
    TransactionItem(
      id: '4',
      title: 'Mua áo thun',
      category: 'Mua sắm',
      amount: -450000,
      date: DateTime.now().subtract(Duration(days: 3)),
      icon: Icons.shopping_bag,
      color: Color(0xFF9C27B0),
    ),
    TransactionItem(
      id: '5',
      title: 'Hóa đơn điện',
      category: 'Hóa đơn',
      amount: -350000,
      date: DateTime.now().subtract(Duration(days: 5)),
      icon: Icons.receipt,
      color: Color(0xFFFF9800),
    ),
    TransactionItem(
      id: '6',
      title: 'Xem phim',
      category: 'Giải trí',
      amount: -120000,
      date: DateTime.now().subtract(Duration(days: 7)),
      icon: Icons.movie,
      color: Color(0xFFE91E63),
    ),
  ];

  List<TransactionItem> get _filteredTransactions {
    List<TransactionItem> filtered = _allTransactions;

    // Filter by category
    if (_selectedFilter != 'Tất cả') {
      filtered = filtered.where((t) => t.category == _selectedFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Giao dịch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Add new transaction
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundLight,
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm giao dịch...',
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.textLight),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('Tất cả'),
                      _buildFilterChip('Thu nhập'),
                      _buildFilterChip('Ăn uống'),
                      _buildFilterChip('Di chuyển'),
                      _buildFilterChip('Mua sắm'),
                      _buildFilterChip('Giải trí'),
                      _buildFilterChip('Hóa đơn'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7043), Color(0xFFFFD180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Thu nhập',
                    '+${_formatCurrency(_getTotalIncome())}',
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
                    _formatCurrency(_getTotalExpense()),
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: _filteredTransactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(
                          _filteredTransactions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.grey300,
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionItem transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: transaction.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction.icon,
              color: transaction.color,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      transaction.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(transaction.date),
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

          // Amount
          Text(
            '${transaction.amount > 0 ? '+' : ''}${_formatCurrency(transaction.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: transaction.amount > 0
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE53E3E),
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
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có giao dịch nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc tìm kiếm',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  double _getTotalIncome() {
    return _filteredTransactions
        .where((t) => t.amount > 0)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double _getTotalExpense() {
    return _filteredTransactions
        .where((t) => t.amount < 0)
        .fold(0, (sum, t) => sum + t.amount);
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatAmountWithCurrency(amount);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Hôm qua';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class TransactionItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final IconData icon;
  final Color color;

  TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.color,
  });
}
