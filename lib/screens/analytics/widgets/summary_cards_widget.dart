/// Summary Cards Widget - Hiển thị tổng quan tài chính
/// Được tách từ AnalyticsScreen để cải thiện maintainability

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/currency_formatter.dart';

class SummaryCardsWidget extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final String incomeChange;
  final String expenseChange;
  final bool isLoading;

  const SummaryCardsWidget({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.incomeChange,
    required this.expenseChange,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCards();
    }

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'Tổng thu',
            amount: totalIncome,
            icon: Icons.trending_up,
            color: AppColors.income,
            change: incomeChange,
            isPositiveChange: _isPositiveChange(incomeChange),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            title: 'Tổng chi',
            amount: totalExpense,
            icon: Icons.trending_down,
            color: AppColors.expense,
            change: expenseChange,
            isPositiveChange: false, // Expense increase is not positive
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCards() {
    return Row(
      children: [
        Expanded(child: _buildLoadingCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildLoadingCard()),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              Container(
                width: 50,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPositiveChange(String change) {
    return change.startsWith('+');
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String change;
  final bool isPositiveChange;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.change,
    required this.isPositiveChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTitle(),
          const SizedBox(height: 4),
          _buildAmount(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const Spacer(),
        _buildChangeIndicator(),
      ],
    );
  }

  Widget _buildChangeIndicator() {
    final changeColor = isPositiveChange ? AppColors.success : AppColors.warning;
    final changeIcon = isPositiveChange ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: changeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            changeIcon,
            color: changeColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            change,
            style: TextStyle(
              color: changeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    );
  }

  Widget _buildAmount() {
    return Text(
      CurrencyFormatter.formatVND(amount),
      style: TextStyle(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Widget for balance display
class BalanceCard extends StatelessWidget {
  final double balance;
  final bool isLoading;

  const BalanceCard({
    super.key,
    required this.balance,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLoading ? _buildLoadingContent() : _buildContent(),
    );
  }

  Widget _buildContent() {
    final isPositive = balance >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: AppColors.textWhite,
              size: 24,
            ),
            const Spacer(),
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: AppColors.textWhite,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Số dư hiện tại',
          style: TextStyle(
            color: AppColors.textWhite.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatVND(balance.abs()),
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!isPositive) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Âm',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.textWhite.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.textWhite.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: 100,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.textWhite.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 150,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.textWhite.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
} 