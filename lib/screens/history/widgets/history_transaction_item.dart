import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../models/transaction_model.dart';
import '../../../utils/currency_formatter.dart';

class HistoryTransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  final bool isListView;

  const HistoryTransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContent(),
            ),
            _buildAmount(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(isListView ? 10 : 8),
      decoration: BoxDecoration(
        color: (transaction.type == TransactionType.income
                ? AppColors.success
                : AppColors.error)
            .withValues(alpha: isListView ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(isListView ? 10 : 8),
      ),
      child: Icon(
        isListView
            ? (transaction.type == TransactionType.income
                ? Icons.add_circle_outline
                : Icons.remove_circle_outline)
            : (transaction.type == TransactionType.income
                ? Icons.arrow_upward
                : Icons.arrow_downward),
        color: transaction.type == TransactionType.income
            ? AppColors.success
            : AppColors.error,
        size: isListView ? 24 : 20,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.note ?? 'Không có ghi chú',
          style: TextStyle(
            fontSize: isListView ? 15 : 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isListView ? 6 : 4),
        if (isListView)
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
          )
        else
          Text(
            DateFormat('HH:mm').format(transaction.date),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildAmount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${transaction.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.formatAmountWithCurrency(transaction.amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: transaction.type == TransactionType.income
                ? AppColors.success
                : AppColors.error,
          ),
        ),
        SizedBox(height: isListView ? 6 : 4),
        if (isListView)
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
          )
        else
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: AppColors.textLight,
          ),
      ],
    );
  }
} 