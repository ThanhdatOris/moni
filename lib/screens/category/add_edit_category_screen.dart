import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:moni/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/providers/providers.dart';
import 'package:moni/services/services.dart';
import '../../utils/helpers/category_icon_helper.dart';
import 'widgets/category_color_selector.dart';
import 'widgets/category_icon_picker_dialog.dart';
import 'widgets/category_parent_selector.dart';
import 'widgets/category_preview_card.dart';
import 'widgets/category_transaction_type_selector.dart';

class AddEditCategoryV2Screen extends ConsumerStatefulWidget {
  final CategoryModel? category;
  final TransactionType? initialTransactionType;

  const AddEditCategoryV2Screen({
    super.key,
    this.category,
    this.initialTransactionType,
  });

  @override
  ConsumerState<AddEditCategoryV2Screen> createState() => _AddEditCategoryV2ScreenState();
}

class _AddEditCategoryV2ScreenState extends ConsumerState<AddEditCategoryV2Screen>
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
  TransactionType _selectedTransactionType = TransactionType.expense;
  
  // UI state
  bool _isLoading = false;
  bool _showParentSelector = false;

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
      _selectedTransactionType = category.type;
      _showParentSelector = category.parentId != null;
    } else {
      // Use initial transaction type or default to expense
      _selectedTransactionType = widget.initialTransactionType ?? TransactionType.expense;
      
      // Set smart defaults based on transaction type
      if (_selectedTransactionType == TransactionType.expense) {
        _selectedIcon = '🛒';
        _selectedColor = const Color(0xFFFF9800); // Orange
      } else {
        _selectedIcon = '💰';
        _selectedColor = const Color(0xFF4CAF50); // Green
      }
    }
  }

  List<CategoryModel> _getAvailableParents() {
    final categoriesAsync = ref.read(allCategoriesProvider);
    if (!categoriesAsync.hasValue) return [];
    
    final allCategories = categoriesAsync.value!;
    final parents = allCategories
        .where((c) => 
            !c.isDeleted &&
            c.type == _selectedTransactionType &&
            (c.parentId == null || c.parentId!.isEmpty) &&
            (!isEditing || c.categoryId != widget.category!.categoryId))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    
    // Set selected parent if editing
    if (isEditing && widget.category!.parentId != null && _selectedParent == null) {
      _selectedParent = parents
          .where((p) => p.categoryId == widget.category!.parentId)
          .firstOrNull;
    }
    
    return parents;
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
                  _selectedTransactionType == TransactionType.expense 
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
          _buildTransactionTypeSection(),
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
    return CategoryPreviewCard(
      selectedIcon: _selectedIcon,
      selectedIconType: _selectedIconType,
      selectedColor: _selectedColor,
      categoryName: _nameController.text,
      selectedParent: _selectedParent,
    );
  }

  Widget _buildTransactionTypeSection() {
    // Don't show type selector when editing existing category
    if (isEditing) return const SizedBox.shrink();
    
    return _buildSection(
      title: 'Loại giao dịch',
      icon: Icons.swap_horiz,
      child: CategoryTransactionTypeSelector(
        selectedType: _selectedTransactionType,
        onTypeChanged: (type) {
          setState(() {
            _selectedTransactionType = type;
            // Update icon and color defaults when type changes
            if (type == TransactionType.expense) {
              _selectedIcon = '🛒';
              _selectedColor = const Color(0xFFFF9800); // Orange
            } else {
              _selectedIcon = '💰';
              _selectedColor = const Color(0xFF4CAF50); // Green
            }
            // Reset parent selection since different types have different parents
            _selectedParent = null;
            _showParentSelector = false;
          });
        },
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
      child: CategoryColorSelector(
        selectedColor: _selectedColor,
        onColorChanged: (color) => setState(() => _selectedColor = color),
        isEnabled: !isDefaultCategory,
      ),
    );
  }

  Widget _buildParentSection() {
    // Watch parent categories provider
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final availableParents = _getAvailableParents();
    final isLoadingParents = categoriesAsync.isLoading;
    
    return _buildSection(
      title: 'Danh mục cha',
      icon: Icons.folder_outlined,
      child: CategoryParentSelector(
        showParentSelector: _showParentSelector,
        selectedParent: _selectedParent,
        availableParents: availableParents,
        isLoadingParents: isLoadingParents,
        selectedColor: _selectedColor,
        onToggleParentSelector: (value) {
          setState(() {
            _showParentSelector = value;
            if (!value) {
              _selectedParent = null;
            }
          });
        },
        onParentChanged: (value) => setState(() => _selectedParent = value),
      ),
    );
  }

  void _showIconPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CategoryIconPickerDialog(
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
        // ignore: deprecated_member_use
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          iconType: _selectedIconType,
          color: _selectedColor.toARGB32(),
          parentId: _selectedParent?.categoryId,
          updatedAt: now,
        );

        await _categoryService.updateCategory(updatedCategory);
      } else {
        // ignore: deprecated_member_use
        final newCategory = CategoryModel(
          categoryId: '',
          userId: '',
          name: _nameController.text.trim(),
          type: _selectedTransactionType,
          icon: _selectedIcon!,
          iconType: _selectedIconType,
          color: _selectedColor.toARGB32()
,
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
