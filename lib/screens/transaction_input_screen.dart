import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'category_selector_screen.dart';
import 'image_input_screen.dart';

class TransactionInputScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const TransactionInputScreen({
    super.key,
    this.transaction,
  });

  @override
  State<TransactionInputScreen> createState() => _TransactionInputScreenState();
}

class _TransactionInputScreenState extends State<TransactionInputScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedImagePath;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFormData();
  }

  void _initializeFormData() {
    if (_isEditing && widget.transaction != null) {
      final transaction = widget.transaction!;
      _amountController.text = transaction.amount.toString();
      _noteController.text = transaction.note;
      _selectedType = transaction.type;
      _selectedDate = transaction.date;
      _selectedTime = TimeOfDay.fromDateTime(transaction.date);
      _selectedImagePath = transaction.imageUrl;

      // Tìm category từ danh sách mặc định (trong thực tế sẽ load từ database)
      final categories = Category.getDefaultCategories();
      _selectedCategory = categories.firstWhere(
        (cat) => cat.id == transaction.categoryId,
        orElse: () => categories.first,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing
            ? AppStrings.editTransaction
            : AppStrings.addTransaction),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(
              icon: Icon(Icons.edit),
              text: AppStrings.quickInput,
            ),
            Tab(
              icon: Icon(Icons.camera_alt),
              text: AppStrings.inputByImage,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickInputTab(),
          _buildImageInputTab(),
        ],
      ),
    );
  }

  Widget _buildQuickInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 24),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            _buildDateTimeSelector(),
            const SizedBox(height: 24),
            _buildNoteInput(),
            const SizedBox(height: 24),
            _buildQuickTemplates(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageInputTab() {
    return ImageInputScreen(
      onImageSelected: (imagePath) {
        setState(() {
          _selectedImagePath = imagePath;
        });
      },
      onDataExtracted: (amount, category, note) {
        setState(() {
          _amountController.text = amount.toString();
          _noteController.text = note;
          if (category != null) {
            _selectedCategory = category;
          }
        });
      },
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              TransactionType.expense,
              AppStrings.expenseCategory,
              Icons.remove_circle,
              AppColors.expense,
            ),
          ),
          Container(width: 1, height: 50, color: AppColors.grey200),
          Expanded(
            child: _buildTypeButton(
              TransactionType.income,
              AppStrings.incomeCategory,
              Icons.add_circle,
              AppColors.income,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    TransactionType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: AppStrings.amount,
          hintText: '0',
          prefixIcon: Icon(
            Icons.attach_money,
            color: _selectedType == TransactionType.income
                ? AppColors.income
                : AppColors.expense,
          ),
          suffixText: 'đ',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.backgroundLight,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppStrings.errorAmount;
          }
          final amount = double.tryParse(value);
          if (amount == null || amount <= 0) {
            return AppStrings.errorAmount;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return InkWell(
      onTap: _selectCategory,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _selectedCategory == null ? AppColors.error : AppColors.grey200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (_selectedCategory?.color ?? AppColors.grey300)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _selectedCategory?.icon ?? Icons.category,
                color: _selectedCategory?.color ?? AppColors.grey500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.selectCategory,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCategory?.name ?? 'Chọn danh mục',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateSelector(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeSelector(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.date,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.time,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _noteController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: AppStrings.note,
          hintText: 'Nhập ghi chú cho giao dịch...',
          prefixIcon: Icon(Icons.note, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.backgroundLight,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildQuickTemplates() {
    final templates = _getQuickTemplates();
    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mẫu nhanh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: templates
              .map((template) => _buildTemplateChip(template))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTemplateChip(Map<String, dynamic> template) {
    return InkWell(
      onTap: () => _applyTemplate(template),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              template['icon'],
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              template['name'],
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Text(
          AppStrings.save,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getQuickTemplates() {
    if (_selectedType == TransactionType.expense) {
      return [
        {
          'name': 'Ăn sáng',
          'amount': 25000,
          'category': 'expense_food',
          'icon': Icons.breakfast_dining
        },
        {
          'name': 'Cà phê',
          'amount': 30000,
          'category': 'expense_food',
          'icon': Icons.coffee
        },
        {
          'name': 'Xăng xe',
          'amount': 100000,
          'category': 'expense_transport',
          'icon': Icons.local_gas_station
        },
        {
          'name': 'Grab',
          'amount': 50000,
          'category': 'expense_transport',
          'icon': Icons.car_rental
        },
      ];
    } else {
      return [
        {
          'name': 'Lương',
          'amount': 10000000,
          'category': 'income_salary',
          'icon': Icons.work
        },
        {
          'name': 'Thưởng',
          'amount': 2000000,
          'category': 'income_bonus',
          'icon': Icons.card_giftcard
        },
      ];
    }
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _amountController.text = template['amount'].toString();
      final categories = Category.getDefaultCategories();
      _selectedCategory = categories.firstWhere(
        (cat) => cat.id == template['category'],
        orElse: () => categories.first,
      );
    });
  }

  void _selectCategory() async {
    final category = await Navigator.push<Category>(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySelectorScreen(
          transactionType: _selectedType,
          selectedCategory: _selectedCategory,
        ),
      ),
    );
    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorCategory)),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final transaction = Transaction(
      id: _isEditing ? widget.transaction!.id : null,
      amount: amount,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      type: _selectedType,
      date: combinedDateTime,
      note: _noteController.text.trim(),
      imageUrl: _selectedImagePath,
    );

    // TODO: Lưu transaction vào database
    debugPrint('Saving transaction: $transaction');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? AppStrings.successEditTransaction
            : AppStrings.successAddTransaction),
        backgroundColor: AppColors.success,
      ),
    );

    // Return to previous screen
    Navigator.pop(context, transaction);
  }
}
