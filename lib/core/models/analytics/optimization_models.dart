/// Models cho tối ưu hóa danh mục
/// Được tách từ AIAnalyticsService để cải thiện maintainability

/// Kết quả tối ưu hóa danh mục tổng quan
class CategoryOptimization {
  final List<CategoryMergeRecommendation> suggestedMerges;
  final List<CategorySplitRecommendation> suggestedSplits;
  final List<String> unusedCategories;
  final List<String> newCategorySuggestions;
  final DateTime optimizationDate;
  final double potentialSavings;

  const CategoryOptimization({
    required this.suggestedMerges,
    required this.suggestedSplits,
    required this.unusedCategories,
    required this.newCategorySuggestions,
    required this.optimizationDate,
    required this.potentialSavings,
  });

  /// Convert to JSON for API/Firebase
  Map<String, dynamic> toJson() {
    return {
      'suggestedMerges': suggestedMerges.map((e) => e.toJson()).toList(),
      'suggestedSplits': suggestedSplits.map((e) => e.toJson()).toList(),
      'unusedCategories': unusedCategories,
      'newCategorySuggestions': newCategorySuggestions,
      'optimizationDate': optimizationDate.toIso8601String(),
      'potentialSavings': potentialSavings,
    };
  }

  /// Create from JSON
  factory CategoryOptimization.fromJson(Map<String, dynamic> json) {
    return CategoryOptimization(
      suggestedMerges: (json['suggestedMerges'] as List)
          .map((e) => CategoryMergeRecommendation.fromJson(e))
          .toList(),
      suggestedSplits: (json['suggestedSplits'] as List)
          .map((e) => CategorySplitRecommendation.fromJson(e))
          .toList(),
      unusedCategories: List<String>.from(json['unusedCategories']),
      newCategorySuggestions: List<String>.from(json['newCategorySuggestions']),
      optimizationDate: DateTime.parse(json['optimizationDate']),
      potentialSavings: json['potentialSavings'].toDouble(),
    );
  }

  /// Get total number of recommendations
  int get totalRecommendations =>
      suggestedMerges.length + suggestedSplits.length + unusedCategories.length + newCategorySuggestions.length;

  /// Check if optimization is needed
  bool get needsOptimization => totalRecommendations > 0;

  /// Get optimization priority level
  String get optimizationPriority {
    if (unusedCategories.length >= 5 || suggestedMerges.length >= 3) return 'Cao';
    if (totalRecommendations >= 3) return 'Trung bình';
    if (totalRecommendations > 0) return 'Thấp';
    return 'Không cần';
  }

  /// Get optimization impact description
  String get optimizationImpact {
    if (potentialSavings >= 1000000) return 'Tác động lớn'; // >= 1M
    if (potentialSavings >= 500000) return 'Tác động trung bình'; // >= 500k
    if (potentialSavings >= 100000) return 'Tác động nhỏ'; // >= 100k
    return 'Tác động rất nhỏ';
  }

  /// Get high confidence recommendations
  List<CategoryMergeRecommendation> get highConfidenceMerges =>
      suggestedMerges.where((m) => m.confidence >= 0.7).toList();

  List<CategorySplitRecommendation> get highConfidenceSplits =>
      suggestedSplits.where((s) => s.confidence >= 0.7).toList();

  /// Get actionable recommendations summary
  Map<String, int> get actionableSummary => {
    'merges': highConfidenceMerges.length,
    'splits': highConfidenceSplits.length,
    'unused': unusedCategories.length,
    'new': newCategorySuggestions.length,
  };
}

/// Gợi ý gộp danh mục
class CategoryMergeRecommendation {
  final List<String> categoryIds;
  final String suggestedName;
  final String reason;
  final double confidence; // 0.0 - 1.0

  const CategoryMergeRecommendation({
    required this.categoryIds,
    required this.suggestedName,
    required this.reason,
    required this.confidence,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categoryIds': categoryIds,
      'suggestedName': suggestedName,
      'reason': reason,
      'confidence': confidence,
    };
  }

  /// Create from JSON
  factory CategoryMergeRecommendation.fromJson(Map<String, dynamic> json) {
    return CategoryMergeRecommendation(
      categoryIds: List<String>.from(json['categoryIds']),
      suggestedName: json['suggestedName'],
      reason: json['reason'],
      confidence: json['confidence'].toDouble(),
    );
  }

  /// Get confidence level as text
  String get confidenceLevel {
    if (confidence >= 0.8) return 'Rất cao';
    if (confidence >= 0.6) return 'Cao';
    if (confidence >= 0.4) return 'Trung bình';
    return 'Thấp';
  }

  /// Get confidence color
  int get confidenceColor {
    if (confidence >= 0.8) return 0xFF4CAF50; // Green
    if (confidence >= 0.6) return 0xFF8BC34A; // Light Green
    if (confidence >= 0.4) return 0xFFFF9800; // Orange
    return 0xFFFF5722; // Deep Orange
  }

  /// Get number of categories being merged
  int get categoryCount => categoryIds.length;

  /// Check if this is a high priority merge
  bool get isHighPriority => confidence >= 0.7 && categoryCount >= 2;

  /// Get merge complexity level
  String get complexityLevel {
    if (categoryCount >= 5) return 'Phức tạp';
    if (categoryCount >= 3) return 'Trung bình';
    return 'Đơn giản';
  }

  /// Get recommended action text
  String get actionText => 'Gộp ${categoryCount} danh mục thành "$suggestedName"';

  /// Get impact estimate
  String get estimatedImpact {
    if (categoryCount >= 5) return 'Giảm đáng kể độ phức tạp';
    if (categoryCount >= 3) return 'Cải thiện tổ chức';
    return 'Tối ưu nhẹ';
  }
}

/// Gợi ý tách danh mục
class CategorySplitRecommendation {
  final String categoryId;
  final List<String> suggestedSplits;
  final String reason;
  final double confidence; // 0.0 - 1.0

  const CategorySplitRecommendation({
    required this.categoryId,
    required this.suggestedSplits,
    required this.reason,
    required this.confidence,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'suggestedSplits': suggestedSplits,
      'reason': reason,
      'confidence': confidence,
    };
  }

  /// Create from JSON
  factory CategorySplitRecommendation.fromJson(Map<String, dynamic> json) {
    return CategorySplitRecommendation(
      categoryId: json['categoryId'],
      suggestedSplits: List<String>.from(json['suggestedSplits']),
      reason: json['reason'],
      confidence: json['confidence'].toDouble(),
    );
  }

  /// Get confidence level as text
  String get confidenceLevel {
    if (confidence >= 0.8) return 'Rất cao';
    if (confidence >= 0.6) return 'Cao';
    if (confidence >= 0.4) return 'Trung bình';
    return 'Thấp';
  }

  /// Get confidence color
  int get confidenceColor {
    if (confidence >= 0.8) return 0xFF4CAF50; // Green
    if (confidence >= 0.6) return 0xFF8BC34A; // Light Green
    if (confidence >= 0.4) return 0xFFFF9800; // Orange
    return 0xFFFF5722; // Deep Orange
  }

  /// Get number of suggested splits
  int get splitCount => suggestedSplits.length;

  /// Check if this is a high priority split
  bool get isHighPriority => confidence >= 0.7 && splitCount >= 2;

  /// Get split complexity level
  String get complexityLevel {
    if (splitCount >= 5) return 'Phức tạp';
    if (splitCount >= 3) return 'Trung bình';
    return 'Đơn giản';
  }

  /// Get recommended action text
  String get actionText => 'Tách thành ${splitCount} danh mục: ${suggestedSplits.join(", ")}';

  /// Get impact estimate
  String get estimatedImpact {
    if (splitCount >= 5) return 'Tăng đáng kể độ chi tiết';
    if (splitCount >= 3) return 'Cải thiện phân loại';
    return 'Tối ưu nhẹ';
  }

  /// Get split preview text
  String get splitPreview {
    if (suggestedSplits.length <= 3) {
      return suggestedSplits.join(' + ');
    }
    return '${suggestedSplits.take(2).join(' + ')} + ${suggestedSplits.length - 2} khác';
  }
}

/// Model dữ liệu để phân tích và tối ưu hóa danh mục
class CategoryAnalysisData {
  final String categoryId;
  final String categoryName;
  final int transactionCount;
  final double totalAmount;
  final double averageAmount;
  final DateTime lastUsed;
  final List<String> commonKeywords;
  final double similarity; // Similarity to other categories (0.0 - 1.0)

  const CategoryAnalysisData({
    required this.categoryId,
    required this.categoryName,
    required this.transactionCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.lastUsed,
    required this.commonKeywords,
    required this.similarity,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'transactionCount': transactionCount,
      'totalAmount': totalAmount,
      'averageAmount': averageAmount,
      'lastUsed': lastUsed.toIso8601String(),
      'commonKeywords': commonKeywords,
      'similarity': similarity,
    };
  }

  /// Create from JSON
  factory CategoryAnalysisData.fromJson(Map<String, dynamic> json) {
    return CategoryAnalysisData(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      transactionCount: json['transactionCount'],
      totalAmount: json['totalAmount'].toDouble(),
      averageAmount: json['averageAmount'].toDouble(),
      lastUsed: DateTime.parse(json['lastUsed']),
      commonKeywords: List<String>.from(json['commonKeywords']),
      similarity: json['similarity'].toDouble(),
    );
  }

  /// Check if category is unused (no transactions in last 3 months)
  bool get isUnused {
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    return lastUsed.isBefore(threeMonthsAgo) || transactionCount == 0;
  }

  /// Check if category has low usage (less than 3 transactions)
  bool get hasLowUsage => transactionCount < 3;

  /// Check if category is similar to others (high similarity score)
  bool get hasHighSimilarity => similarity >= 0.8;

  /// Get usage frequency level
  String get usageFrequency {
    if (transactionCount >= 50) return 'Rất cao';
    if (transactionCount >= 20) return 'Cao';
    if (transactionCount >= 10) return 'Trung bình';
    if (transactionCount >= 3) return 'Thấp';
    return 'Rất thấp';
  }

  /// Get category health score (0.0 - 1.0)
  double get healthScore {
    double score = 0.0;
    
    // Usage frequency (40% weight)
    if (transactionCount >= 10) score += 0.4;
    else score += (transactionCount / 10) * 0.4;
    
    // Recency (30% weight)
    final daysSinceLastUsed = DateTime.now().difference(lastUsed).inDays;
    if (daysSinceLastUsed <= 30) score += 0.3;
    else if (daysSinceLastUsed <= 90) score += 0.15;
    
    // Uniqueness (30% weight)
    score += (1.0 - similarity) * 0.3;
    
    return score.clamp(0.0, 1.0);
  }

  /// Get health status
  String get healthStatus {
    final health = healthScore;
    if (health >= 0.8) return 'Xuất sắc';
    if (health >= 0.6) return 'Tốt';
    if (health >= 0.4) return 'Trung bình';
    if (health >= 0.2) return 'Kém';
    return 'Rất kém';
  }

  /// Get health color
  int get healthColor {
    final health = healthScore;
    if (health >= 0.8) return 0xFF4CAF50; // Green
    if (health >= 0.6) return 0xFF8BC34A; // Light Green
    if (health >= 0.4) return 0xFFFF9800; // Orange
    if (health >= 0.2) return 0xFFFF5722; // Deep Orange
    return 0xFFD32F2F; // Red
  }

  /// Get days since last use
  int get daysSinceLastUsed => DateTime.now().difference(lastUsed).inDays;

  /// Get keywords summary (first 3 keywords)
  String get keywordsSummary {
    if (commonKeywords.isEmpty) return 'Không có từ khóa';
    if (commonKeywords.length <= 3) return commonKeywords.join(', ');
    return '${commonKeywords.take(3).join(', ')}...';
  }
} 