import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/transaction_model.dart';
import '../../../services/transaction_template_service.dart';
import '../../../utils/currency_formatter.dart';

/// Widget hiển thị transaction templates
class BudgetTransactionTemplateWidget extends StatefulWidget {
  final TransactionType transactionType;
  final Function(TransactionTemplate) onTemplateSelected;
  final VoidCallback? onManageTemplates;

  const BudgetTransactionTemplateWidget({
    super.key,
    required this.transactionType,
    required this.onTemplateSelected,
    this.onManageTemplates,
  });

  @override
  State<BudgetTransactionTemplateWidget> createState() => _BudgetTransactionTemplateWidgetState();
}

class _BudgetTransactionTemplateWidgetState extends State<BudgetTransactionTemplateWidget> {
  final TransactionTemplateService _templateService = TransactionTemplateService();
  List<TransactionTemplate> _templates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void didUpdateWidget(BudgetTransactionTemplateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactionType != widget.transactionType) {
      _loadTemplates();
    }
  }

  Future<void> _loadTemplates() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final allTemplates = await _templateService.getPopularTemplates(limit: 8);
      
      // Lọc templates theo type
      final filteredTemplates = allTemplates
          .where((template) => template.type == widget.transactionType)
          .toList();

      if (mounted) {
        setState(() {
          _templates = filteredTemplates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_templates.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTemplatesList();
  }

  Widget _buildLoadingState() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Đang tải templates...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha:0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_outline,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có template nào',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tạo template để nhập giao dịch nhanh hơn',
            style: TextStyle(
              color: Colors.orange.withValues(alpha:0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onManageTemplates != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onManageTemplates,
              child: const Text('Quản lý templates'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha:0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Templates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (widget.onManageTemplates != null)
                TextButton(
                  onPressed: widget.onManageTemplates,
                  child: const Text(
                    'Quản lý',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: _buildTemplateCard(template),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(TransactionTemplate template) {
    return GestureDetector(
      onTap: () => _onTemplateTapped(template),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: template.type == TransactionType.expense
              ? Colors.red[50]
              : Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: template.type == TransactionType.expense
                ? Colors.red.withValues(alpha:0.2)
                : Colors.green.withValues(alpha:0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  template.type == TransactionType.expense
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: template.type == TransactionType.expense
                      ? Colors.red
                      : Colors.green,
                  size: 16,
                ),
                const Spacer(),
                if (template.isAutoGenerated)
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.amber,
                    size: 12,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              template.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              template.categoryName,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              CurrencyFormatter.formatCurrency(template.amount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: template.type == TransactionType.expense
                    ? Colors.red[700]
                    : Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTemplateTapped(TransactionTemplate template) async {
    // Tăng số lần sử dụng
    await _templateService.incrementTemplateUsage(template.id);
    
    // Gọi callback
    widget.onTemplateSelected(template);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }
}

/// Extension để thêm haptic feedback
extension HapticFeedback on void {
  static void lightImpact() {
    // Implement haptic feedback nếu cần
  }
}
