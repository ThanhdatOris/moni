import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:moni/constants/app_colors.dart';
import '../../../services/providers/providers.dart';
import 'package:moni/services/services.dart';
import 'transaction_image_picker.dart';

class TransactionAiScanTab extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onScanComplete;

  const TransactionAiScanTab({
    super.key,
    required this.onScanComplete,
  });

  @override
  ConsumerState<TransactionAiScanTab> createState() => _TransactionAiScanTabState();
}

class _TransactionAiScanTabState extends ConsumerState<TransactionAiScanTab> {
  String? _selectedImagePath;
  bool _isProcessingImage = false;
  Map<String, dynamic>? _scanResults;
  String? _errorMessage;

  late final AIProcessorService _aiProcessorService;

  @override
  void initState() {
    super.initState();
    _aiProcessorService = GetIt.instance<AIProcessorService>();
  }

  @override
  Widget build(BuildContext context) {
    // Watch categories provider
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final isCategoriesLoading = categoriesAsync.isLoading;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiHeader(),
          const SizedBox(height: 24),
          if (isCategoriesLoading) ...[
            _buildCategoriesLoadingCard(),
          ] else if (_selectedImagePath == null) ...[
            TransactionImagePicker(
              onImagePicked: _handleImagePicked,
            ),
          ] else if (_isProcessingImage) ...[
            _buildProcessingCard(),
          ] else if (_scanResults != null) ...[
            _buildScanCompleteCard(),
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
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hủy'),
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    side: BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Chọn ảnh khác'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _processCurrentImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Thử lại'),
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
      final categoriesAsync = ref.read(allCategoriesProvider);
      if (!categoriesAsync.hasValue || categoriesAsync.value!.isEmpty) {
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

  Widget _buildScanCompleteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan thành công!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dữ liệu đã được điền tự động vào form',
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
          const SizedBox(height: 20),
          
          // Show basic scan info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow('Số tiền:', _formatAmount(_scanResults!['amount'])),
                const SizedBox(height: 8),
                _buildInfoRow('Loại:', _scanResults!['type'] == 'income' ? 'Thu nhập' : 'Chi tiêu'),
                const SizedBox(height: 8),
                _buildInfoRow('Ghi chú:', _scanResults!['note'] ?? _scanResults!['description'] ?? ''),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetScan,
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
                  onPressed: () {
                    // Chuyển về tab manual để chỉnh sửa
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Chỉnh sửa'),
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
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    if (amount is String) {
      return amount;
    }
    if (amount is num) {
      return '${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
    }
    return amount.toString();
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
