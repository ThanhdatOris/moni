import 'dart:math' as math;

import 'package:flutter/material.dart';

class TypingDots extends StatefulWidget {
  final Color color;
  final double size;

  const TypingDots({
    super.key,
    this.color = const Color(0xFF6B7280),
    this.size = 6.0,
  });

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 5, // space for 3 dots + padding
      height: widget.size * 2,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double t = (_controller.value + index * 0.2) % 1.0;
                // Simple sine wave for opacity or offset using dart:math
                final double sineValue = math.sin(t * 2 * math.pi);

                final double opacity = (0.4 + 0.6 * (0.5 * (1 + sineValue)))
                    .clamp(0.2, 1.0); // Ensure min opacity is visible

                final double scale = 1.0 - 0.3 * (0.5 * (1 + sineValue));

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: widget.size / 3),
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                  transform: Matrix4.diagonal3Values(scale, scale, 1.0),
                  transformAlignment: Alignment.center,
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
