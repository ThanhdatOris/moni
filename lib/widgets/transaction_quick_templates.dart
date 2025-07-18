import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/transaction_model.dart';

class TransactionQuickTemplates extends StatelessWidget {
  final TransactionType transactionType;
  final Function(Map<String, dynamic>) onTemplateSelected;

  const TransactionQuickTemplates({
    super.key,
    required this.transactionType,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final templates = _getTemplatesForType();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Icon(
                Icons.flash_on,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Mẫu nhanh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transactionType == TransactionType.expense
                      ? 'Chi tiêu'
                      : 'Thu nhập',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (templates.isEmpty)
            _buildEmptyState()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: templates
                  .map((template) => _buildCompactTemplateChip(template))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chưa có mẫu nhanh nào',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTemplateChip(Map<String, dynamic> template) {
    return GestureDetector(
      onTap: () => onTemplateSelected(template),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              template['icon'],
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              template['name'],
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (template['amount'] != null) ...[
              const SizedBox(width: 4),
              Text(
                _formatAmount(template['amount']),
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getTemplatesForType() {
    if (transactionType == TransactionType.expense) {
      return [
        {
          'name': 'Ăn sáng',
          'amount': '30000',
          'icon': Icons.free_breakfast,
          'note': 'Ăn sáng',
        },
        {
          'name': 'Cà phê',
          'amount': '25000',
          'icon': Icons.local_cafe,
          'note': 'Cà phê',
        },
        {
          'name': 'Cơm trưa',
          'amount': '50000',
          'icon': Icons.restaurant,
          'note': 'Cơm trưa',
        },
        {
          'name': 'Xăng xe',
          'amount': '100000',
          'icon': Icons.local_gas_station,
          'note': 'Đổ xăng',
        },
        {
          'name': 'Grab',
          'amount': '50000',
          'icon': Icons.directions_car,
          'note': 'Di chuyển',
        },
        {
          'name': 'Mua sắm',
          'amount': '200000',
          'icon': Icons.shopping_bag,
          'note': 'Mua sắm',
        },
      ];
    } else {
      return [
        {
          'name': 'Lương',
          'amount': '15000000',
          'icon': Icons.work,
          'note': 'Lương tháng',
        },
        {
          'name': 'Thưởng',
          'amount': '2000000',
          'icon': Icons.card_giftcard,
          'note': 'Thưởng',
        },
        {
          'name': 'Bán hàng',
          'amount': '500000',
          'icon': Icons.store,
          'note': 'Thu nhập từ bán hàng',
        },
        {
          'name': 'Đầu tư',
          'amount': '1000000',
          'icon': Icons.trending_up,
          'note': 'Lợi nhuận đầu tư',
        },
        {
          'name': 'Freelance',
          'amount': '3000000',
          'icon': Icons.laptop,
          'note': 'Thu nhập freelance',
        },
      ];
    }
  }

  String _formatAmount(String amount) {
    final number = int.tryParse(amount) ?? 0;
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
