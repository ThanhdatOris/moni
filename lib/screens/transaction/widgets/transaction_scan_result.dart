import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';
import 'package:moni/constants/enums.dart';

import '../../../models/category_model.dart';
import '../../../utils/formatting/currency_formatter.dart';
import '../../../utils/helpers/category_icon_helper.dart';
import 'transaction_amount_input.dart';
import 'transaction_date_selector.dart';
import 'transaction_note_input.dart';
import 'transaction_type_selector.dart';

class TransactionScanResult extends StatefulWidget {
  final Map<String, dynamic> scanResult;
  final List<CategoryModel> categories;
  final Function(Map<String, dynamic>) onResultEdited;
  final VoidCallback onSave;
  final VoidCallback onRescan;

  const TransactionScanResult({
    super.key,
    required this.scanResult,
    required this.categories,
    required this.onResultEdited,
    required this.onSave,
    required this.onRescan,
  });

  @override
  State<TransactionScanResult> createState() => _TransactionScanResultState();
}

class _TransactionScanResultState extends State<TransactionScanResult> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late TransactionType _selectedType;
  late DateTime _selectedDate;
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final amount = widget.scanResult['amount'] ?? 0;
    // Xử lý amount an toàn để tránh FormatException
    int safeAmount;
    if (amount is int) {
      safeAmount = amount;
    } else if (amount is double) {
      safeAmount = amount.toInt();
    } else if (amount is String) {
      safeAmount = int.tryParse(amount) ?? 0;
    } else {
      safeAmount = 0;
    }

    _amountController = TextEditingController(
      text: CurrencyFormatter.formatDisplay(safeAmount),
    );
    _descriptionController = TextEditingController(
      text: widget.scanResult['note'] ?? widget.scanResult['description'] ?? '',
    );

    _selectedType = widget.scanResult['type'] == 'income'
        ? TransactionType.income
        : TransactionType.expense;

    _selectedDate = _parseDate(widget.scanResult['date']);
    _selectedCategory = _findCategory(widget.scanResult['category_name'] ??
        widget.scanResult['category_suggestion']);

    // Add listeners for real-time updates
    _amountController.addListener(_updateResult);
    _descriptionController.addListener(_updateResult);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết quả scan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Kiểm tra và chỉnh sửa thông tin nếu cần',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Form fields using common widgets
          TransactionAmountInput(
            controller: _amountController,
            onChanged: (_) => _updateResult(),
          ),
          const SizedBox(height: 16),

          TransactionTypeSelector(
            selectedType: _selectedType,
            onTypeChanged: (type) {
              setState(() {
                _selectedType = type;
              });
              _updateResult();
            },
          ),
          const SizedBox(height: 16),

          TransactionDateSelector(
            selectedDate: _selectedDate,
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
              _updateResult();
            },
          ),
          const SizedBox(height: 16),

          TransactionNoteInput(
            controller: _descriptionController,
          ),
          const SizedBox(height: 16),

          // Category selector
          _buildCategorySelector(),
          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Danh mục',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CategoryModel>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'Chọn danh mục',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(16),
            ),
            items: widget.categories
                .where((category) => category.type == _selectedType)
                .map((category) {
              return DropdownMenuItem<CategoryModel>(
                value: category,
                child: Row(
                  children: [
                    // Sử dụng CategoryIconHelper thay vì parse icon thành int
                    CategoryIconHelper.buildIcon(
                      category,
                      size: 20,
                      color: Color(category.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (CategoryModel? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
              _updateResult();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onRescan,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Scan lại'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: BorderSide(color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: widget.onSave,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Lưu giao dịch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  CategoryModel? _findCategory(String? categoryName) {
    if (categoryName == null) return null;

    try {
      return widget.categories.firstWhere(
        (category) =>
            category.name.toLowerCase().contains(categoryName.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  void _updateResult() {
    // Xử lý amount an toàn để tránh FormatException
    double safeAmount;
    try {
      safeAmount =
          CurrencyFormatter.getRawValue(_amountController.text).toDouble();
    } catch (e) {
      safeAmount = 0.0;
    }

    final updatedResult = {
      ...widget.scanResult,
      'amount': safeAmount,
      'note':
          _descriptionController.text, // Map thành note cho TransactionModel
      'description':
          _descriptionController.text, // Giữ lại cho backward compatibility
      'type': _selectedType == TransactionType.income ? 'income' : 'expense',
      'category_name': _selectedCategory?.name ?? '', // Lưu tên category
      'category_suggestion':
          _selectedCategory?.name ?? '', // Giữ lại cho backward compatibility
      'date': _selectedDate.toIso8601String().split('T')[0],
    };

    widget.onResultEdited(updatedResult);
  }
}
