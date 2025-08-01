import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/category_service.dart';
import 'ai_filled_banner.dart';
import 'category_debug_section.dart';
import 'enhanced_category_selector.dart';
import 'enhanced_save_button.dart';
import 'transaction_amount_input.dart';
import 'transaction_date_selector.dart';
import 'transaction_note_input.dart';
import 'transaction_type_selector.dart';

class TransactionManualForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Logger logger;
  
  // Controllers
  final TextEditingController amountController;
  final TextEditingController noteController;
  
  // Transaction data
  final TransactionType selectedType;
  final CategoryModel? selectedCategory;
  final DateTime selectedDate;
  final List<CategoryModel> categories;
  final bool isCategoriesLoading;
  final String? categoriesError;
  final bool isLoading;
  
  // AI tracking
  final Set<String> aiFilledFields;
  final bool showAiFilledHint;
  
  // Services
  final CategoryService categoryService;
  final TransactionType currentTransactionType;
  
  // Callbacks
  final Function(TransactionType) onTypeChanged;
  final Function(String) onAmountChanged;
  final Function(CategoryModel?) onCategoryChanged;
  final VoidCallback onRetryLoadCategories;
  final Function(DateTime) onDateChanged;
  final VoidCallback onSaveTransaction;
  final VoidCallback onDebugAllCategories;
  final VoidCallback onDismissAiBanner;

  const TransactionManualForm({
    super.key,
    required this.formKey,
    required this.logger,
    required this.amountController,
    required this.noteController,
    required this.selectedType,
    required this.selectedCategory,
    required this.selectedDate,
    required this.categories,
    required this.isCategoriesLoading,
    required this.categoriesError,
    required this.isLoading,
    required this.aiFilledFields,
    required this.showAiFilledHint,
    required this.categoryService,
    required this.currentTransactionType,
    required this.onTypeChanged,
    required this.onAmountChanged,
    required this.onCategoryChanged,
    required this.onRetryLoadCategories,
    required this.onDateChanged,
    required this.onSaveTransaction,
    required this.onDebugAllCategories,
    required this.onDismissAiBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Auto-fill hint banner
            if (showAiFilledHint)
              AiFilledBanner(
                aiFilledFields: aiFilledFields,
                onDismiss: onDismissAiBanner,
              ),
            
            TransactionTypeSelector(
              selectedType: selectedType,
              onTypeChanged: (type) {
                if (type != selectedType) {
                  logger.d('🔄 Transaction type changed from ${selectedType.value} to ${type.value}');
                  onTypeChanged(type);
                }
              },
            ),
            const SizedBox(height: 16),
            
            TransactionAmountInput(
              controller: amountController,
              onChanged: onAmountChanged,
            ),
            const SizedBox(height: 16),
            
            EnhancedCategorySelector(
              selectedCategory: selectedCategory,
              categories: categories,
              isLoading: isCategoriesLoading,
              errorMessage: categoriesError,
              onCategoryChanged: onCategoryChanged,
              onRetry: onRetryLoadCategories,
              transactionType: currentTransactionType,
              transactionNote: noteController.text.isNotEmpty ? noteController.text : null,
              transactionTime: selectedDate,
            ),
            
            // Debug section for empty categories
            CategoryDebugSection(
              categories: categories,
              isCategoriesLoading: isCategoriesLoading,
              categoryService: categoryService,
              selectedType: selectedType,
              onDebugAllCategories: onDebugAllCategories,
            ),
            
            const SizedBox(height: 16),
            
            TransactionDateSelector(
              selectedDate: selectedDate,
              onDateChanged: onDateChanged,
            ),
            const SizedBox(height: 16),
            
            TransactionNoteInput(
              controller: noteController,
            ),
            const SizedBox(height: 20),
            
            EnhancedSaveButton(
              isLoading: isLoading,
              onSave: onSaveTransaction,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }
}
