import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:moni/services/services.dart';
import 'package:moni/constants/app_colors.dart';
import '../utils/formatting/currency_formatter.dart';

/// Dialog cảnh báo giới hạn chi tiêu
class BudgetLimitWarningDialog extends StatelessWidget {
  final LimitCheckResult result;
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  const BudgetLimitWarningDialog({
    super.key,
    required this.result,
    required this.onProceed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final criticalWarning = result.warnings
        .where((w) => w.severity == WarningSeverity.critical)
        .firstOrNull;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getWarningIcon(
                criticalWarning?.severity ?? WarningSeverity.medium),
            color: _getWarningColor(
                criticalWarning?.severity ?? WarningSeverity.medium),
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getTitle(criticalWarning?.severity ?? WarningSeverity.medium),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getWarningColor(
                    criticalWarning?.severity ?? WarningSeverity.medium),
              ),
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
              _getDescription(
                  criticalWarning?.severity ?? WarningSeverity.medium),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...result.warnings
                .map((warning) => _buildWarningItem(warning)),
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
            backgroundColor: _getActionColor(
                criticalWarning?.severity ?? WarningSeverity.medium),
            foregroundColor: Colors.white,
          ),
          child: Text(_getActionText(
              criticalWarning?.severity ?? WarningSeverity.medium)),
        ),
      ],
    );
  }

  Widget _buildWarningItem(LimitWarning warning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getWarningColor(warning.severity).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getWarningColor(warning.severity).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  warning.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getWarningColor(warning.severity),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getWarningColor(warning.severity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${warning.usagePercentage.toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                    warning.usagePercentage, warning.severity),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã chi: ${CurrencyFormatter.formatCurrency(warning.currentSpending)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Giới hạn: ${CurrencyFormatter.formatCurrency(warning.limit.amount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double percentage, WarningSeverity severity) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (percentage / 100).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: _getWarningColor(severity),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  IconData _getWarningIcon(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return Icons.dangerous;
      case WarningSeverity.high:
        return Icons.warning;
      case WarningSeverity.medium:
        return Icons.info;
      case WarningSeverity.low:
        return Icons.notifications;
    }
  }

  Color _getWarningColor(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return Colors.red;
      case WarningSeverity.high:
        return Colors.orange;
      case WarningSeverity.medium:
        return Colors.amber;
      case WarningSeverity.low:
        return Colors.blue;
    }
  }

  Color _getActionColor(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return Colors.red;
      case WarningSeverity.high:
        return Colors.orange;
      case WarningSeverity.medium:
        return Colors.amber;
      case WarningSeverity.low:
        return AppColors.primary;
    }
  }

  String _getTitle(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return 'Vượt giới hạn chi tiêu';
      case WarningSeverity.high:
        return 'Cảnh báo giới hạn';
      case WarningSeverity.medium:
        return 'Thông báo chi tiêu';
      case WarningSeverity.low:
        return 'Nhắc nhở chi tiêu';
    }
  }

  String _getDescription(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return 'Giao dịch này sẽ vượt quá giới hạn chi tiêu đã đặt. Bạn có chắc chắn muốn tiếp tục?';
      case WarningSeverity.high:
        return 'Bạn sắp đạt giới hạn chi tiêu. Hãy cân nhắc kỹ trước khi tiếp tục.';
      case WarningSeverity.medium:
        return 'Bạn đã sử dụng một phần đáng kể của giới hạn chi tiêu.';
      case WarningSeverity.low:
        return 'Chỉ là thông báo về tình trạng chi tiêu hiện tại của bạn.';
    }
  }

  String _getActionText(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return 'Vẫn tiếp tục';
      case WarningSeverity.high:
        return 'Tiếp tục';
      case WarningSeverity.medium:
        return 'Lưu giao dịch';
      case WarningSeverity.low:
        return 'Xác nhận';
    }
  }

  /// Hiển thị dialog cảnh báo giới hạn
  static Future<bool> show(
    BuildContext context,
    LimitCheckResult result,
  ) async {
    if (!result.hasWarnings) return true;

    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BudgetLimitWarningDialog(
        result: result,
        onProceed: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    return shouldProceed ?? false;
  }
}

/// Dialog để tạo/sửa giới hạn chi tiêu
class BudgetLimitEditDialog extends StatefulWidget {
  final SpendingLimit? existingLimit;
  final String? categoryId;
  final String? categoryName;

  const BudgetLimitEditDialog({
    super.key,
    this.existingLimit,
    this.categoryId,
    this.categoryName,
  });

  @override
  State<BudgetLimitEditDialog> createState() => _BudgetLimitEditDialogState();
}

class _BudgetLimitEditDialogState extends State<BudgetLimitEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  late LimitType _selectedType;
  late bool _allowOverride;
  late bool _isActive;

  @override
  void initState() {
    super.initState();

    if (widget.existingLimit != null) {
      _amountController.text = widget.existingLimit!.amount.toString();
      _selectedType = widget.existingLimit!.type;
      _allowOverride = widget.existingLimit!.allowOverride;
      _isActive = widget.existingLimit!.isActive;
    } else {
      _selectedType = LimitType.monthly;
      _allowOverride = false;
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingLimit != null
            ? 'Sửa giới hạn chi tiêu'
            : 'Tạo giới hạn chi tiêu',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.categoryName != null) ...[
                Text(
                  'Danh mục: ${widget.categoryName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Số tiền giới hạn',
                  prefixText: '₫ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Loại giới hạn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...LimitType.values.map((type) {
                final isSelected = _selectedType == type;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _getLimitTypeDisplayName(type),
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Cho phép vượt giới hạn'),
                subtitle: const Text(
                    'Hiển thị cảnh báo nhưng vẫn cho phép lưu giao dịch'),
                value: _allowOverride,
                onChanged: (value) {
                  setState(() {
                    _allowOverride = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Kích hoạt'),
                subtitle: const Text('Bật/tắt giới hạn này'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveLimit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  void _saveLimit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final now = DateTime.now();

    final limit = SpendingLimit(
      id: widget.existingLimit?.id ?? now.millisecondsSinceEpoch.toString(),
      categoryId: widget.categoryId ?? 'all',
      categoryName: widget.categoryName ?? 'Tất cả',
      amount: amount,
      type: _selectedType,
      isActive: _isActive,
      allowOverride: _allowOverride,
      createdAt: widget.existingLimit?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(limit);
  }

  String _getLimitTypeDisplayName(LimitType type) {
    switch (type) {
      case LimitType.daily:
        return 'Hàng ngày';
      case LimitType.weekly:
        return 'Hàng tuần';
      case LimitType.monthly:
        return 'Hàng tháng';
    }
  }
}

/// Widget hiển thị progress bar cho giới hạn
class BudgetLimitProgressWidget extends StatelessWidget {
  final double currentAmount;
  final double limitAmount;
  final LimitType limitType;
  final String categoryName;

  const BudgetLimitProgressWidget({
    super.key,
    required this.currentAmount,
    required this.limitAmount,
    required this.limitType,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (currentAmount / limitAmount * 100).clamp(0.0, 100.0);
    final color = _getProgressColor(percentage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.formatCurrency(currentAmount),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                CurrencyFormatter.formatCurrency(limitAmount),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return Colors.red;
    if (percentage >= 90) return Colors.orange;
    if (percentage >= 75) return Colors.amber;
    return Colors.green;
  }
}
