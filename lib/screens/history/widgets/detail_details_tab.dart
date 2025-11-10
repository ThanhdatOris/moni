import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:moni/config/app_config.dart';
import 'package:moni/services/services.dart';

import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import 'detail_amount_card.dart';
import 'detail_info_card.dart';

class DetailDetailsTab extends StatefulWidget {
  final TransactionModel transaction;
  final CategoryModel? selectedCategory;

  const DetailDetailsTab({
    super.key,
    required this.transaction,
    required this.selectedCategory,
  });

  @override
  State<DetailDetailsTab> createState() => _DetailDetailsTabState();
}

class _DetailDetailsTabState extends State<DetailDetailsTab> {
  CategoryModel? _categoryData;
  bool _isLoadingCategory = false;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  @override
  void didUpdateWidget(DetailDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload category nếu selectedCategory thay đổi
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _loadCategoryData();
    }
  }

  Future<void> _loadCategoryData() async {
    // Ưu tiên selectedCategory từ parent
    if (widget.selectedCategory != null) {
      setState(() {
        _categoryData = widget.selectedCategory;
        _isLoadingCategory = false;
      });
      return;
    }

    // Nếu không có selectedCategory, load từ service
    if (widget.transaction.categoryId.isNotEmpty) {
      setState(() {
        _isLoadingCategory = true;
      });

      try {
        final categoryService = GetIt.instance<CategoryService>();
        final category = await categoryService.getCategory(widget.transaction.categoryId);
        
        if (mounted) {
          setState(() {
            _categoryData = category;
            _isLoadingCategory = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _categoryData = null;
            _isLoadingCategory = false;
          });
        }
      }
    } else {
      setState(() {
        _categoryData = null;
        _isLoadingCategory = false;
      });
    }
  }

  String get _categoryDisplayName {
    if (_isLoadingCategory) return 'Đang tải...';
    if (_categoryData != null) return _categoryData!.name;
    
    // Fallback dựa trên transaction type và categoryName
    if (widget.transaction.categoryName?.isNotEmpty == true) {
      return widget.transaction.categoryName!;
    }
    
    return widget.transaction.type == TransactionType.income ? 'Thu nhập' : 'Chi tiêu';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Card
          DetailAmountCard(transaction: widget.transaction),

          const SizedBox(height: 24),

          // Details Cards
          DetailInfoCard(
            icon: Icons.category_outlined,
            title: 'Danh mục',
            value: _categoryDisplayName,
            categoryIcon: _categoryData,
          ),

          const SizedBox(height: 16),

          DetailInfoCard(
            icon: Icons.calendar_today_outlined,
            title: 'Ngày',
            value: DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                .format(widget.transaction.date),
          ),

          const SizedBox(height: 16),

          DetailInfoCard(
            icon: Icons.access_time_outlined,
            title: 'Thời gian',
            value: DateFormat('HH:mm').format(widget.transaction.date),
          ),

          if (widget.transaction.note?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            DetailInfoCard(
              icon: Icons.note_outlined,
              title: 'Ghi chú',
              value: widget.transaction.note!,
              isMultiline: true,
            ),
          ],

          const SizedBox(height: 16),

          DetailInfoCard(
            icon: Icons.update_outlined,
            title: 'Cập nhật lần cuối',
            value: DateFormat('dd/MM/yyyy HH:mm')
                .format(widget.transaction.updatedAt),
          ),
        ],
      ),
    );
  }
}