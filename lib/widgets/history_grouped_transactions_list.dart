import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import 'history_date_header.dart';
import 'history_transaction_item.dart';

class HistoryGroupedTransactionsList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Function(TransactionModel) onTransactionTap;

  const HistoryGroupedTransactionsList({
    super.key,
    required this.transactions,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    HistoryDateHeader(
                      dateKey: dateKey,
                      transactions: dayTransactions,
                    ),

                    // Transactions for this date
                    ...dayTransactions.map((transaction) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: HistoryTransactionItem(
                          transaction: transaction,
                          onTap: () => onTransactionTap(transaction),
                          isListView: true,
                        ),
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
} 