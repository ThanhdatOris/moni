import 'package:flutter/material.dart';
import 'package:moni/config/app_config.dart';

/// Base card component for assistant modules
/// Provides consistent styling and behavior across all assistant cards
class AssistantBaseCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isLoading;
  final bool hasError;
  final double? height;
  final Gradient? gradient;

  const AssistantBaseCard({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.onTap,
    this.padding,
    this.margin,
    this.isLoading = false,
    this.hasError = false,
    this.height,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Height is optional; card shrink-wraps content by default
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient ?? _getDefaultGradient(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: hasError
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: hasError
            ? Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // We intentionally shrink-wrap content instead of forcing flex under unbounded constraints
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      _buildHeader(),
                      const SizedBox(height: 16),
                    ],
                    _buildContent(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (titleIcon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              titleIcon!,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withValues(alpha: 0.8),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return child;
  }

  Gradient _getDefaultGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary,
        AppColors.primaryDark,
      ],
    );
  }
}
