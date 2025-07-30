import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/category_service.dart';
import '../../utils/helpers/category_icon_helper.dart';
import '../../widgets/category_icon_picker.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final CategoryModel? category;
  final TransactionType transactionType;

  const AddEditCategoryScreen({
    super.key,
    this.category,
    required this.transactionType,
  });

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final GetIt _getIt = GetIt.instance;
  late final CategoryService _categoryService;

  // Form data
  String? _selectedIcon;
  CategoryIconType _selectedIconType = CategoryIconType.material;
  Color _selectedColor = const Color(0xFF607D8B);
  CategoryModel? _selectedParent;
  List<CategoryModel> _parentCategories = [];
  bool _isLoading = false;
  bool _isLoadingParents = false;

  // Predefined colors
  final List<Color> _availableColors = [
    const Color(0xFFFF6B35), // Orange
    const Color(0xFF2196F3), // Blue
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Amber
    const Color(0xFFF44336), // Red
    const Color(0xFF4CAF50), // Green
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFFFD700), // Gold
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF795548), // Brown
    const Color(0xFF9E9E9E), // Grey
    const Color(0xFF3F51B5), // Indigo
  ];

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _categoryService = _getIt<CategoryService>();

    if (isEditing) {
      _initializeForEditing();
    } else {
      _initializeForAdding();
    }

    _loadParentCategories();
  }

  void _initializeForEditing() {
    final category = widget.category!;
    _nameController.text = category.name;
    _selectedIcon = category.icon;
    _selectedIconType = category.iconType;
    _selectedColor = Color(category.color);
  }

  void _initializeForAdding() {
    // Set default icon based on transaction type
    if (widget.transactionType == TransactionType.expense) {
      _selectedIcon = '🍽️';
      _selectedIconType = CategoryIconType.emoji;
    } else {
      _selectedIcon = '💼';
      _selectedIconType = CategoryIconType.emoji;
    }
    _selectedColor = _availableColors.first;
  }

  Future<void> _loadParentCategories() async {
    setState(() {
      _isLoadingParents = true;
    });

    try {
      final categories = await _categoryService
          .getCategories(type: widget.transactionType)
          .first;

      setState(() {
        // Chỉ lấy parent categories và sắp xếp theo tên
        _parentCategories = categories
            .where((c) =>
                c.isParentCategory &&
                (!isEditing || c.categoryId != widget.category!.categoryId))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        // Set selected parent if editing and has parent
        if (isEditing && widget.category!.parentId != null) {
          _selectedParent = _parentCategories
              .where((p) => p.categoryId == widget.category!.parentId)
              .firstOrNull;
          
          // Nếu không tìm thấy parent trong danh sách hiện tại, tải lại
          if (_selectedParent == null) {
            _loadSpecificParent(widget.category!.parentId!);
          }
        }

        _isLoadingParents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingParents = false;
      });
      _showErrorSnackBar('Lỗi tải danh sách danh mục cha: $e');
    }
  }

  /// Load specific parent category nếu không có trong danh sách
  Future<void> _loadSpecificParent(String parentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(parentId)
          .get();

      if (doc.exists) {
        final parentCategory = CategoryModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        
        setState(() {
          _selectedParent = parentCategory;
          // Thêm vào danh sách nếu chưa có
          if (!_parentCategories.any((p) => p.categoryId == parentId)) {
            _parentCategories.add(parentCategory);
            _parentCategories.sort((a, b) => a.name.compareTo(b.name));
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi tải thông tin danh mục cha: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(),
              const SizedBox(height: 24),
              _buildIconSelector(),
              const SizedBox(height: 24),
              _buildColorSelector(),
              const SizedBox(height: 24),
              _buildParentSelector(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        isEditing ? 'Sửa danh mục' : 'Thêm danh mục',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha:0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tên danh mục',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Nhập tên danh mục',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha:0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha:0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_emotions,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Biểu tượng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showIconPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (_selectedIcon != null)
                    CategoryIconHelper.buildIconPreview(
                      _selectedIcon!,
                      _selectedIconType,
                      size: 32,
                      isSelected: true,
                      categoryColor: _selectedColor,
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha:0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedIcon != null
                              ? 'Biểu tượng đã chọn'
                              : 'Chọn biểu tượng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedIconType == CategoryIconType.emoji
                              ? 'Emoji'
                              : 'Material Icon',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha:0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Màu sắc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableColors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha:0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildParentSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha:0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Danh mục cha (tùy chọn)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingParents)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            DropdownButtonFormField<CategoryModel>(
              value: _selectedParent,
              decoration: InputDecoration(
                hintText: 'Chọn danh mục cha',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha:0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: [
                const DropdownMenuItem<CategoryModel>(
                  value: null,
                  child: Text('Không có danh mục cha'),
                ),
                ..._parentCategories.map((parent) {
                  return DropdownMenuItem<CategoryModel>(
                    value: parent,
                    child: Row(
                      children: [
                        CategoryIconHelper.buildIcon(
                          parent,
                          size: 20,
                          color: Color(parent.color),
                          showBackground: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            parent.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedParent = value;
                });
              },
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : Text(
                isEditing ? 'Cập nhật danh mục' : 'Tạo danh mục',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showIconPicker() async {
    final result = await CategoryIconPickerHelper.showIconPicker(
      context: context,
      currentIcon: _selectedIcon,
      currentIconType: _selectedIconType,
      transactionType: widget.transactionType,
      categoryColor: _selectedColor,
    );

    if (result != null) {
      setState(() {
        _selectedIcon = result['icon'];
        _selectedIconType = result['iconType'];
      });
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIcon == null) {
      _showErrorSnackBar('Vui lòng chọn biểu tượng');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      if (isEditing) {
        // Update existing category
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
        // Create new category
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
      }
    } catch (e) {
      _showErrorSnackBar(
        isEditing ? 'Lỗi cập nhật danh mục: $e' : 'Lỗi tạo danh mục: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
