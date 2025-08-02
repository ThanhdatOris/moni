/// Category Optimizer - Chuyên tối ưu hóa danh mục chi tiêu
/// Được tách từ AIAnalyticsService để cải thiện maintainability

import '../../core/models/analytics/analytics_models.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../base_service.dart';
import '../category_service.dart';
import '../offline_service.dart';
import '../transaction_service.dart';

/// Service chuyên tối ưu hóa danh mục và đưa ra gợi ý cải thiện
class CategoryOptimizer extends BaseService {
  static final CategoryOptimizer _instance = CategoryOptimizer._internal();
  factory CategoryOptimizer() => _instance;
  CategoryOptimizer._internal();

  late final TransactionService _transactionService;
  late final CategoryService _categoryService;

  /// Initialize services (call this before using)
  void _initializeServices() {
    final offlineService = OfflineService();
    _transactionService = TransactionService(offlineService: offlineService);
    _categoryService = CategoryService();
  }

  /// Main method: Optimize categories and provide recommendations
  Future<CategoryOptimization> optimizeCategories() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      _initializeServices();
      logInfo('Optimizing categories for user: $currentUserId');

      final currentCategories = await _categoryService.getCategories().first;
      final transactions = await _getAllTransactions();

      if (currentCategories.isEmpty) {
        return _getEmptyOptimization();
      }

      // Run optimization analyses in parallel
      final futures = await Future.wait([
        _suggestCategoryMerges(currentCategories, transactions),
        _suggestCategorySplits(currentCategories, transactions),
        _identifyUnusedCategories(currentCategories, transactions),
        _suggestNewCategories(transactions),
      ]);

      final optimization = CategoryOptimization(
        suggestedMerges: futures[0] as List<CategoryMergeRecommendation>,
        suggestedSplits: futures[1] as List<CategorySplitRecommendation>,
        unusedCategories: futures[2] as List<String>,
        newCategorySuggestions: futures[3] as List<String>,
        optimizationDate: DateTime.now(),
        potentialSavings: _calculatePotentialSavings(
          futures[0] as List<CategoryMergeRecommendation>,
          futures[1] as List<CategorySplitRecommendation>,
        ),
      );

      logInfo('Completed category optimization');
      return optimization;
    } catch (e) {
      logError('Error optimizing categories', e);
      return _getEmptyOptimization();
    }
  }

  /// Get urgent optimizations that need immediate attention
  Future<List<Map<String, dynamic>>> getUrgentOptimizations() async {
    try {
      _initializeServices();
      final optimization = await optimizeCategories();
      final urgent = <Map<String, dynamic>>[];

      // Check for urgent merges (high confidence)
      for (final merge in optimization.highConfidenceMerges) {
        if (merge.confidence >= 0.8) {
          urgent.add({
            'type': 'merge',
            'title': 'Gộp danh mục',
            'description': merge.actionText,
            'priority': merge.confidence,
          });
        }
      }

      // Check for too many unused categories
      if (optimization.unusedCategories.length >= 5) {
        urgent.add({
          'type': 'cleanup',
          'title': 'Dọn dẹp danh mục',
          'description': 'Có ${optimization.unusedCategories.length} danh mục không sử dụng',
          'priority': 0.9,
        });
      }

      return urgent;
    } catch (e) {
      logError('Error getting urgent optimizations', e);
      return [];
    }
  }

  /// Analyze category usage patterns
  Future<List<CategoryAnalysisData>> analyzeCategoryUsage() async {
    try {
      _initializeServices();
      final categories = await _categoryService.getCategories().first;
      final transactions = await _getAllTransactions();
      final analysisData = <CategoryAnalysisData>[];

      for (final category in categories) {
        final categoryTransactions = transactions
            .where((t) => t.categoryId == category.id)
            .toList();

        final data = await _createCategoryAnalysisData(category, categoryTransactions);
        analysisData.add(data);
      }

      // Sort by health score (lowest first - needs attention)
      analysisData.sort((a, b) => a.healthScore.compareTo(b.healthScore));
      
      return analysisData;
    } catch (e) {
      logError('Error analyzing category usage', e);
      return [];
    }
  }

  /// Get categories that are candidates for merging
  Future<Map<String, List<CategoryModel>>> getMergeCandidates() async {
    try {
      _initializeServices();
      final categories = await _categoryService.getCategories().first;
      final transactions = await _getAllTransactions();
      final mergeCandidates = <String, List<CategoryModel>>{};

      // Group categories by similarity
      for (int i = 0; i < categories.length; i++) {
        for (int j = i + 1; j < categories.length; j++) {
          final category1 = categories[i];
          final category2 = categories[j];
          
          final similarity = await _calculateCategorySimilarity(
            category1, 
            category2, 
            transactions,
          );

          if (similarity >= 0.7) {
            final key = '${category1.name}_${category2.name}';
            mergeCandidates[key] = [category1, category2];
          }
        }
      }

      return mergeCandidates;
    } catch (e) {
      logError('Error getting merge candidates', e);
      return {};
    }
  }

  /// Get categories that need to be split
  Future<List<CategoryModel>> getSplitCandidates() async {
    try {
      _initializeServices();
      final categories = await _categoryService.getCategories().first;
      final transactions = await _getAllTransactions();
      final splitCandidates = <CategoryModel>[];

      for (final category in categories) {
        final categoryTransactions = transactions
            .where((t) => t.categoryId == category.id)
            .toList();

        // Categories with high transaction count and high variance might need splitting
        if (categoryTransactions.length >= 20) {
          final amounts = categoryTransactions.map((t) => t.amount).toList();
          final variance = _calculateVariance(amounts);
          final mean = amounts.reduce((a, b) => a + b) / amounts.length;
          final coefficientOfVariation = variance / mean;

          if (coefficientOfVariation > 1.5) { // High variation
            splitCandidates.add(category);
          }
        }
      }

      return splitCandidates;
    } catch (e) {
      logError('Error getting split candidates', e);
      return [];
    }
  }

  // Private optimization methods

  Future<List<CategoryMergeRecommendation>> _suggestCategoryMerges(
    List<CategoryModel> categories,
    List<TransactionModel> transactions,
  ) async {
    final recommendations = <CategoryMergeRecommendation>[];

    // Find similar categories that can be merged
    for (int i = 0; i < categories.length; i++) {
      for (int j = i + 1; j < categories.length; j++) {
        final category1 = categories[i];
        final category2 = categories[j];
        
        final similarity = await _calculateCategorySimilarity(
          category1, 
          category2, 
          transactions,
        );

        if (similarity >= 0.7) {
          recommendations.add(CategoryMergeRecommendation(
            categoryIds: [category1.id, category2.id],
            suggestedName: _suggestMergedName(category1, category2),
            reason: 'Hai danh mục này có mẫu chi tiêu tương tự (${(similarity * 100).toInt()}% giống nhau)',
            confidence: similarity,
          ));
        }
      }
    }

    // Sort by confidence
    recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
    return recommendations.take(5).toList(); // Top 5 suggestions
  }

  Future<List<CategorySplitRecommendation>> _suggestCategorySplits(
    List<CategoryModel> categories,
    List<TransactionModel> transactions,
  ) async {
    final recommendations = <CategorySplitRecommendation>[];

    for (final category in categories) {
      final categoryTransactions = transactions
          .where((t) => t.categoryId == category.id)
          .toList();

      if (categoryTransactions.length < 10) continue; // Not enough data

      // Analyze transaction patterns to suggest splits
      final splits = await _analyzePotentialSplits(category, categoryTransactions);
      
      if (splits.isNotEmpty) {
        recommendations.add(CategorySplitRecommendation(
          categoryId: category.id,
          suggestedSplits: splits,
          reason: 'Danh mục này có nhiều loại chi tiêu khác nhau có thể tách riêng',
          confidence: _calculateSplitConfidence(categoryTransactions),
        ));
      }
    }

    // Sort by confidence
    recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
    return recommendations.take(3).toList(); // Top 3 suggestions
  }

  Future<List<String>> _identifyUnusedCategories(
    List<CategoryModel> categories,
    List<TransactionModel> transactions,
  ) async {
    final usedCategories = transactions.map((t) => t.categoryId).toSet();
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(threeMonthsAgo))
        .map((t) => t.categoryId)
        .toSet();

    final unusedCategories = <String>[];

    for (final category in categories) {
      // Category is unused if:
      // 1. Never used, OR
      // 2. Not used in last 3 months
      if (!usedCategories.contains(category.id) || 
          !recentTransactions.contains(category.id)) {
        unusedCategories.add(category.id);
      }
    }

    return unusedCategories;
  }

  Future<List<String>> _suggestNewCategories(
    List<TransactionModel> transactions,
  ) async {
    final suggestions = <String>[];

    // Analyze transaction notes for common keywords
    final keywords = <String, int>{};
    for (final transaction in transactions) {
      if (transaction.note != null && transaction.note!.isNotEmpty) {
        final words = transaction.note!.toLowerCase().split(' ');
        for (final word in words) {
          if (word.length > 3) { // Only meaningful words
            keywords[word] = (keywords[word] ?? 0) + 1;
          }
        }
      }
    }

    // Find common keywords that might suggest new categories
    final commonKeywords = keywords.entries
        .where((entry) => entry.value >= 5) // Used at least 5 times
        .map((entry) => entry.key)
        .toList();

    // Suggest categories based on common keywords
    for (final keyword in commonKeywords.take(3)) {
      suggestions.add(_keywordToCategory(keyword));
    }

    return suggestions;
  }

  Future<CategoryAnalysisData> _createCategoryAnalysisData(
    CategoryModel category,
    List<TransactionModel> transactions,
  ) async {
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final averageAmount = transactions.isNotEmpty ? totalAmount / transactions.length : 0.0;
    final lastUsed = transactions.isNotEmpty 
        ? transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now().subtract(const Duration(days: 365));

    // Extract common keywords from notes
    final keywords = <String>[];
    for (final transaction in transactions) {
      if (transaction.note != null && transaction.note!.isNotEmpty) {
        final words = transaction.note!.toLowerCase().split(' ');
        keywords.addAll(words.where((w) => w.length > 3));
      }
    }

    // Calculate similarity to other categories (simplified)
    final similarity = await _calculateCategoryComplexity(category, transactions);

    return CategoryAnalysisData(
      categoryId: category.id,
      categoryName: category.name,
      transactionCount: transactions.length,
      totalAmount: totalAmount,
      averageAmount: averageAmount,
      lastUsed: lastUsed,
      commonKeywords: keywords.toSet().take(5).toList(),
      similarity: similarity,
    );
  }

  // Helper methods

  Future<double> _calculateCategorySimilarity(
    CategoryModel category1,
    CategoryModel category2,
    List<TransactionModel> transactions,
  ) async {
    // Simple similarity based on name and usage patterns
    double similarity = 0.0;

    // Name similarity (basic)
    if (category1.name.toLowerCase().contains(category2.name.toLowerCase()) ||
        category2.name.toLowerCase().contains(category1.name.toLowerCase())) {
      similarity += 0.3;
    }

    // Type similarity
    if (category1.type == category2.type) {
      similarity += 0.2;
    }

    // Usage pattern similarity
    final cat1Transactions = transactions.where((t) => t.categoryId == category1.id).toList();
    final cat2Transactions = transactions.where((t) => t.categoryId == category2.id).toList();

    if (cat1Transactions.isNotEmpty && cat2Transactions.isNotEmpty) {
      final avg1 = cat1Transactions.fold(0.0, (sum, t) => sum + t.amount) / cat1Transactions.length;
      final avg2 = cat2Transactions.fold(0.0, (sum, t) => sum + t.amount) / cat2Transactions.length;
      
      final difference = (avg1 - avg2).abs() / ((avg1 + avg2) / 2);
      similarity += (1.0 - difference.clamp(0.0, 1.0)) * 0.3;
    }

    // Frequency similarity
    if (cat1Transactions.length > 0 && cat2Transactions.length > 0) {
      final freq1 = cat1Transactions.length;
      final freq2 = cat2Transactions.length;
      final freqSimilarity = 1.0 - (freq1 - freq2).abs() / (freq1 + freq2);
      similarity += freqSimilarity * 0.2;
    }

    return similarity.clamp(0.0, 1.0);
  }

  String _suggestMergedName(CategoryModel category1, CategoryModel category2) {
    // Simple name merging logic
    if (category1.name.length < category2.name.length) {
      return category2.name;
    }
    return category1.name;
  }

  Future<List<String>> _analyzePotentialSplits(
    CategoryModel category,
    List<TransactionModel> transactions,
  ) async {
    final splits = <String>[];

    // Analyze by amount ranges
    final amounts = transactions.map((t) => t.amount).toList()..sort();
    if (amounts.isNotEmpty) {
      final median = amounts[amounts.length ~/ 2];
      
      if (amounts.last > median * 3) {
        splits.add('${category.name} (Nhỏ)');
        splits.add('${category.name} (Lớn)');
      }
    }

    // Analyze by time patterns
    final weekdayTransactions = transactions.where((t) => t.date.weekday <= 5).length;
    final weekendTransactions = transactions.where((t) => t.date.weekday > 5).length;
    
    if (weekdayTransactions > 0 && weekendTransactions > 0 && 
        (weekdayTransactions / weekendTransactions > 2 || weekendTransactions / weekdayTransactions > 2)) {
      splits.clear(); // Replace amount-based splits
      splits.add('${category.name} (Ngày thường)');
      splits.add('${category.name} (Cuối tuần)');
    }

    return splits;
  }

  double _calculateSplitConfidence(List<TransactionModel> transactions) {
    if (transactions.length < 10) return 0.2;
    
    final amounts = transactions.map((t) => t.amount).toList();
    final variance = _calculateVariance(amounts);
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final coefficientOfVariation = variance / mean;
    
    // Higher variation = higher confidence for split
    return (coefficientOfVariation / 2.0).clamp(0.0, 1.0);
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  Future<double> _calculateCategoryComplexity(
    CategoryModel category,
    List<TransactionModel> transactions,
  ) async {
    if (transactions.isEmpty) return 0.0;
    
    // Simple complexity based on transaction variance
    final amounts = transactions.map((t) => t.amount).toList();
    final variance = _calculateVariance(amounts);
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    
    return (variance / (mean * mean)).clamp(0.0, 1.0);
  }

  String _keywordToCategory(String keyword) {
    // Simple mapping of keywords to suggested categories
    final categoryMappings = {
      'cafe': 'Café & Cà phê',
      'grab': 'Giao hàng',
      'shopee': 'Mua sắm online',
      'cinema': 'Rạp chiếu phim',
      'gym': 'Thể thao',
      'book': 'Sách & Giáo dục',
      'medicine': 'Thuốc & Y tế',
      'pet': 'Thú cưng',
      'travel': 'Du lịch',
      'gift': 'Quà tặng',
    };

    return categoryMappings[keyword] ?? 'Danh mục mới ($keyword)';
  }

  double _calculatePotentialSavings(
    List<CategoryMergeRecommendation> merges,
    List<CategorySplitRecommendation> splits,
  ) {
    // Simple calculation - in real app this would be more sophisticated
    double savings = 0.0;
    
    // Merging categories can save management overhead
    savings += merges.length * 50000; // 50k per merge
    
    // Splitting can help identify optimization opportunities  
    savings += splits.length * 30000; // 30k per split
    
    return savings;
  }

  Future<List<TransactionModel>> _getAllTransactions() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return await _transactionService.getTransactionsByDateRange(
      sixMonthsAgo,
      DateTime.now(),
    );
  }

  CategoryOptimization _getEmptyOptimization() {
    return CategoryOptimization(
      suggestedMerges: [],
      suggestedSplits: [],
      unusedCategories: [],
      newCategorySuggestions: [],
      optimizationDate: DateTime.now(),
      potentialSavings: 0.0,
    );
  }
} 