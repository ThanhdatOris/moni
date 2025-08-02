import 'dart:math';
import 'package:uuid/uuid.dart';
/// Anomaly Detector - Chuyên phát hiện bất thường trong chi tiêu
/// Migrated from lib/services/analytics/ để tăng tính modularity

import '../../../../../core/models/analytics/analytics_models.dart';
import '../../../../../models/transaction_model.dart';
import '../../../../../services/base_service.dart';
import '../../../../../services/offline_service.dart';
import '../../../../../services/transaction_service.dart';

/// Service chuyên phát hiện các bất thường trong mẫu chi tiêu
class AnomalyDetector extends BaseService {
  static final AnomalyDetector _instance = AnomalyDetector._internal();
  factory AnomalyDetector() => _instance;
  AnomalyDetector._internal();

  late final TransactionService _transactionService;
  final _uuid = const Uuid();

  /// Initialize services (call this before using)
  void _initializeServices() {
    final offlineService = OfflineService();
    _transactionService = TransactionService(offlineService: offlineService);
  }

  /// Main method: Detect advanced anomalies in spending patterns
  Future<List<SpendingAnomaly>> detectAdvancedAnomalies() async {
    try {
      if (currentUserId == null) return [];

      _initializeServices();
      logInfo('Detecting advanced anomalies');

      final transactions = await _getAllTransactions();
      final anomalies = <SpendingAnomaly>[];

      // Run different anomaly detection algorithms in parallel
      final futures = await Future.wait([
        _detectStatisticalAnomalies(transactions),
        _detectBehavioralAnomalies(transactions),
        _detectTemporalAnomalies(transactions),
        _detectCategoryAnomalies(transactions),
      ]);

      // Combine all anomalies
      for (final anomalyList in futures) {
        anomalies.addAll(anomalyList);
      }

      // Sort by severity and confidence
      anomalies.sort((a, b) {
        final severityOrder = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1};
        final aSeverity = severityOrder[a.severity] ?? 0;
        final bSeverity = severityOrder[b.severity] ?? 0;
        
        if (aSeverity != bSeverity) {
          return bSeverity.compareTo(aSeverity);
        }
        return b.confidence.compareTo(a.confidence);
      });

      logInfo('Detected ${anomalies.length} anomalies');
      return anomalies.take(20).toList(); // Return top 20 anomalies
    } catch (e) {
      logError('Error detecting anomalies', e);
      return [];
    }
  }

  /// Get recent anomalies (last N days)
  Future<List<SpendingAnomaly>> getRecentAnomalies({int days = 7}) async {
    try {
      _initializeServices();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final transactions = await _getRecentTransactions(days: days);
      
      final anomalies = await _detectQuickAnomalies(transactions);
      
      // Filter by detection date
      return anomalies.where((a) => a.detectedAt.isAfter(cutoffDate)).toList();
    } catch (e) {
      logError('Error getting recent anomalies', e);
      return [];
    }
  }

  /// Get anomalies for specific category
  Future<List<SpendingAnomaly>> getCategoryAnomalies(String categoryId) async {
    try {
      _initializeServices();
      final transactions = await _getAllTransactions();
      final categoryTransactions = transactions
          .where((t) => t.categoryId == categoryId)
          .toList();

      return await _detectCategorySpecificAnomalies(categoryTransactions, categoryId);
    } catch (e) {
      logError('Error getting category anomalies', e);
      return [];
    }
  }

  /// Check if spending is normal for today
  Future<bool> isSpendingNormalToday() async {
    try {
      _initializeServices();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todayTransactions = await _transactionService.getTransactionsByDateRange(
        startOfDay,
        endOfDay,
      );

      if (todayTransactions.isEmpty) return true;

      final anomalies = await _detectQuickAnomalies(todayTransactions);
      return anomalies.where((a) => a.severity == 'high' || a.severity == 'critical').isEmpty;
    } catch (e) {
      logError('Error checking if spending is normal today', e);
      return true;
    }
  }

  /// Get anomaly summary
  Future<Map<String, int>> getAnomalySummary() async {
    try {
      final anomalies = await detectAdvancedAnomalies();
      
      final summary = <String, int>{
        'total': anomalies.length,
        'critical': anomalies.where((a) => a.severity == 'critical').length,
        'high': anomalies.where((a) => a.severity == 'high').length,
        'medium': anomalies.where((a) => a.severity == 'medium').length,
        'low': anomalies.where((a) => a.severity == 'low').length,
      };

      return summary;
    } catch (e) {
      logError('Error getting anomaly summary', e);
      return {};
    }
  }

  // Private detection methods

  Future<List<SpendingAnomaly>> _detectStatisticalAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];

    // Group by category for statistical analysis
    final categoryGroups = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      categoryGroups.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }

    for (final entry in categoryGroups.entries) {
      final categoryTransactions = entry.value;
      
      if (categoryTransactions.length < 5) continue; // Need minimum data

      final amounts = categoryTransactions.map((t) => t.amount).toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final stdDev = sqrt(variance);

      // Detect outliers (more than 2 standard deviations from mean)
      for (final transaction in categoryTransactions) {
        final zScore = (transaction.amount - mean).abs() / stdDev;
        
        if (zScore > 2.5) { // Highly unusual
          String severity;
          if (zScore > 4.0) {
            severity = 'critical';
          } else if (zScore > 3.0) {
            severity = 'high';
          } else {
            severity = 'medium';
          }

          anomalies.add(SpendingAnomaly(
            id: _uuid.v4(),
            type: 'statistical',
            severity: severity,
            description: _getStatisticalAnomalyDescription(transaction, mean, zScore),
            transaction: transaction,
            detectedAt: DateTime.now(),
            confidence: (zScore / 4.0).clamp(0.5, 1.0),
          ));
        }
      }
    }

    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectBehavioralAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];

    // Detect unusual spending times
    for (final transaction in transactions) {
      final hour = transaction.date.hour;
      
      // Very late night spending (2-5 AM) might be unusual
      if (hour >= 2 && hour <= 5) {
        anomalies.add(SpendingAnomaly(
          id: _uuid.v4(),
          type: 'behavioral',
          severity: 'medium',
          description: 'Giao dịch vào lúc ${hour}h có thể bất thường',
          transaction: transaction,
          detectedAt: DateTime.now(),
          confidence: 0.6,
        ));
      }
    }

    // Detect rapid successive transactions
    transactions.sort((a, b) => a.date.compareTo(b.date));
    for (int i = 1; i < transactions.length; i++) {
      final prev = transactions[i - 1];
      final current = transactions[i];
      
      final timeDiff = current.date.difference(prev.date).inMinutes;
      
      // Multiple transactions within 5 minutes
      if (timeDiff <= 5 && current.categoryId == prev.categoryId) {
        anomalies.add(SpendingAnomaly(
          id: _uuid.v4(),
          type: 'behavioral',
          severity: 'medium',
          description: 'Nhiều giao dịch liên tiếp trong thời gian ngắn',
          transaction: current,
          detectedAt: DateTime.now(),
          confidence: 0.7,
        ));
      }
    }

    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectTemporalAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];

    // Analyze monthly spending patterns
    final monthlySpending = <String, double>{};
    for (final transaction in transactions) {
      final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + transaction.amount;
    }

    if (monthlySpending.length >= 3) {
      final amounts = monthlySpending.values.toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final stdDev = sqrt(amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length);

      // Check current month spending
      final currentMonth = DateTime.now();
      final currentMonthKey = '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}';
      final currentMonthSpending = monthlySpending[currentMonthKey] ?? 0;

      if (currentMonthSpending > mean + 2 * stdDev) {
        // Find a representative transaction for this month
        final currentMonthTransactions = transactions
            .where((t) => t.date.year == currentMonth.year && t.date.month == currentMonth.month)
            .toList();

        if (currentMonthTransactions.isNotEmpty) {
          // Use the largest transaction as representative
          final largestTransaction = currentMonthTransactions
              .reduce((a, b) => a.amount > b.amount ? a : b);

          anomalies.add(SpendingAnomaly(
            id: _uuid.v4(),
            type: 'temporal',
            severity: 'high',
            description: 'Chi tiêu tháng này cao bất thường: ${(currentMonthSpending / 1000000).toStringAsFixed(1)}M',
            transaction: largestTransaction,
            detectedAt: DateTime.now(),
            confidence: 0.8,
          ));
        }
      }
    }

    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectCategoryAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];

    // Detect new categories with high spending
    final categorySpending = <String, double>{};
    final categoryFirstTransaction = <String, DateTime>{};

    for (final transaction in transactions) {
      categorySpending[transaction.categoryId] = 
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
      
      if (!categoryFirstTransaction.containsKey(transaction.categoryId)) {
        categoryFirstTransaction[transaction.categoryId] = transaction.date;
      } else {
        final existing = categoryFirstTransaction[transaction.categoryId]!;
        if (transaction.date.isBefore(existing)) {
          categoryFirstTransaction[transaction.categoryId] = transaction.date;
        }
      }
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    for (final entry in categorySpending.entries) {
      final categoryId = entry.key;
      final spending = entry.value;
      final firstTransactionDate = categoryFirstTransaction[categoryId]!;

      // New category (first transaction within 30 days) with high spending
      if (firstTransactionDate.isAfter(thirtyDaysAgo) && spending > 1000000) { // > 1M
        final categoryTransactions = transactions
            .where((t) => t.categoryId == categoryId)
            .toList();

        if (categoryTransactions.isNotEmpty) {
          final representativeTransaction = categoryTransactions
              .reduce((a, b) => a.amount > b.amount ? a : b);

          anomalies.add(SpendingAnomaly(
            id: _uuid.v4(),
            type: 'category',
            severity: 'medium',
            description: 'Danh mục mới với chi tiêu cao: ${(spending / 1000000).toStringAsFixed(1)}M',
            transaction: representativeTransaction,
            detectedAt: DateTime.now(),
            confidence: 0.7,
          ));
        }
      }
    }

    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectCategorySpecificAnomalies(
    List<TransactionModel> transactions,
    String categoryId,
  ) async {
    final anomalies = <SpendingAnomaly>[];

    if (transactions.length < 3) return anomalies;

    // Statistical analysis for this category
    final amounts = transactions.map((t) => t.amount).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final variance = amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length;
    final stdDev = sqrt(variance);

    for (final transaction in transactions) {
      final zScore = (transaction.amount - mean).abs() / stdDev;
      
      if (zScore > 2.0) {
        anomalies.add(SpendingAnomaly(
          id: _uuid.v4(),
          type: 'category',
          severity: zScore > 3.0 ? 'high' : 'medium',
          description: 'Giao dịch bất thường trong danh mục này',
          transaction: transaction,
          detectedAt: DateTime.now(),
          confidence: (zScore / 3.0).clamp(0.5, 1.0),
        ));
      }
    }

    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectQuickAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];

    if (transactions.isEmpty) return anomalies;

    // Quick detection for large amounts
    for (final transaction in transactions) {
      if (transaction.amount > 5000000) { // > 5M VND
        anomalies.add(SpendingAnomaly(
          id: _uuid.v4(),
          type: 'statistical',
          severity: transaction.amount > 10000000 ? 'high' : 'medium',
          description: 'Giao dịch có số tiền lớn: ${(transaction.amount / 1000000).toStringAsFixed(1)}M',
          transaction: transaction,
          detectedAt: DateTime.now(),
          confidence: 0.8,
        ));
      }
    }

    return anomalies;
  }

  // Helper methods

  String _getStatisticalAnomalyDescription(
    TransactionModel transaction, 
    double mean, 
    double zScore,
  ) {
    final diff = (transaction.amount - mean) / 1000000;
    if (transaction.amount > mean) {
      return 'Giao dịch cao hơn trung bình ${diff.toStringAsFixed(1)}M (${zScore.toStringAsFixed(1)} độ lệch chuẩn)';
    } else {
      return 'Giao dịch thấp hơn trung bình ${(-diff).toStringAsFixed(1)}M (${zScore.toStringAsFixed(1)} độ lệch chuẩn)';
    }
  }

  Future<List<TransactionModel>> _getAllTransactions() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return await _transactionService.getTransactionsByDateRange(
      sixMonthsAgo,
      DateTime.now(),
    );
  }

  Future<List<TransactionModel>> _getRecentTransactions({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return await _transactionService.getTransactionsByDateRange(
      startDate,
      DateTime.now(),
    );
  }
} 