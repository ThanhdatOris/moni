import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A widget that displays financial overview cards with a glassmorphism effect.
class FinancialOverviewCards extends StatelessWidget {
  const FinancialOverviewCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                title: 'Tổng thu',
                amount: '15.000.000đ',
                icon: Icons.arrow_upward_rounded,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFinancialCard(
                title: 'Tổng chi',
                amount: '8.500.000đ',
                icon: Icons.arrow_downward_rounded,
                iconColor: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFinancialCard(
          title: 'Số dư khả dụng',
          amount: '6.500.000đ',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.info,
          isFullWidth: true,
        ),
      ],
    );
  }

  /// Builds a single card with a transparent, glass-like design.
  Widget _buildFinancialCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4), // Semi-transparent background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isFullWidth
          ? Row(
              children: [
                _buildIcon(icon, iconColor),
                const SizedBox(width: 16),
                _buildText(title, amount, iconColor),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(icon, iconColor),
                const SizedBox(height: 12),
                _buildText(title, amount, iconColor),
              ],
            ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildText(String title, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          amount,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
