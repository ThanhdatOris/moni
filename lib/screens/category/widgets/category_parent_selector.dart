import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../utils/helpers/category_icon_helper.dart';

class CategoryParentSelector extends StatelessWidget {
  final bool showParentSelector;
  final CategoryModel? selectedParent;
  final List<CategoryModel> availableParents;
  final bool isLoadingParents;
  final Color selectedColor;
  final ValueChanged<bool> onToggleParentSelector;
  final ValueChanged<CategoryModel?> onParentChanged;

  const CategoryParentSelector({
    super.key,
    required this.showParentSelector,
    required this.selectedParent,
    required this.availableParents,
    required this.isLoadingParents,
    required this.selectedColor,
    required this.onToggleParentSelector,
    required this.onParentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                value: showParentSelector,
                onChanged: onToggleParentSelector,
                activeColor: selectedColor,
              ),
            ],
          ),
        ),
        
        // Parent selector
        if (showParentSelector) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: _buildParentDropdown(),
          ),
        ],
      ],
    );
  }

  Widget _buildParentDropdown() {
    if (isLoadingParents) {
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
      initialValue: selectedParent,
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
          borderSide: BorderSide(color: selectedColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: availableParents.map((parent) {
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
      onChanged: onParentChanged,
      dropdownColor: Colors.white,
    );
  }
}
