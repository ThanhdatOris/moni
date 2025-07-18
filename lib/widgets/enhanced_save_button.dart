import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Enhanced save button với animations và loading states
class EnhancedSaveButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onSave;
  final String? label;
  final IconData? icon;
  final bool showProgress;
  final double progress;

  const EnhancedSaveButton({
    super.key,
    required this.isLoading,
    this.onSave,
    this.label,
    this.icon,
    this.showProgress = false,
    this.progress = 0.0,
  });

  @override
  State<EnhancedSaveButton> createState() => _EnhancedSaveButtonState();
}

class _EnhancedSaveButtonState extends State<EnhancedSaveButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedSaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _rotationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.isLoading) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.isLoading
                ? Colors.grey.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.isLoading
                    ? LinearGradient(
                        colors: [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Progress bar background
                  if (widget.showProgress)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  
                  // Progress bar
                  if (widget.showProgress)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: MediaQuery.of(context).size.width * widget.progress,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  
                  // Button content
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.isLoading ? null : widget.onSave,
                      onTapDown: _onTapDown,
                      onTapUp: _onTapUp,
                      onTapCancel: _onTapCancel,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        child: widget.isLoading
                            ? _buildLoadingContent()
                            : _buildNormalContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          'Đang lưu...',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNormalContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label ?? 'Lưu giao dịch',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
