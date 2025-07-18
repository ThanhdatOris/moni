import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/category_icon_helper.dart';

class CategoryIconPicker extends StatefulWidget {
  final String? currentIcon;
  final CategoryIconType currentIconType;
  final TransactionType transactionType;
  final Color categoryColor;
  final Function(String icon, CategoryIconType iconType) onIconSelected;

  const CategoryIconPicker({
    super.key,
    this.currentIcon,
    this.currentIconType = CategoryIconType.material,
    required this.transactionType,
    this.categoryColor = const Color(0xFF607D8B),
    required this.onIconSelected,
  });

  @override
  State<CategoryIconPicker> createState() => _CategoryIconPickerState();
}

class _CategoryIconPickerState extends State<CategoryIconPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedIcon;
  CategoryIconType _selectedIconType = CategoryIconType.material;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedIcon = widget.currentIcon;
    _selectedIconType = widget.currentIconType;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMaterialIconsTab(),
                _buildEmojiPickerTab(),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Text(
                'Chọn biểu tượng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),

              // Preview
              if (_selectedIcon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.categoryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: CategoryIconHelper.buildIconPreview(
                    _selectedIcon!,
                    _selectedIconType,
                    size: 24,
                    isSelected: true,
                    categoryColor: widget.categoryColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.apps, size: 20),
            text: 'Material Icons',
          ),
          Tab(
            icon: Icon(Icons.emoji_emotions, size: 20),
            text: 'Emoji',
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialIconsTab() {
    final icons = widget.transactionType == TransactionType.expense
        ? CategoryIconHelper.getPopularExpenseIcons()
        : CategoryIconHelper.getPopularIncomeIcons();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final iconName = icons[index];
          final isSelected = _selectedIcon == iconName &&
              _selectedIconType == CategoryIconType.material;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIcon = iconName;
                _selectedIconType = CategoryIconType.material;
              });
            },
            child: CategoryIconHelper.buildIconPreview(
              iconName,
              CategoryIconType.material,
              size: 28,
              isSelected: isSelected,
              categoryColor: widget.categoryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmojiPickerTab() {
    return EmojiPicker(
      onEmojiSelected: (Category? category, Emoji emoji) {
        setState(() {
          _selectedIcon = emoji.emoji;
          _selectedIconType = CategoryIconType.emoji;
        });
      },
      config: Config(
        height: double.infinity,
        checkPlatformCompatibility: true,
        emojiViewConfig: EmojiViewConfig(
          emojiSizeMax: 28,
          backgroundColor: Colors.white,
          columns: 8,
          verticalSpacing: 8,
          horizontalSpacing: 8,
          recentsLimit: 20,
          buttonMode: ButtonMode.MATERIAL,
        ),
        categoryViewConfig: CategoryViewConfig(
          backgroundColor: Colors.grey[100]!,
          iconColor: AppColors.textSecondary,
          iconColorSelected: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabBarHeight: 46,
          initCategory: widget.transactionType == TransactionType.expense
              ? Category.ACTIVITIES
              : Category.OBJECTS,
        ),
        bottomActionBarConfig: const BottomActionBarConfig(
          enabled: false,
        ),
        searchViewConfig: const SearchViewConfig(
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Confirm button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedIcon != null
                  ? () {
                      widget.onIconSelected(_selectedIcon!, _selectedIconType);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Chọn biểu tượng',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper method để show icon picker
class CategoryIconPickerHelper {
  static Future<Map<String, dynamic>?> showIconPicker({
    required BuildContext context,
    String? currentIcon,
    CategoryIconType currentIconType = CategoryIconType.material,
    required TransactionType transactionType,
    Color categoryColor = const Color(0xFF607D8B),
  }) async {
    String? selectedIcon;
    CategoryIconType? selectedIconType;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CategoryIconPicker(
          currentIcon: currentIcon,
          currentIconType: currentIconType,
          transactionType: transactionType,
          categoryColor: categoryColor,
          onIconSelected: (icon, iconType) {
            selectedIcon = icon;
            selectedIconType = iconType;
          },
        );
      },
    );

    if (selectedIcon != null && selectedIconType != null) {
      return {
        'icon': selectedIcon,
        'iconType': selectedIconType,
      };
    }

    return null;
  }
}
