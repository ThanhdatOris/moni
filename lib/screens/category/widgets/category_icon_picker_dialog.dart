import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../utils/helpers/category_icon_helper.dart';

class CategoryIconPickerDialog extends StatefulWidget {
  final String? selectedIcon;
  final CategoryIconType selectedIconType;
  final Color selectedColor;

  const CategoryIconPickerDialog({
    super.key,
    this.selectedIcon,
    required this.selectedIconType,
    required this.selectedColor,
  });

  @override
  State<CategoryIconPickerDialog> createState() => _CategoryIconPickerDialogState();
}

class _CategoryIconPickerDialogState extends State<CategoryIconPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CategoryIconType _currentIconType = CategoryIconType.emoji;
  String? _selectedIcon;

  // Predefined emojis for categories
  final List<String> _emojis = [
    '🍕', '🛒', '🚗', '⛽', '🎬', '🧾', '🏥', '🏠', '🎓', '⚽',
    '✈️', '🏨', '🛍️', '💪', '🐕', '👶', '🎉', '☕', '🍺', '💼',
    '🎁', '📈', '💰', '🏦', '💴', '🏢', '💵', '💲', '📁', '🏷️',
    '🍔', '🍜', '🍳', '🥗', '🍎', '🍌', '🍓', '🥤', '🧃', '🍹',
    '🏋️', '🎮', '📱', '💻', '📚', '✏️', '🎨', '🎵', '📷', '🎯',
    '🚌', '🚇', '🚲', '🛴', '⛵', '🏊', '🎿', '🧗', '🏃', '🚶',
    '👕', '👖', '👗', '👠', '👜', '💍', '⌚', '🕶️', '🧢', '🧤',
    '🏪', '🏬', '🎪', '🎭', '🎨', '🎼', '🎤', '🎸', '🎹', '🥁',
    '💊', '🩺', '🧴', '🧼', '🧽', '🧹', '🔧', '🔨', '⚡', '🔥',
    '🌟', '⭐', '💫', '🌙', '☀️', '🌈', '🍀', '🌺', '🌸', '🌼'
  ];

  // Material icons for categories
  final List<Map<String, String>> _materialIcons = [
    {'name': 'restaurant', 'label': 'Ăn uống'},
    {'name': 'shopping_cart', 'label': 'Mua sắm'},
    {'name': 'directions_car', 'label': 'Xe cộ'},
    {'name': 'local_gas_station', 'label': 'Xăng dầu'},
    {'name': 'movie', 'label': 'Giải trí'},
    {'name': 'receipt', 'label': 'Hóa đơn'},
    {'name': 'local_hospital', 'label': 'Y tế'},
    {'name': 'home', 'label': 'Nhà ở'},
    {'name': 'school', 'label': 'Giáo dục'},
    {'name': 'sports_soccer', 'label': 'Thể thao'},
    {'name': 'flight', 'label': 'Du lịch'},
    {'name': 'hotel', 'label': 'Khách sạn'},
    {'name': 'shopping_bag', 'label': 'Thời trang'},
    {'name': 'fitness_center', 'label': 'Gym'},
    {'name': 'pets', 'label': 'Thú cưng'},
    {'name': 'child_friendly', 'label': 'Trẻ em'},
    {'name': 'celebration', 'label': 'Lễ hội'},
    {'name': 'local_cafe', 'label': 'Cafe'},
    {'name': 'local_bar', 'label': 'Đồ uống'},
    {'name': 'work', 'label': 'Công việc'},
    {'name': 'card_giftcard', 'label': 'Quà tặng'},
    {'name': 'trending_up', 'label': 'Đầu tư'},
    {'name': 'attach_money', 'label': 'Tiền'},
    {'name': 'account_balance', 'label': 'Ngân hàng'},
    {'name': 'savings', 'label': 'Tiết kiệm'},
    {'name': 'business', 'label': 'Doanh nghiệp'},
    {'name': 'payment', 'label': 'Thanh toán'},
    {'name': 'monetization_on', 'label': 'Thu nhập'},
    {'name': 'folder', 'label': 'Thư mục'},
    {'name': 'local_offer', 'label': 'Ưu đãi'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentIconType = widget.selectedIconType;
    _selectedIcon = widget.selectedIcon;
    
    // Set initial tab based on icon type
    if (_currentIconType == CategoryIconType.material) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEmojiKeyboard() async {
    final TextEditingController controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập emoji'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập hoặc dán emoji từ bàn phím...',
            border: OutlineInputBorder(),
          ),
          maxLength: 2, // Limit to emoji length
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context, text);
              }
            },
            child: const Text('Chọn'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedIcon = result;
        _currentIconType = CategoryIconType.emoji;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn biểu tượng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tab Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  setState(() {
                    _currentIconType = index == 0 
                        ? CategoryIconType.emoji 
                        : CategoryIconType.material;
                    _selectedIcon = null; // Reset selection when switching
                  });
                },
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(
                    height: 20,
                    text: 'Emoji',
                  ),
                  Tab(
                    height: 20,
                    text: 'Material',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmojiGrid(),
                  _buildMaterialIconGrid(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedIcon != null
                      ? () => Navigator.pop(context, {
                            'icon': _selectedIcon,
                            'iconType': _currentIconType,
                          })
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Chọn'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiGrid() {
    return Column(
      children: [
        // Emoji from keyboard button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            onPressed: _showEmojiKeyboard,
            icon: const Icon(Icons.keyboard),
            label: const Text('Chọn từ bàn phím'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundLight,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        // Predefined emojis grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _emojis.length,
            itemBuilder: (context, index) {
              final emoji = _emojis[index];
              final isSelected = _selectedIcon == emoji && _currentIconType == CategoryIconType.emoji;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = emoji;
                    _currentIconType = CategoryIconType.emoji;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? widget.selectedColor.withValues(alpha: 0.2)
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? widget.selectedColor 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialIconGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _materialIcons.length,
      itemBuilder: (context, index) {
        final iconData = _materialIcons[index];
        final iconName = iconData['name']!;
        final isSelected = _selectedIcon == iconName && _currentIconType == CategoryIconType.material;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIcon = iconName;
              _currentIconType = CategoryIconType.material;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? widget.selectedColor.withValues(alpha: 0.2)
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? widget.selectedColor 
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CategoryIconHelper.getIconData(iconName),
                  color: widget.selectedColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  iconData['label']!,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
