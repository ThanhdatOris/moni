import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/category_service.dart';
import '../../utils/helpers/category_icon_helper.dart';

class AddEditCategoryV2Screen extends StatefulWidget {
  final CategoryModel? category;
  final TransactionType transactionType;

  const AddEditCategoryV2Screen({
    super.key,
    this.category,
    required this.transactionType,
  });

  @override
  State<AddEditCategoryV2Screen> createState() => _AddEditCategoryV2ScreenState();
}

class _AddEditCategoryV2ScreenState extends State<AddEditCategoryV2Screen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final CategoryService _categoryService;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form data
  String? _selectedIcon;
  CategoryIconType _selectedIconType = CategoryIconType.emoji;
  Color _selectedColor = const Color(0xFF2196F3);
  CategoryModel? _selectedParent;
  List<CategoryModel> _availableParents = [];
  
  // UI state
  bool _isLoading = false;
  bool _isLoadingParents = false;
  bool _showParentSelector = false;

  // Predefined colors with better selection
  final List<Color> _colorPalette = [
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFFF44336), // Red
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFFFD700), // Gold
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFFE91E63), // Pink
    const Color(0xFF8BC34A), // Light Green
  ];

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _categoryService = GetIt.instance<CategoryService>();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _initializeData();
    _loadAvailableParents();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeData() {
    if (isEditing) {
      final category = widget.category!;
      _nameController.text = category.name;
      _selectedIcon = category.icon;
      _selectedIconType = category.iconType;
      _selectedColor = Color(category.color);
      _showParentSelector = category.parentId != null;
    } else {
      // Set smart defaults based on transaction type
      if (widget.transactionType == TransactionType.expense) {
        _selectedIcon = '🛒';
        _selectedColor = const Color(0xFFFF9800); // Orange
      } else {
        _selectedIcon = '💰';
        _selectedColor = const Color(0xFF4CAF50); // Green
      }
    }
  }

  Future<void> _loadAvailableParents() async {
    setState(() => _isLoadingParents = true);

    try {
      final categories = await _categoryService
          .getCategories(type: widget.transactionType)
          .first;

      final parents = categories
          .where((c) => c.isParentCategory && 
                       (!isEditing || c.categoryId != widget.category!.categoryId))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _availableParents = parents;
        
        // Set selected parent if editing
        if (isEditing && widget.category!.parentId != null) {
          _selectedParent = parents
              .where((p) => p.categoryId == widget.category!.parentId)
              .firstOrNull;
        }
        
        _isLoadingParents = false;
      });
    } catch (e) {
      setState(() => _isLoadingParents = false);
      _showError('Lỗi tải danh sách danh mục: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.grey100,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Sửa danh mục' : 'Thêm danh mục mới',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.transactionType == TransactionType.expense 
                      ? 'Danh mục chi tiêu' 
                      : 'Danh mục thu nhập',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPreviewCard(),
          const SizedBox(height: 20),
          _buildNameSection(),
          const SizedBox(height: 20),
          _buildIconSection(),
          const SizedBox(height: 20),
          _buildColorSection(),
          const SizedBox(height: 20),
          _buildParentSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedColor.withValues(alpha: 0.1),
            _selectedColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _selectedIcon != null
                ? _buildIconWidget(_selectedIcon!, _selectedIconType)
                : Icon(
                    Icons.category_rounded,
                    color: _selectedColor,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty 
                      ? 'Tên danh mục...' 
                      : _nameController.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _nameController.text.isEmpty 
                        ? AppColors.grey400 
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_selectedParent != null) ...[
                      Text(
                        'Thuộc: ${_selectedParent!.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Danh mục độc lập',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return _buildSection(
      title: 'Tên danh mục',
      icon: Icons.label_outline,
      child: TextFormField(
        controller: _nameController,
        enabled: !(isEditing && widget.category!.isDefault),
        decoration: InputDecoration(
          hintText: 'Nhập tên danh mục...',
          prefixIcon: Icon(Icons.edit_outlined, color: AppColors.grey600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.grey200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _selectedColor, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.grey300),
          ),
          filled: true,
          fillColor: (isEditing && widget.category!.isDefault) 
              ? AppColors.grey100 
              : Colors.white,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập tên danh mục';
          }
          if (value.trim().length < 2) {
            return 'Tên danh mục phải có ít nhất 2 ký tự';
          }
          return null;
        },
        onChanged: (value) => setState(() {}), // Update preview
      ),
    );
  }

  Widget _buildIconSection() {
    final isDefaultCategory = isEditing && widget.category!.isDefault;
    
    return _buildSection(
      title: 'Biểu tượng',
      icon: Icons.emoji_emotions_outlined,
      child: GestureDetector(
        onTap: isDefaultCategory ? null : _showIconPicker,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDefaultCategory ? AppColors.grey100 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedIcon != null
                    ? _buildIconWidget(_selectedIcon!, _selectedIconType)
                    : Icon(Icons.add, color: _selectedColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedIcon != null ? 'Biểu tượng đã chọn' : 'Chọn biểu tượng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDefaultCategory ? AppColors.grey600 : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Nhấn để thay đổi',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    final isDefaultCategory = isEditing && widget.category!.isDefault;
    
    return _buildSection(
      title: 'Màu sắc',
      icon: Icons.palette_outlined,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _colorPalette.length,
        itemBuilder: (context, index) {
          final color = _colorPalette[index];
          final isSelected = color.value == _selectedColor.value;
          
          return GestureDetector(
            onTap: isDefaultCategory ? null : () => setState(() {
              _selectedColor = color;
            }),
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
      ),
    );
  }

  Widget _buildParentSection() {
    return _buildSection(
      title: 'Danh mục cha',
      icon: Icons.folder_outlined,
      child: Column(
        children: [
          // Toggle switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Có danh mục cha',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tạo phân cấp cho danh mục',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showParentSelector,
                  onChanged: (value) async {
                    setState(() {
                      _showParentSelector = value;
                      if (!value) {
                        _selectedParent = null;
                      }
                    });
                    
                    // Load parents when toggled on
                    if (value && _availableParents.isEmpty) {
                      await _loadAvailableParents();
                    }
                  },
                  activeColor: _selectedColor,
                ),
              ],
            ),
          ),
          
          // Parent selector
          if (_showParentSelector) ...[
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: _buildParentDropdown(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParentDropdown() {
    if (_isLoadingParents) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return DropdownButtonFormField<CategoryModel>(
      value: _selectedParent,
      decoration: InputDecoration(
        hintText: 'Chọn danh mục cha...',
        prefixIcon: Icon(Icons.folder_outlined, color: AppColors.grey600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _selectedColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _availableParents.map((parent) {
        return DropdownMenuItem<CategoryModel>(
          value: parent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryIconHelper.buildIcon(
                parent,
                size: 20,
                color: Color(parent.color),
                showBackground: true,
                isCompact: true,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  parent.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedParent = value),
      dropdownColor: Colors.white,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: _selectedColor.withValues(alpha: 0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isEditing ? 'Cập nhật danh mục' : 'Tạo danh mục',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: _selectedColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  void _showIconPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _IconPickerDialog(
        selectedIcon: _selectedIcon,
        selectedIconType: _selectedIconType,
        selectedColor: _selectedColor,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedIcon = result['icon'];
        _selectedIconType = result['iconType'];
      });
    }
  }

  Future<void> _saveCategory() async {
    // Prevent editing default categories
    if (isEditing && widget.category!.isDefault) {
      _showError('Không thể chỉnh sửa danh mục mặc định');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedIcon == null) {
      _showError('Vui lòng chọn biểu tượng');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      if (isEditing) {
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          iconType: _selectedIconType,
          color: _selectedColor.value,
          parentId: _selectedParent?.categoryId,
          updatedAt: now,
        );

        await _categoryService.updateCategory(updatedCategory);
      } else {
        final newCategory = CategoryModel(
          categoryId: '',
          userId: '',
          name: _nameController.text.trim(),
          type: widget.transactionType,
          icon: _selectedIcon!,
          iconType: _selectedIconType,
          color: _selectedColor.value,
          parentId: _selectedParent?.categoryId,
          createdAt: now,
          updatedAt: now,
        );

        await _categoryService.createCategory(newCategory);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing 
                  ? '✅ Cập nhật danh mục thành công!' 
                  : '✅ Tạo danh mục thành công!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError(
        isEditing ? 'Lỗi cập nhật danh mục: $e' : 'Lỗi tạo danh mục: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildIconWidget(String icon, CategoryIconType iconType) {
    switch (iconType) {
      case CategoryIconType.emoji:
        return Text(
          icon,
          style: const TextStyle(fontSize: 24),
        );
      case CategoryIconType.material:
        return Icon(
          CategoryIconHelper.getIconData(icon),
          color: _selectedColor,
          size: 24,
        );
      case CategoryIconType.custom:
        // For now, show material icon as fallback
        return Icon(
          CategoryIconHelper.getIconData('category'),
          color: _selectedColor,
          size: 24,
        );
    }
  }
}

class _IconPickerDialog extends StatefulWidget {
  final String? selectedIcon;
  final CategoryIconType selectedIconType;
  final Color selectedColor;

  const _IconPickerDialog({
    this.selectedIcon,
    required this.selectedIconType,
    required this.selectedColor,
  });

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog>
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
                  icon: Icon(Icons.close),
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
            icon: Icon(Icons.keyboard),
            label: Text('Chọn từ bàn phím'),
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
