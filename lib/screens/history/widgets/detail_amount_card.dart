import 'package:flutter/material.dart';

import 'package:moni/config/app_config.dart';

import '../../../models/transaction_model.dart';
import '../../../utils/formatting/currency_formatter.dart';

class DetailAmountCard extends StatelessWidget {
  final TransactionModel transaction;

  const DetailAmountCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: transaction.type == TransactionType.income
              ? [
                  AppColors.success,
                  AppColors.success.withValues(alpha: 0.8)
                ]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (transaction.type == TransactionType.income
                    ? AppColors.success
                    : AppColors.error)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            transaction.type == TransactionType.income
                ? 'Thu nhập'
                : 'Chi tiêu',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${transaction.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.formatAmountWithCurrency(transaction.amount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
