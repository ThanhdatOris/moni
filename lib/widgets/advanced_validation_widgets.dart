import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';
import 'package:moni/services/services.dart';

/// Dialog hiển thị advanced validation warnings
class BudgetAdvancedValidationDialog extends StatelessWidget {
  final ValidationResult validationResult;
  final RecurringTransactionSuggestion? recurringSuggestion;
  final VoidCallback onProceed;
  final VoidCallback onCancel;
  final VoidCallback? onSetupRecurring;

  const BudgetAdvancedValidationDialog({
    super.key,
    required this.validationResult,
    this.recurringSuggestion,
    required this.onProceed,
    required this.onCancel,
    this.onSetupRecurring,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.psychology,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Phân tích thông minh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (validationResult.hasWarnings) ...[
                const Text(
                  'Hệ thống phát hiện một số điểm cần lưu ý:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...validationResult.warnings.entries.map((entry) => 
                  _buildWarningItem(entry.key, entry.value)),
              ],
              
              if (recurringSuggestion != null) ...[
                const SizedBox(height: 16),
                _buildRecurringSuggestion(recurringSuggestion!),
              ],
              
              if (!validationResult.hasWarnings && recurringSuggestion == null) ...[
                const Text(
                  'Giao dịch của bạn trông tốt! Không có gì bất thường.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Hủy'),
        ),
        if (recurringSuggestion != null && onSetupRecurring != null) ...[
          TextButton(
            onPressed: onSetupRecurring,
            child: const Text('Thiết lập tự động'),
          ),
        ],
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Tiếp tục'),
        ),
      ],
    );
  }

  Widget _buildWarningItem(String key, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getWarningColor(key).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getWarningColor(key).withValues(alpha:0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getWarningIcon(key),
            color: _getWarningColor(key),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getWarningTitle(key),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getWarningColor(key),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getWarningColor(key).withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringSuggestion(RecurringTransactionSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.repeat,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Giao dịch định kỳ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống phát hiện bạn có ${suggestion.similarTransactions.length} giao dịch tương tự với khoảng cách ${suggestion.intervalDays} ngày.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.withValues(alpha:0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gợi ý: Thiết lập giao dịch tự động ${suggestion.suggestedFrequency.displayName.toLowerCase()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.withValues(alpha:0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Độ tin cậy: ${(suggestion.confidence * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getWarningColor(String key) {
    switch (key) {
      case 'unusual_amount':
      case 'large_amount':
        return Colors.orange;
      case 'high_frequency':
      case 'similar_transactions':
        return Colors.red;
      case 'unusual_time':
      case 'unusual_weekday':
        return Colors.blue;
      case 'type_mismatch':
      case 'unusual_note':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getWarningIcon(String key) {
    switch (key) {
      case 'unusual_amount':
      case 'large_amount':
        return Icons.attach_money;
      case 'high_frequency':
      case 'similar_transactions':
        return Icons.speed;
      case 'unusual_time':
      case 'unusual_weekday':
        return Icons.schedule;
      case 'type_mismatch':
      case 'unusual_note':
        return Icons.category;
      default:
        return Icons.info;
    }
  }

  String _getWarningTitle(String key) {
    switch (key) {
      case 'unusual_amount':
        return 'Số tiền bất thường';
      case 'large_amount':
        return 'Số tiền lớn';
      case 'high_frequency':
        return 'Tần suất cao';
      case 'similar_transactions':
        return 'Giao dịch tương tự';
      case 'unusual_time':
        return 'Thời gian bất thường';
      case 'unusual_weekday':
        return 'Ngày không thường';
      case 'type_mismatch':
        return 'Danh mục không phù hợp';
      case 'unusual_note':
        return 'Ghi chú khác lạ';
      default:
        return 'Thông báo';
    }
  }

  /// Hiển thị dialog advanced validation
  static Future<AdvancedValidationResult> show(
    BuildContext context, {
    required ValidationResult validationResult,
    RecurringTransactionSuggestion? recurringSuggestion,
  }) async {
    if (!validationResult.hasWarnings && recurringSuggestion == null) {
      return AdvancedValidationResult.proceed;
    }

    final result = await showDialog<AdvancedValidationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BudgetAdvancedValidationDialog(
        validationResult: validationResult,
        recurringSuggestion: recurringSuggestion,
        onProceed: () => Navigator.of(context).pop(AdvancedValidationResult.proceed),
        onCancel: () => Navigator.of(context).pop(AdvancedValidationResult.cancel),
        onSetupRecurring: recurringSuggestion != null
            ? () => Navigator.of(context).pop(AdvancedValidationResult.setupRecurring)
            : null,
      ),
    );

    return result ?? AdvancedValidationResult.cancel;
  }
}

/// Kết quả advanced validation dialog
enum AdvancedValidationResult {
  proceed,
  cancel,
  setupRecurring,
}

/// Widget hiển thị pattern insights
class BudgetPatternInsightsWidget extends StatelessWidget {
  final List<String> insights;

  const BudgetPatternInsightsWidget({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Insights thông minh',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.withValues(alpha:0.7),
                  ),
                ),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.withValues(alpha:0.8),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
