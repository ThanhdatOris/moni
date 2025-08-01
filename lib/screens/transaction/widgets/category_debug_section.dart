import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../services/category_service.dart';

class CategoryDebugSection extends StatelessWidget {
  final List categories;
  final bool isCategoriesLoading;
  final CategoryService categoryService;
  final dynamic selectedType;
  final VoidCallback onDebugAllCategories;

  const CategoryDebugSection({
    super.key,
    required this.categories,
    required this.isCategoriesLoading,
    required this.categoryService,
    required this.selectedType,
    required this.onDebugAllCategories,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isNotEmpty || isCategoriesLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () async {
                  try {
                    await categoryService.createDefaultCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã tạo danh mục mặc định')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi tạo danh mục: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tạo danh mục'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              TextButton.icon(
                onPressed: onDebugAllCategories,
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ],
          ),
          // Show current type info
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              'Current type: ${selectedType.value}\nCategories loaded: ${categories.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
