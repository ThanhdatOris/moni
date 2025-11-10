import 'package:flutter/material.dart';

import 'package:moni/config/app_config.dart';

class CategoryTransactionTypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;
  final bool isEnabled;

  const CategoryTransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              'Chi tiêu',
              TransactionType.expense,
              Icons.trending_down,
              AppColors.error,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              'Thu nhập',
              TransactionType.income,
              Icons.trending_up,
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String title,
    TransactionType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedType == type;
    
    return GestureDetector(
      onTap: isEnabled ? () => onTypeChanged(type) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
