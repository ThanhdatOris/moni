import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Service quản lý transaction templates
class TransactionTemplateService {
  static const String _templatesKey = 'transaction_templates';
  static const String _usageKey = 'template_usage';
  static const int _maxTemplates = 10;

  final Logger _logger = Logger();

  /// Lưu template mới
  Future<void> saveTemplate(TransactionTemplate template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templates = await getTemplates();
      
      // Kiểm tra xem template đã tồn tại chưa
      final existingIndex = templates.indexWhere((t) => 
        t.name.toLowerCase() == template.name.toLowerCase());
      
      if (existingIndex >= 0) {
        // Cập nhật template hiện tại
        templates[existingIndex] = template;
      } else {
        // Thêm template mới
        templates.add(template);
        
        // Giới hạn số lượng templates
        if (templates.length > _maxTemplates) {
          templates.removeAt(0);
        }
      }
      
      // Lưu vào SharedPreferences
      final templatesJson = templates.map((t) => t.toJson()).toList();
      await prefs.setString(_templatesKey, jsonEncode(templatesJson));
    } catch (e) {
      _logger.e('Error saving template: $e');
    }
  }

  /// Lấy danh sách templates
  Future<List<TransactionTemplate>> getTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesString = prefs.getString(_templatesKey);
      
      if (templatesString == null) return [];
      
      final templatesJson = jsonDecode(templatesString) as List;
      return templatesJson
          .map((json) => TransactionTemplate.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Error loading templates: $e');
      return [];
    }
  }

  /// Xóa template
  Future<void> deleteTemplate(String templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templates = await getTemplates();
      
      templates.removeWhere((t) => t.id == templateId);
      
      final templatesJson = templates.map((t) => t.toJson()).toList();
      await prefs.setString(_templatesKey, jsonEncode(templatesJson));
    } catch (e) {
      _logger.e('Error deleting template: $e');
    }
  }

  /// Tăng số lần sử dụng template
  Future<void> incrementTemplateUsage(String templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usage = await getTemplateUsage();
      
      final currentUsage = usage[templateId] ?? 0;
      usage[templateId] = currentUsage + 1;
      
      await prefs.setString(_usageKey, jsonEncode(usage));
    } catch (e) {
      _logger.e('Error incrementing template usage: $e');
    }
  }

  /// Lấy thống kê sử dụng template
  Future<Map<String, int>> getTemplateUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usageString = prefs.getString(_usageKey);
      
      if (usageString == null) return {};
      
      final usageJson = jsonDecode(usageString) as Map<String, dynamic>;
      return usageJson.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      _logger.e('Error loading template usage: $e');
      return {};
    }
  }

  /// Lấy templates phổ biến nhất
  Future<List<TransactionTemplate>> getPopularTemplates({int limit = 5}) async {
    try {
      final templates = await getTemplates();
      final usage = await getTemplateUsage();
      
      // Sắp xếp templates theo số lần sử dụng
      templates.sort((a, b) {
        final usageA = usage[a.id] ?? 0;
        final usageB = usage[b.id] ?? 0;
        return usageB.compareTo(usageA);
      });
      
      return templates.take(limit).toList();
    } catch (e) {
      _logger.e('Error getting popular templates: $e');
      return [];
    }
  }

  /// Tạo template từ transaction
  Future<TransactionTemplate> createTemplateFromTransaction({
    required String name,
    required TransactionType type,
    required double amount,
    required CategoryModel category,
    required String note,
  }) async {
    return TransactionTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      amount: amount,
      categoryId: category.id,
      categoryName: category.name,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  /// Tự động tạo template từ transaction thường xuyên
  Future<List<TransactionTemplate>> suggestTemplatesFromFrequentTransactions(
    List<TransactionModel> recentTransactions,
  ) async {
    try {
      final suggestions = <TransactionTemplate>[];
      final transactionPatterns = <String, List<TransactionModel>>{};
      
      // Nhóm transactions theo pattern (amount + category)
      for (final transaction in recentTransactions) {
        final pattern = '${transaction.amount}_${transaction.categoryId}';
        transactionPatterns[pattern] ??= [];
        transactionPatterns[pattern]!.add(transaction);
      }
      
      // Tìm patterns xuất hiện >= 3 lần
      for (final entry in transactionPatterns.entries) {
        if (entry.value.length >= 3) {
          final firstTransaction = entry.value.first;
          final templateName = _generateTemplateName(firstTransaction);
          
          final template = TransactionTemplate(
            id: 'auto_${entry.key}',
            name: templateName,
            type: firstTransaction.type,
            amount: firstTransaction.amount,
            categoryId: firstTransaction.categoryId,
            categoryName: firstTransaction.categoryName ?? 'Không rõ',
            note: firstTransaction.note ?? '',
            createdAt: DateTime.now(),
            isAutoGenerated: true,
          );
          
          suggestions.add(template);
        }
      }
      
      return suggestions;
    } catch (e) {
      _logger.e('Error suggesting templates: $e');
      return [];
    }
  }

  String _generateTemplateName(TransactionModel transaction) {
    final note = transaction.note ?? '';
    if (note.isNotEmpty) {
      return note;
    }
    
    final typeText = transaction.type == TransactionType.expense ? 'Chi' : 'Thu';
    final categoryName = transaction.categoryName ?? 'Không rõ';
    return '$typeText $categoryName';
  }

  /// Làm sạch templates cũ
  Future<void> cleanupOldTemplates() async {
    try {
      final templates = await getTemplates();
      final now = DateTime.now();
      
      // Xóa templates không được sử dụng trong 30 ngày
      final activeTemplates = templates.where((template) {
        final daysSinceCreated = now.difference(template.createdAt).inDays;
        return daysSinceCreated <= 30;
      }).toList();
      
      if (activeTemplates.length != templates.length) {
        final prefs = await SharedPreferences.getInstance();
        final templatesJson = activeTemplates.map((t) => t.toJson()).toList();
        await prefs.setString(_templatesKey, jsonEncode(templatesJson));
      }
    } catch (e) {
      _logger.e('Error cleaning up templates: $e');
    }
  }
}

/// Model cho Transaction Template
class TransactionTemplate {
  final String id;
  final String name;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String note;
  final DateTime createdAt;
  final bool isAutoGenerated;

  TransactionTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.note,
    required this.createdAt,
    this.isAutoGenerated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'isAutoGenerated': isAutoGenerated,
    };
  }

  factory TransactionTemplate.fromJson(Map<String, dynamic> json) {
    return TransactionTemplate(
      id: json['id'],
      name: json['name'],
      type: TransactionType.values.firstWhere(
        (type) => type.toString() == json['type'],
      ),
      amount: json['amount'].toDouble(),
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      isAutoGenerated: json['isAutoGenerated'] ?? false,
    );
  }

  TransactionTemplate copyWith({
    String? id,
    String? name,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? note,
    DateTime? createdAt,
    bool? isAutoGenerated,
  }) {
    return TransactionTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      isAutoGenerated: isAutoGenerated ?? this.isAutoGenerated,
    );
  }
}
