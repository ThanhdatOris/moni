import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../constants/app_colors.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/ai_processor_service.dart';
import '../services/category_service.dart';
import 'transaction_image_picker.dart';
import 'transaction_scan_result.dart';

class TransactionAiScanTab extends StatefulWidget {
  final Function(Map<String, dynamic>) onScanComplete;
  final VoidCallback onScanSaved;

  const TransactionAiScanTab({
    super.key,
    required this.onScanComplete,
    required this.onScanSaved,
  });

  @override
  State<TransactionAiScanTab> createState() => _TransactionAiScanTabState();
}

class _TransactionAiScanTabState extends State<TransactionAiScanTab> {
  String? _selectedImagePath;
  bool _isProcessingImage = false;
  Map<String, dynamic>? _scanResults;
  List<CategoryModel> _categories = [];
  String? _errorMessage;
  bool _isCategoriesLoading = true;

  final GetIt _getIt = GetIt.instance;
  late final AIProcessorService _aiProcessorService;
  late final CategoryService _categoryService;

  @override
  void initState() {
    super.initState();
    _aiProcessorService = _getIt<AIProcessorService>();
    _categoryService = _getIt<CategoryService>();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Load categories with proper stream handling
      final List<CategoryModel> allCategories = [];
      
      // Load expense categories
      try {
        final expenseStream = _categoryService.getCategories(type: TransactionType.expense);
        await for (final expenseCategories in expenseStream.take(1)) {
          allCategories.addAll(expenseCategories.where((cat) => !cat.isDeleted));
          break;
        }
      } catch (e) {
        Logger().e('Error loading expense categories: $e');
      }

      // Load income categories  
      try {
        final incomeStream = _categoryService.getCategories(type: TransactionType.income);
        await for (final incomeCategories in incomeStream.take(1)) {
          allCategories.addAll(incomeCategories.where((cat) => !cat.isDeleted));
          break;
        }
      } catch (e) {
        Logger().e('Error loading income categories: $e');
      }

      if (mounted) {
        setState(() {
          _categories = allCategories;
          _isCategoriesLoading = false;
        });
        Logger().i('Loaded ${allCategories.length} categories for scan tab');
      }
    } catch (e) {
      Logger().e('Error in _loadCategories: $e');
      if (mounted) {
        setState(() {
          _categories = [];
          _isCategoriesLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiHeader(),
          const SizedBox(height: 24),
          if (_isCategoriesLoading) ...[
            _buildCategoriesLoadingCard(),
          ] else if (_selectedImagePath == null) ...[
            TransactionImagePicker(
              onImagePicked: _handleImagePicked,
            ),
          ] else if (_isProcessingImage) ...[
            _buildProcessingCard(),
          ] else if (_scanResults != null) ...[
            TransactionScanResult(
              scanResult: _scanResults!,
              categories: _categories,
              onResultEdited: _handleResultEdited,
              onSave: widget.onScanSaved,
              onRescan: _resetScan,
            ),
          ] else if (_errorMessage != null) ...[
            _buildErrorCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildAiHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan hóa đơn thông minh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI sẽ tự động trích xuất thông tin từ hóa đơn',
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
    );
  }

  Widget _buildCategoriesLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang tải danh mục...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng đợi để load danh mục giao dịch',
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
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(_selectedImagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Processing animation
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang phân tích hóa đơn...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OCR + AI đang đọc và phân tích',
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

          const SizedBox(height: 16),

          // Cancel button
          OutlinedButton(
            onPressed: _resetScan,
            child: const Text('Hủy'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Không thể xử lý ảnh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Có lỗi xảy ra khi xử lý ảnh',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetScan,
                  child: const Text('Chọn ảnh khác'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    side: BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _processCurrentImage,
                  child: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleImagePicked(File imageFile) async {
    try {
      // Check if categories are loaded
      if (_categories.isEmpty) {
        throw Exception('Chưa có danh mục khả dụng. Vui lòng tạo danh mục trước khi scan.');
      }

      // Validate image first
      await _aiProcessorService.validateImageForProcessing(imageFile);

      setState(() {
        _selectedImagePath = imageFile.path;
        _isProcessingImage = true;
        _scanResults = null;
        _errorMessage = null;
      });

      await _processCurrentImage();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _processCurrentImage() async {
    if (_selectedImagePath == null) return;

    setState(() {
      _isProcessingImage = true;
      _errorMessage = null;
    });

    try {
      final imageFile = File(_selectedImagePath!);
      final result = await _aiProcessorService
          .extractTransactionFromImageWithOCR(imageFile);

      if (mounted) {
        setState(() {
          _isProcessingImage = false;
          if (result['success'] == true) {
            _scanResults = result;
            widget.onScanComplete(result);
          } else {
            _errorMessage =
                result['error'] ?? 'Không thể đọc được thông tin từ ảnh';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
          _errorMessage = 'Lỗi xử lý ảnh: $e';
        });
      }
    }
  }

  void _handleResultEdited(Map<String, dynamic> updatedResult) {
    setState(() {
      _scanResults = updatedResult;
    });
    widget.onScanComplete(updatedResult);
  }

  void _resetScan() {
    setState(() {
      _selectedImagePath = null;
      _isProcessingImage = false;
      _scanResults = null;
      _errorMessage = null;
    });
  }
}
