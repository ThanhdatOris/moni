import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import 'detail_amount_card.dart';
import 'detail_info_card.dart';

class DetailDetailsTab extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? selectedCategory;

  const DetailDetailsTab({
    super.key,
    required this.transaction,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Card
          DetailAmountCard(transaction: transaction),

          const SizedBox(height: 24),

          // Details Cards
          DetailInfoCard(
            icon: Icons.category_outlined,
            title: 'Danh mục',
            value: selectedCategory?.name ?? 'Đang tải...',
            categoryIcon: selectedCategory,
          ),

          const SizedBox(height: 16),

          DetailInfoCard(
            icon: Icons.calendar_today_outlined,
            title: 'Ngày',
            value: DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                .format(transaction.date),
          ),

          const SizedBox(height: 16),

          DetailInfoCard(
            icon: Icons.access_time_outlined,
            title: 'Thời gian',
            value: DateFormat('HH:mm').format(transaction.date),
          ),

          if (transaction.note?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            DetailInfoCard(
              icon: Icons.note_outlined,
              title: 'Ghi chú',
              value: transaction.note!,
              isMultiline: true,
            ),
          ],

          const SizedBox(height: 16),

          DetailInfoCard(
            icon: Icons.update_outlined,
            title: 'Cập nhật lần cuối',
            value: DateFormat('dd/MM/yyyy HH:mm')
                .format(transaction.updatedAt),
          ),
        ],
      ),
    );
  }
}
