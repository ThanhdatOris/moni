import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/transaction_model.dart';

class AnimatedTypeSelector extends StatefulWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;
  final double swipeOffset;
  final bool isAnimating;

  const AnimatedTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.swipeOffset = 0.0,
    this.isAnimating = false,
  });

  @override
  State<AnimatedTypeSelector> createState() => _AnimatedTypeSelectorState();
}

class _AnimatedTypeSelectorState extends State<AnimatedTypeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_scaleAnimation.value * 0.01),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'Chi tiêu',
                    TransactionType.expense,
                    Icons.remove_circle_outline,
                    AppColors.expense,
                  ),
                ),
                Expanded(
                  child: _buildTypeButton(
                    'Thu nhập',
                    TransactionType.income,
                    Icons.add_circle_outline,
                    AppColors.income,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeButton(
    String title,
    TransactionType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = widget.selectedType == type;
    
    // Calculate scale based on swipe direction
    double scale = 1.0;
    if (widget.swipeOffset != 0.0) {
      if (type == TransactionType.expense && widget.swipeOffset > 0) {
        scale = 1.0 + (widget.swipeOffset / 200);
      } else if (type == TransactionType.income && widget.swipeOffset < 0) {
        scale = 1.0 + (widget.swipeOffset.abs() / 200);
      } else if (isSelected) {
        scale = 1.0 - (widget.swipeOffset.abs() / 400);
      }
      scale = scale.clamp(0.9, 1.1);
    }

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: () => widget.onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
