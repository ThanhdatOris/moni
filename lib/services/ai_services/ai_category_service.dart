import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'package:moni/constants/enums.dart';

import '../core/environment_service.dart';
import 'ai_helpers.dart';
import 'ai_response_cache.dart';
import 'ai_token_manager.dart';

/// Handles category suggestions for transactions
/// - Single category suggestion with cache
/// - Batch category suggestions for bulk operations
/// - Smart caching with 7-day TTL
class AICategoryService {
  final GenerativeModel _model;
  final Logger _logger = Logger();
  final AIResponseCache _cache;
  final AITokenManager _tokenManager;

  AICategoryService({
    required GenerativeModel model,
    required AIResponseCache cache,
    required AITokenManager tokenManager,
  })  : _model = model,
        _cache = cache,
        _tokenManager = tokenManager;

  /// Suggest category for a single transaction description
  Future<String> suggestCategory(String description) async {
    // Check smart cache first
    final cacheKey = 'category:${description.toLowerCase().trim()}';
    final cached = _cache.get(cacheKey, CachePriority.high);
    if (cached != null) {
      if (EnvironmentService.debugMode) {
        _logger.d('📁 Smart cache hit for category: $description');
      }
      return cached;
    }

    try {
      _logger.i('🤔 Suggesting category for: "$description"');

      final prompt = '''
Suggest best category for transaction: "$description"
Return Vietnamese category name only: "Ăn uống", "Mua sắm", "Đi lại", "Giải trí", "Lương", etc.
''';

      // Check usage before API call
      await AIHelpers.checkUsageBeforeCall(_tokenManager, prompt);

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text?.trim() ?? 'Khác';

      // Update token usage after API call
      await AIHelpers.updateUsageAfterCall(_tokenManager, prompt, result);

      // Save to smart cache (7 days TTL)
      _cache.put(cacheKey, result, CachePriority.high);
      await _cache.saveToDisk(); // Persist immediately

      if (EnvironmentService.debugMode) {
        _logger.d('✅ Category suggested: "$result" for "$description"');
      }
      return result;
    } catch (e) {
      _logger.e('❌ Error suggesting category: $e');
      return 'Ăn uống'; // Default fallback category
    }
  }

  /// Batch category suggestions to reduce API calls
  /// Use this when importing multiple transactions or batch processing
  /// Returns Map\<description, category>
  Future<Map<String, String>> suggestCategoriesBatch(
      List<String> descriptions) async {
    if (descriptions.isEmpty) return {};

    // Check smart cache first
    final Map<String, String> results = {};
    final List<String> uncachedDescriptions = [];

    for (final desc in descriptions) {
      final cacheKey = 'category:${desc.toLowerCase().trim()}';
      final cached = _cache.get(cacheKey, CachePriority.high);
      if (cached != null) {
        results[desc] = cached;
      } else {
        uncachedDescriptions.add(desc);
      }
    }

    if (uncachedDescriptions.isEmpty) {
      _logger.d('📁 All ${descriptions.length} categories from smart cache');
      return results;
    }

    try {
      _logger.i(
          '🤔 Batch suggesting categories for ${uncachedDescriptions.length} transactions');

      // Build batch prompt
      final indexedDescriptions = uncachedDescriptions
          .asMap()
          .entries
          .map((e) => '${e.key}: "${e.value}"')
          .join('\n');

      final prompt = '''
Suggest best Vietnamese category for each transaction.
Return ONLY valid JSON object mapping index to category name.

Transactions:
$indexedDescriptions

Valid categories: "Ăn uống", "Mua sắm", "Đi lại", "Giải trí", "Y tế", "Học tập", "Hóa đơn", "Lương", "Đầu tư", "Thưởng", "Freelance", "Bán hàng", "Khác"

Response format: {"0": "Ăn uống", "1": "Đi lại", ...}
''';

      // Check usage before API call
      await AIHelpers.checkUsageBeforeCall(_tokenManager, prompt);

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text?.trim() ?? '{}';

      // Update token usage after API call
      await AIHelpers.updateUsageAfterCall(_tokenManager, prompt, responseText);

      // Parse JSON response
      try {
        // Extract JSON from markdown code blocks if present
        final jsonMatch = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```')
            .firstMatch(responseText);
        final jsonString = jsonMatch?.group(1) ?? responseText;

        final Map<String, dynamic> parsed = jsonDecode(jsonString);

        // Map results back to descriptions
        for (var i = 0; i < uncachedDescriptions.length; i++) {
          final category = parsed[i.toString()]?.toString() ?? 'Khác';
          results[uncachedDescriptions[i]] = category;

          // Cache individual results to smart cache
          final cacheKey =
              'category:${uncachedDescriptions[i].toLowerCase().trim()}';
          _cache.put(cacheKey, category, CachePriority.high);
        }

        // Persist cache after batch operation
        await _cache.saveToDisk();

        _logger.d(
            '✅ Batch suggested ${uncachedDescriptions.length} categories');
      } catch (e) {
        _logger.e('❌ Error parsing batch response: $e');
        // Fallback to defaults
        for (final desc in uncachedDescriptions) {
          results[desc] = 'Ăn uống';
        }
      }

      return results;
    } catch (e) {
      _logger.e('❌ Error in batch category suggestion: $e');
      // Fallback to defaults
      for (final desc in uncachedDescriptions) {
        results[desc] = 'Ăn uống';
      }
      return results;
    }
  }
}
