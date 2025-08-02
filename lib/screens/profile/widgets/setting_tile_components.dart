/// Setting Tile Components - Helper widgets cho các loại setting tiles
/// Được tách từ ProfileScreen để cải thiện maintainability và reusability

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Base setting tile widget
class SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isEnabled;

  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: isEnabled ? Colors.black87 : AppColors.textSecondary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Switch setting tile
class SettingSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isEnabled;

  const SettingSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: title,
      subtitle: subtitle,
      isEnabled: isEnabled,
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch(
          value: value,
          onChanged: isEnabled ? onChanged : null,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: AppColors.grey400,
          inactiveTrackColor: AppColors.grey200,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      onTap: isEnabled ? () => onChanged(!value) : null,
    );
  }
}

/// Action setting tile with button
class SettingActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isEnabled;
  final Color? buttonColor;
  final IconData? buttonIcon;

  const SettingActionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.buttonText,
    required this.onPressed,
    this.isEnabled = true,
    this.buttonColor,
    this.buttonIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: title,
      subtitle: subtitle,
      isEnabled: isEnabled,
      trailing: _buildActionButton(),
    );
  }

  Widget _buildActionButton() {
    final color = buttonColor ?? AppColors.primary;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (buttonIcon != null) ...[
              Icon(buttonIcon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown setting tile
class SettingDropdownTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String currentValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool isEnabled;

  const SettingDropdownTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.currentValue,
    required this.options,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: title,
      subtitle: subtitle,
      isEnabled: isEnabled,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.grey100, // Changed from grey50
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: currentValue,
          underline: Container(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          items: options.map((value) => DropdownMenuItem(
            value: value,
            child: Text(value),
          )).toList(),
          onChanged: isEnabled ? onChanged : null,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isEnabled ? AppColors.textSecondary : AppColors.grey400,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Info setting tile (read-only)
class SettingInfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const SettingInfoTile({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation setting tile with arrow
class SettingNavigationTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final Widget? badge;

  const SettingNavigationTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.isEnabled = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: title,
      subtitle: subtitle,
      isEnabled: isEnabled,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            badge!,
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.chevron_right,
            color: isEnabled ? AppColors.textSecondary : AppColors.grey400,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Progress setting tile
class SettingProgressTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double progress; // 0.0 to 1.0
  final String? progressText;
  final Color? progressColor;

  const SettingProgressTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.progress,
    this.progressText,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: title,
      subtitle: subtitle,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progressText != null)
            Text(
              progressText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: progressColor ?? AppColors.primary,
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? AppColors.primary,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Setting section container
class SettingSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isFirst;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback? onExpansionChanged;

  const SettingSection({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.isExpanded = false,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: isLast 
            ? BorderSide.none 
            : const BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primaryDark.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textSecondary,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          childrenPadding: EdgeInsets.zero,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onExpansionChanged: onExpansionChanged != null 
            ? (expanded) => onExpansionChanged!() 
            : null,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.grey100, // Changed from grey50
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading setting tile
class SettingLoadingTile extends StatelessWidget {
  final bool hasSubtitle;

  const SettingLoadingTile({
    super.key,
    this.hasSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 15,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
} 