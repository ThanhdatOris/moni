import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/duplicate_detection_service.dart';
import '../utils/currency_formatter.dart';

/// Widget hiển thị cảnh báo giao dịch trùng lặp
class BudgetDuplicateWarningDialog extends StatelessWidget {
  final DuplicateDetectionResult result;
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  const BudgetDuplicateWarningDialog({
    super.key,
    required this.result,
    required this.onProceed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getWarningIcon(),
            color: _getWarningColor(),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            _getTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getWarningColor(),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDescription(),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (result.duplicates.isNotEmpty) ...[
              const Text(
                'Giao dịch tương tự:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...result.duplicates.take(3).map((duplicate) => 
                _buildDuplicateItem(duplicate)).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getActionColor(),
            foregroundColor: Colors.white,
          ),
          child: Text(_getActionText()),
        ),
      ],
    );
  }

  Widget _buildDuplicateItem(DuplicateMatch duplicate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  CurrencyFormatter.formatCurrency(duplicate.transaction.amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getScoreColor(duplicate.score),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(duplicate.score * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Danh mục: ${duplicate.transaction.categoryId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if ((duplicate.transaction.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              duplicate.transaction.note ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormatter.formatDateTime(duplicate.transaction.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          if (duplicate.reasons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: duplicate.reasons.map((reason) => 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getWarningIcon() {
    switch (result.riskLevel) {
      case DuplicateRiskLevel.high:
        return Icons.dangerous;
      case DuplicateRiskLevel.medium:
        return Icons.warning;
      case DuplicateRiskLevel.low:
        return Icons.info;
      case DuplicateRiskLevel.none:
        return Icons.check_circle;
    }
  }

  Color _getWarningColor() {
    switch (result.riskLevel) {
      case DuplicateRiskLevel.high:
        return Colors.red;
      case DuplicateRiskLevel.medium:
        return Colors.orange;
      case DuplicateRiskLevel.low:
        return Colors.blue;
      case DuplicateRiskLevel.none:
        return Colors.green;
    }
  }

  Color _getActionColor() {
    switch (result.riskLevel) {
      case DuplicateRiskLevel.high:
        return Colors.red;
      case DuplicateRiskLevel.medium:
        return Colors.orange;
      case DuplicateRiskLevel.low:
        return AppColors.primary;
      case DuplicateRiskLevel.none:
        return AppColors.primary;
    }
  }

  String _getTitle() {
    switch (result.riskLevel) {
      case DuplicateRiskLevel.high:
        return 'Giao dịch trùng lặp';
      case DuplicateRiskLevel.medium:
        return 'Cảnh báo trùng lặp';
      case DuplicateRiskLevel.low:
        return 'Giao dịch tương tự';
      case DuplicateRiskLevel.none:
        return 'Xác nhận giao dịch';
    }
  }

  String _getDescription() {
    switch (result.riskLevel) {
      case DuplicateRiskLevel.high:
        return 'Phát hiện giao dịch có khả năng trùng lặp cao. Vui lòng kiểm tra kỹ trước khi tiếp tục.';
      case DuplicateRiskLevel.medium:
        return 'Phát hiện giao dịch tương tự gần đây. Bạn có chắc chắn muốn tiếp tục?';
      case DuplicateRiskLevel.low:
        return 'Tìm thấy một số giao dịch tương tự. Hãy xem lại để đảm bảo không bị trùng lặp.';
      case DuplicateRiskLevel.none:
        return 'Không phát hiện giao dịch trùng lặp.';
    }
  }

  String _getActionText() {
    switch (result.riskLevel) {
      case DuplicateRiskLevel.high:
        return 'Vẫn tiếp tục';
      case DuplicateRiskLevel.medium:
        return 'Tiếp tục';
      case DuplicateRiskLevel.low:
        return 'Lưu giao dịch';
      case DuplicateRiskLevel.none:
        return 'Xác nhận';
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) return Colors.red;
    if (score >= 0.8) return Colors.orange;
    if (score >= 0.6) return Colors.amber;
    return Colors.green;
  }

  /// Hiển thị dialog cảnh báo trùng lặp
  static Future<bool> show(
    BuildContext context,
    DuplicateDetectionResult result,
  ) async {
    if (!result.hasDuplicates) return true;

    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BudgetDuplicateWarningDialog(
        result: result,
        onProceed: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    return shouldProceed ?? false;
  }
}

/// Extension để thêm format date
extension DateFormatter on DateTime {
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
