import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../services/enhanced_navigation_service.dart';

/// Enhanced tab navigation with better UX and consistent design
class EnhancedTabNavigation extends StatefulWidget {
  final TabController tabController;
  final Function(int)? onTabChanged;
  final bool isCompact;

  const EnhancedTabNavigation({
    super.key,
    required this.tabController,
    this.onTabChanged,
    this.isCompact = false,
  });

  @override
  State<EnhancedTabNavigation> createState() => _EnhancedTabNavigationState();
}

class _EnhancedTabNavigationState extends State<EnhancedTabNavigation>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.tabController.index;

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    widget.tabController.addListener(_onTabControllerChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabControllerChanged);
    _rippleController.dispose();
    super.dispose();
  }

  void _onTabControllerChanged() {
    if (_selectedIndex != widget.tabController.index) {
      setState(() {
        _selectedIndex = widget.tabController.index;
      });
      _rippleController.forward().then((_) {
        _rippleController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 20 : 40,
        vertical: 0,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.isCompact ? _buildCompactTabs() : _buildFullTabs(),
    );
  }

  Widget _buildFullTabs() {
    return TabBar(
      controller: widget.tabController,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            EnhancedNavigationService.modules[_selectedIndex].color,
            EnhancedNavigationService.modules[_selectedIndex].color
                .withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: EnhancedNavigationService.modules[_selectedIndex].color
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      onTap: (index) {
        widget.onTabChanged?.call(index);
        EnhancedNavigationService().navigateToTab(index);
      },
      tabs: EnhancedNavigationService.modules.asMap().entries.map((entry) {
        final index = entry.key;
        final module = entry.value;
        final isSelected = index == _selectedIndex;

        return Tab(
          height: 40,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    module.icon,
                    size: isSelected ? 18 : 16,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      module.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactTabs() {
    return Row(
      children: EnhancedNavigationService.modules.asMap().entries.map((entry) {
        final index = entry.key;
        final module = entry.value;
        final isSelected = index == _selectedIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              widget.tabController.animateTo(index);
              widget.onTabChanged?.call(index);
              EnhancedNavigationService().navigateToTab(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          module.color,
                          module.color.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: module.color.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      module.icon,
                      size: isSelected ? 20 : 18,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    child: Text(
                      module.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Responsive tab bar that adapts to screen size
class ResponsiveTabNavigation extends StatelessWidget {
  final TabController tabController;
  final Function(int)? onTabChanged;

  const ResponsiveTabNavigation({
    super.key,
    required this.tabController,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return EnhancedTabNavigation(
          tabController: tabController,
          onTabChanged: onTabChanged,
          isCompact: isCompact,
        );
      },
    );
  }
}

/// Tab indicator with custom animation
class CustomTabIndicator extends Decoration {
  final Color color;
  final double radius;
  final EdgeInsetsGeometry insets;

  const CustomTabIndicator({
    required this.color,
    this.radius = 12.0,
    this.insets = EdgeInsets.zero,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomTabIndicatorPainter(
      color: color,
      radius: radius,
      insets: insets,
      onChanged: onChanged,
    );
  }
}

class _CustomTabIndicatorPainter extends BoxPainter {
  final Color color;
  final double radius;
  final EdgeInsetsGeometry insets;

  _CustomTabIndicatorPainter({
    required this.color,
    required this.radius,
    required this.insets,
    VoidCallback? onChanged,
  }) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final Rect indicator =
        insets.resolve(configuration.textDirection).deflateRect(rect);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(indicator, Radius.circular(radius)),
      paint,
    );
  }
}
