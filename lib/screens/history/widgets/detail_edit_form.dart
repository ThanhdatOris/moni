import 'package:flutter/material.dart';

import 'package:moni/config/app_config.dart';

import '../../../models/category_model.dart';
import '../../transaction/widgets/enhanced_category_selector.dart';
import '../../transaction/widgets/transaction_amount_input.dart';
import '../../transaction/widgets/transaction_date_selector.dart';
import '../../transaction/widgets/transaction_note_input.dart';
import '../../transaction/widgets/transaction_type_selector.dart';

class DetailEditForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final TransactionType selectedType;
  final CategoryModel? selectedCategory;
  final DateTime selectedDate;
  final List<CategoryModel> categories;
  final bool isCategoriesLoading;
  final bool isLoading;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<CategoryModel?> onCategoryChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onRetry;
  final VoidCallback onSave;

  const DetailEditForm({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.noteController,
    required this.selectedType,
    required this.selectedCategory,
    required this.selectedDate,
    required this.categories,
    required this.isCategoriesLoading,
    required this.isLoading,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onDateChanged,
    required this.onRetry,
    required this.onSave,
  });

  @override
  State<DetailEditForm> createState() => _DetailEditFormState();
}

class _DetailEditFormState extends State<DetailEditForm> {

  @override
  void initState() {
    super.initState();
    // Listen to note changes để refresh category suggestions
    widget.noteController.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    widget.noteController.removeListener(_onNoteChanged);
    super.dispose();
  }

  void _onNoteChanged() {
    // Force rebuild khi note thay đổi để update suggestions
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Selector
            TransactionTypeSelector(
              selectedType: widget.selectedType,
              onTypeChanged: widget.onTypeChanged,
            ),

            const SizedBox(height: 24),

            // Amount Input
            TransactionAmountInput(
              controller: widget.amountController,
            ),

            const SizedBox(height: 24),

            // Category Selector (Enhanced với suggestions)
            EnhancedCategorySelector(
              key: ValueKey('${widget.selectedType}_${widget.categories.length}'),
              selectedCategory: widget.selectedCategory,
              categories: widget.categories,
              isLoading: widget.isCategoriesLoading,
              onCategoryChanged: widget.onCategoryChanged,
              onRetry: widget.onRetry,
              transactionType: widget.selectedType,
              transactionNote: widget.noteController.text.isNotEmpty 
                  ? widget.noteController.text 
                  : null,
              transactionTime: widget.selectedDate,
            ),

            const SizedBox(height: 24),

            // Date Selector
            TransactionDateSelector(
              selectedDate: widget.selectedDate,
              onDateChanged: widget.onDateChanged,
            ),

            const SizedBox(height: 24),

            // Note Input
            TransactionNoteInput(
              controller: widget.noteController,
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Cập nhật giao dịch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
