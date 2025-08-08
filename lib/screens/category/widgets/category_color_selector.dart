import 'package:flutter/material.dart';

class CategoryColorSelector extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final bool isEnabled;

  // Predefined colors with better selection
  static const List<Color> colorPalette = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFD700), // Gold
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF3F51B5), // Indigo
    Color(0xFFE91E63), // Pink
    Color(0xFF8BC34A), // Light Green
  ];

  const CategoryColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: colorPalette.length,
      itemBuilder: (context, index) {
        final color = colorPalette[index];
        final isSelected = color == selectedColor;
        
        return GestureDetector(
          onTap: isEnabled ? () => onColorChanged(color) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      },
    );
  }
}
