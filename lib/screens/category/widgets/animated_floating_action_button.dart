import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class AnimatedFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double swipeOffset;
  final bool isAnimating;

  const AnimatedFloatingActionButton({
    super.key,
    required this.onPressed,
    this.swipeOffset = 0.0,
    this.isAnimating = false,
  });

  @override
  State<AnimatedFloatingActionButton> createState() => _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double swipeScale = 1.0;
        if (widget.swipeOffset.abs() > 30) {
          swipeScale = 1.0 + (widget.swipeOffset.abs() / 500).clamp(0.0, 0.1);
        }

        return Transform.scale(
          scale: _scaleAnimation.value * swipeScale,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 3.14159,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.isAnimating ? 0.8 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                    // Enhanced shadow during swipe
                    if (widget.swipeOffset.abs() > 20)
                      BoxShadow(
                        color: AppColors.primary.withValues(
                            alpha: 0.4 * (widget.swipeOffset.abs() / 100).clamp(0.0, 1.0)),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: widget.onPressed,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  highlightElevation: 0,
                  focusElevation: 0,
                  hoverElevation: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28 + (widget.swipeOffset.abs() > 40 ? 2 : 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(AnimatedFloatingActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.swipeOffset.abs() > 40 && oldWidget.swipeOffset.abs() <= 40) {
      _animationController.forward();
    } else if (widget.swipeOffset.abs() <= 40 && oldWidget.swipeOffset.abs() > 40) {
      _animationController.reverse();
    }
  }
}
