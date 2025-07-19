import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';

class HistoryEmptyState extends StatelessWidget {
  final DateTime? selectedDay;
  final bool isListView;

  const HistoryEmptyState({
    super.key,
    this.selectedDay,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isListView) {
      return _buildEmptyListState();
    } else {
      return _buildEmptyCalendarState();
    }
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

  Widget _buildEmptyCalendarState() {
    if (selectedDay == null) {
      return _buildEmptyListState();
    }

    final isToday = selectedDay!.day == DateTime.now().day &&
        selectedDay!.month == DateTime.now().month &&
        selectedDay!.year == DateTime.now().year;

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
            DateFormat('dd/MM/yyyy').format(selectedDay!),
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
} 