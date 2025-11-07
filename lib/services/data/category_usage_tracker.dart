import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

/// Service theo dõi usage của categories để đưa ra smart suggestions
class CategoryUsageTracker {
  static const String _keyUsageData = 'category_usage_data';
  static const String _keyRecentCategories = 'recent_categories';
  static const int _maxRecentCategories = 10;

  static final CategoryUsageTracker _instance =
      CategoryUsageTracker._internal();
  factory CategoryUsageTracker() => _instance;
  CategoryUsageTracker._internal();

  SharedPreferences? _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize tracker
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Track category usage khi user tạo transaction
  Future<void> trackCategoryUsage({
    required String categoryId,
    required String categoryName,
    required TransactionType transactionType,
    required double amount,
    required DateTime timestamp,
  }) async {
    await initialize();

    // Update usage statistics
    await _updateUsageStatistics(
        categoryId, categoryName, transactionType, amount);

    // Update recent categories
    await _updateRecentCategories(
        categoryId, categoryName, transactionType, timestamp);

    // Đồng bộ Firestore tổng hợp usage
    final user = _auth.currentUser;
    if (user != null) {
      final key = '${categoryId}_${transactionType.value}';
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('category_usage')
          .doc(key);

      await docRef.set({
        'categoryId': categoryId,
        'categoryName': categoryName,
        'type': transactionType.value,
        'count': FieldValue.increment(1),
        'totalAmount': FieldValue.increment(amount),
        'lastUsed': Timestamp.fromDate(timestamp),
      }, SetOptions(merge: true));

      final hour = timestamp.hour.toString();
      await docRef.set({
        'hourlyUsage.$hour': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
  }

  /// Get suggested categories based on usage patterns
  Future<List<CategorySuggestion>> getSuggestedCategories({
    required TransactionType transactionType,
    required List<CategoryModel> availableCategories,
    String? transactionNote,
    DateTime? transactionTime,
  }) async {
    await initialize();

    final suggestions = <CategorySuggestion>[];

    // 1. Recent categories (highest priority)
    final recentSuggestions = await _getRecentCategorySuggestions(
      transactionType,
      availableCategories,
    );
    suggestions.addAll(recentSuggestions);

    // 2. Most used categories
    final usageSuggestions = await _getMostUsedCategorySuggestions(
      transactionType,
      availableCategories,
    );
    suggestions.addAll(usageSuggestions);

    // 3. Time-based suggestions
    if (transactionTime != null) {
      final timeSuggestions = await _getTimeBasedSuggestions(
        transactionType,
        availableCategories,
        transactionTime,
      );
      suggestions.addAll(timeSuggestions);
    }

    // 4. Note-based suggestions
    if (transactionNote != null && transactionNote.isNotEmpty) {
      final noteSuggestions = await _getNoteBasedSuggestions(
        transactionType,
        availableCategories,
        transactionNote,
      );
      suggestions.addAll(noteSuggestions);
    }

    // Remove duplicates và sort by confidence
    final uniqueSuggestions = _removeDuplicatesAndSort(suggestions);

    return uniqueSuggestions.take(5).toList();
  }

  /// Get recent categories for quick access
  Future<List<CategoryModel>> getRecentCategories({
    required TransactionType transactionType,
    required List<CategoryModel> availableCategories,
  }) async {
    await initialize();

    final recentData = _prefs?.getString(_keyRecentCategories);
    if (recentData == null) return [];

    try {
      final List<dynamic> recentList = jsonDecode(recentData);
      final recentCategories = <CategoryModel>[];

      for (final item in recentList) {
        final data = item as Map<String, dynamic>;
        if (data['type'] == transactionType.value) {
          final category = availableCategories.firstWhere(
            (cat) => cat.categoryId == data['categoryId'],
            orElse: () => CategoryModel(
              categoryId: '',
              userId: '',
              name: '',
              type: transactionType,
              icon: '',
              color: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          if (category.categoryId.isNotEmpty) {
            recentCategories.add(category);
          }
        }
      }

      return recentCategories;
    } catch (e) {
      return [];
    }
  }

  /// Update usage statistics
  Future<void> _updateUsageStatistics(
    String categoryId,
    String categoryName,
    TransactionType transactionType,
    double amount,
  ) async {
    final usageData = _prefs?.getString(_keyUsageData);
    Map<String, dynamic> usage = {};

    if (usageData != null) {
      try {
        usage = jsonDecode(usageData);
      } catch (e) {
        // Invalid data, start fresh
        usage = {};
      }
    }

    final key = '${categoryId}_${transactionType.value}';
    final currentUsage = usage[key] as Map<String, dynamic>? ?? {};

    // Update statistics
    currentUsage['categoryId'] = categoryId;
    currentUsage['categoryName'] = categoryName;
    currentUsage['type'] = transactionType.value;
    currentUsage['count'] = (currentUsage['count'] as int? ?? 0) + 1;
    currentUsage['totalAmount'] =
        (currentUsage['totalAmount'] as double? ?? 0.0) + amount;
    currentUsage['lastUsed'] = DateTime.now().millisecondsSinceEpoch;

    // Track hourly usage for time-based suggestions
    final hour = DateTime.now().hour;
    final hourlyUsage =
        currentUsage['hourlyUsage'] as Map<String, dynamic>? ?? {};
    hourlyUsage[hour.toString()] =
        (hourlyUsage[hour.toString()] as int? ?? 0) + 1;
    currentUsage['hourlyUsage'] = hourlyUsage;

    usage[key] = currentUsage;

    await _prefs?.setString(_keyUsageData, jsonEncode(usage));
  }

  /// Update recent categories list
  Future<void> _updateRecentCategories(
    String categoryId,
    String categoryName,
    TransactionType transactionType,
    DateTime timestamp,
  ) async {
    final recentData = _prefs?.getString(_keyRecentCategories);
    List<dynamic> recentList = [];

    if (recentData != null) {
      try {
        recentList = jsonDecode(recentData);
      } catch (e) {
        recentList = [];
      }
    }

    // Remove existing entry if exists
    recentList.removeWhere((item) =>
        item['categoryId'] == categoryId &&
        item['type'] == transactionType.value);

    // Add to front
    recentList.insert(0, {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'type': transactionType.value,
      'timestamp': timestamp.millisecondsSinceEpoch,
    });

    // Keep only max recent categories
    if (recentList.length > _maxRecentCategories) {
      recentList = recentList.take(_maxRecentCategories).toList();
    }

    await _prefs?.setString(_keyRecentCategories, jsonEncode(recentList));
  }

  /// Get recent category suggestions
  Future<List<CategorySuggestion>> _getRecentCategorySuggestions(
    TransactionType transactionType,
    List<CategoryModel> availableCategories,
  ) async {
    final recentCategories = await getRecentCategories(
      transactionType: transactionType,
      availableCategories: availableCategories,
    );

    return recentCategories
        .map((category) => CategorySuggestion(
              category: category,
              confidence: 0.9, // High confidence for recent categories
              reason: 'Gần đây đã sử dụng',
            ))
        .toList();
  }

  /// Get most used category suggestions
  Future<List<CategorySuggestion>> _getMostUsedCategorySuggestions(
    TransactionType transactionType,
    List<CategoryModel> availableCategories,
  ) async {
    final usageData = _prefs?.getString(_keyUsageData);
    if (usageData == null) return [];

    try {
      final Map<String, dynamic> usage = jsonDecode(usageData);
      final suggestions = <CategorySuggestion>[];

      for (final entry in usage.entries) {
        final data = entry.value as Map<String, dynamic>;
        if (data['type'] == transactionType.value) {
          final category = availableCategories.firstWhere(
            (cat) => cat.categoryId == data['categoryId'],
            orElse: () => CategoryModel(
              categoryId: '',
              userId: '',
              name: '',
              type: transactionType,
              icon: '',
              color: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          if (category.categoryId.isNotEmpty) {
            final count = data['count'] as int;
            final confidence =
                (count / 50).clamp(0.1, 0.8); // Max 0.8 confidence

            suggestions.add(CategorySuggestion(
              category: category,
              confidence: confidence,
              reason: 'Sử dụng nhiều ($count lần)',
            ));
          }
        }
      }

      return suggestions;
    } catch (e) {
      return [];
    }
  }

  /// Get time-based suggestions
  Future<List<CategorySuggestion>> _getTimeBasedSuggestions(
    TransactionType transactionType,
    List<CategoryModel> availableCategories,
    DateTime transactionTime,
  ) async {
    final usageData = _prefs?.getString(_keyUsageData);
    if (usageData == null) return [];

    try {
      final Map<String, dynamic> usage = jsonDecode(usageData);
      final suggestions = <CategorySuggestion>[];
      final currentHour = transactionTime.hour;

      for (final entry in usage.entries) {
        final data = entry.value as Map<String, dynamic>;
        if (data['type'] == transactionType.value) {
          final hourlyUsage = data['hourlyUsage'] as Map<String, dynamic>?;
          if (hourlyUsage != null) {
            final hourUsage = hourlyUsage[currentHour.toString()] as int? ?? 0;
            if (hourUsage > 0) {
              final category = availableCategories.firstWhere(
                (cat) => cat.categoryId == data['categoryId'],
                orElse: () => CategoryModel(
                  categoryId: '',
                  userId: '',
                  name: '',
                  type: transactionType,
                  icon: '',
                  color: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

              if (category.categoryId.isNotEmpty) {
                final confidence = (hourUsage / 10).clamp(0.1, 0.7);
                suggestions.add(CategorySuggestion(
                  category: category,
                  confidence: confidence,
                  reason: 'Thường dùng vào ${_getTimeDescription(currentHour)}',
                ));
              }
            }
          }
        }
      }

      return suggestions;
    } catch (e) {
      return [];
    }
  }

  /// Get note-based suggestions
  Future<List<CategorySuggestion>> _getNoteBasedSuggestions(
    TransactionType transactionType,
    List<CategoryModel> availableCategories,
    String transactionNote,
  ) async {
    final suggestions = <CategorySuggestion>[];
    final noteWords = transactionNote.toLowerCase().split(' ');

    // Simple keyword matching
    final categoryKeywords = {
      'restaurant': [
        'cơm',
        'phở',
        'bún',
        'bánh',
        'cafe',
        'coffee',
        'restaurant',
        'ăn'
      ],
      'shopping_cart': ['mua', 'shop', 'store', 'market', 'siêu thị'],
      'directions_car': ['xăng', 'gas', 'xe', 'taxi', 'grab', 'uber'],
      'movie': ['phim', 'cinema', 'movie', 'xem'],
      'receipt': ['hóa đơn', 'bill', 'payment', 'thanh toán'],
      'work': ['lương', 'salary', 'bonus', 'work', 'công việc'],
    };

    for (final category in availableCategories) {
      if (category.type == transactionType) {
        final keywords = categoryKeywords[category.icon] ?? [];
        var matchCount = 0;

        for (final keyword in keywords) {
          if (noteWords.any((word) => word.contains(keyword))) {
            matchCount++;
          }
        }

        if (matchCount > 0) {
          final confidence = (matchCount / keywords.length).clamp(0.1, 0.8);
          suggestions.add(CategorySuggestion(
            category: category,
            confidence: confidence,
            reason: 'Phù hợp với ghi chú',
          ));
        }
      }
    }

    return suggestions;
  }

  /// Remove duplicates and sort by confidence
  List<CategorySuggestion> _removeDuplicatesAndSort(
      List<CategorySuggestion> suggestions) {
    final Map<String, CategorySuggestion> uniqueSuggestions = {};

    for (final suggestion in suggestions) {
      final key = suggestion.category.categoryId;
      final existing = uniqueSuggestions[key];

      if (existing == null || suggestion.confidence > existing.confidence) {
        uniqueSuggestions[key] = suggestion;
      }
    }

    final result = uniqueSuggestions.values.toList();
    result.sort((a, b) => b.confidence.compareTo(a.confidence));

    return result;
  }

  /// Get time description for display
  String _getTimeDescription(int hour) {
    if (hour >= 6 && hour < 12) return 'buổi sáng';
    if (hour >= 12 && hour < 18) return 'buổi chiều';
    if (hour >= 18 && hour < 22) return 'buổi tối';
    return 'buổi đêm';
  }

  /// Clear all usage data
  Future<void> clearUsageData() async {
    await initialize();
    await _prefs?.remove(_keyUsageData);
    await _prefs?.remove(_keyRecentCategories);
  }
}

/// Category suggestion với confidence score
class CategorySuggestion {
  final CategoryModel category;
  final double confidence;
  final String reason;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reason,
  });
}
