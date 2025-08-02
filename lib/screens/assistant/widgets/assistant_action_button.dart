import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Action button component for assistant modules
/// Provides consistent button styling across assistant features
class AssistantActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final ButtonType type;

  const AssistantActionButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.type = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _getButtonDecoration(),
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(0, 48),
        ),
        child: isLoading ? _buildLoadingContent() : _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon!,
            color: _getTextColor(),
            size: 18,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: _getTextColor(),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
      ),
    );
  }

  BoxDecoration _getButtonDecoration() {
    switch (type) {
      case ButtonType.primary:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? AppColors.primary,
              (backgroundColor ?? AppColors.primary).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : null,
        );
      case ButtonType.secondary:
        return BoxDecoration(
          color: backgroundColor ?? AppColors.grey100,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.grey300,
            width: 1,
          ),
        );
      case ButtonType.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: backgroundColor ?? AppColors.primary,
            width: 2,
          ),
        );
    }
  }

  Color _getTextColor() {
    if (!isEnabled) return AppColors.grey400;
    
    switch (type) {
      case ButtonType.primary:
        return textColor ?? Colors.white;
      case ButtonType.secondary:
        return textColor ?? AppColors.textPrimary;
      case ButtonType.outline:
        return textColor ?? (backgroundColor ?? AppColors.primary);
    }
  }
}

/// Quick action chip for small actions
class AssistantQuickActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isSelected;
  final Color? selectedColor;

  const AssistantQuickActionChip({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isSelected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;
    
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected ? LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ) : null,
        color: isSelected ? null : AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : AppColors.grey300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon!,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ButtonType { primary, secondary, outline }
