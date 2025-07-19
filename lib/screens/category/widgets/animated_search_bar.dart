import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String searchQuery;
  final double swipeOffset;
  final bool isAnimating;

  const AnimatedSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.searchQuery,
    this.swipeOffset = 0.0,
    this.isAnimating = false,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _focusAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: AppColors.backgroundLight,
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

  void _onFocusChanged(bool focused) {
    setState(() {
      _isFocused = focused;
    });
    if (focused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _focusAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: _isFocused ? 2 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
                // Enhanced shadow during focus
                if (_isFocused)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                // Swipe effect shadow
                if (widget.swipeOffset.abs() > 10)
                  BoxShadow(
                    color: AppColors.primary.withValues(
                        alpha: 0.08 * (widget.swipeOffset.abs() / 100).clamp(0.0, 1.0)),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.search,
                    color: _isFocused 
                        ? AppColors.primary 
                        : AppColors.textSecondary,
                    size: 20 + (widget.swipeOffset.abs() > 30 ? 1 : 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Focus(
                    onFocusChange: _onFocusChanged,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.isAnimating ? 0.7 : 1.0,
                      child: TextField(
                        controller: widget.controller,
                        onChanged: widget.onChanged,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm danh mục...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.searchQuery.isNotEmpty)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: GestureDetector(
                          onTap: () {
                            widget.controller.clear();
                            widget.onChanged('');
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
