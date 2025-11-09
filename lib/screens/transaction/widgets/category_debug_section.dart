import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';
import 'package:moni/services/services.dart';

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

    // Trong production, hiển thị giao diện thân thiện hơn
    if (!kDebugMode) {
      return _buildUserFriendlyEmptyState(context);
    }

    // Trong development, hiển thị debug interface đầy đủ
    return _buildDebugInterface(context);
  }

  Widget _buildUserFriendlyEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 48,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có danh mục nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo danh mục đầu tiên để bắt đầu quản lý giao dịch',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await categoryService.createDefaultCategories();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã tạo danh mục mặc định thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi tạo danh mục: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.add_circle),
            label: const Text('Tạo danh mục mặc định'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInterface(BuildContext context) {
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã tạo danh mục mặc định')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi tạo danh mục: $e')),
                      );
                    }
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
