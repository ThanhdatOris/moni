/// CashFlow Predictor - Chuyên dự đoán dòng tiền
/// Được tách từ AIAnalyticsService để cải thiện maintainability

import 'dart:math';

import '../../core/models/analytics/analytics_models.dart';
import '../../models/transaction_model.dart';
import '../base_service.dart';
import '../offline_service.dart';
import '../transaction_service.dart';

/// Service chuyên dự đoán cash flow và xu hướng tài chính
class CashFlowPredictor extends BaseService {
  static final CashFlowPredictor _instance = CashFlowPredictor._internal();
  factory CashFlowPredictor() => _instance;
  CashFlowPredictor._internal();

  late final TransactionService _transactionService;

  /// Initialize services (call this before using)
  void _initializeServices() {
    final offlineService = OfflineService();
    _transactionService = TransactionService(offlineService: offlineService);
  }

  /// Main method: Predict cash flow for upcoming months
  Future<CashFlowPrediction> predictCashFlow({int months = 6}) async {
    try {
      if (currentUserId == null) {
        return _getEmptyCashFlowPrediction();
      }

      _initializeServices();
      logInfo('Predicting cash flow for next $months months');

      final transactions = await _getAllTransactions();
      if (transactions.isEmpty) {
        return _getEmptyCashFlowPrediction();
      }

      // Analyze historical data
      final monthlyData = await _analyzeMonthlyData(transactions);
      
      // Generate predictions
      final predictions = await _generateMonthlyPredictions(monthlyData, months);
      
      // Calculate totals
      final totalIncome = predictions.fold(0.0, (sum, p) => sum + p.income);
      final totalExpenses = predictions.fold(0.0, (sum, p) => sum + p.expenses);
      
      // Calculate confidence based on data quality
      final confidence = _calculateOverallConfidence(transactions, monthlyData);
      
      // Identify key factors affecting predictions
      final factors = await _identifyPredictionFactors(transactions, monthlyData);

      final cashFlowPrediction = CashFlowPrediction(
        predictions: predictions,
        totalPredictedIncome: totalIncome,
        totalPredictedExpenses: totalExpenses,
        confidence: confidence,
        factors: factors,
      );

      logInfo('Completed cash flow prediction');
      return cashFlowPrediction;
    } catch (e) {
      logError('Error predicting cash flow', e);
      return _getEmptyCashFlowPrediction();
    }
  }

  /// Get next month prediction only
  Future<MonthlyPrediction> getNextMonthPrediction() async {
    try {
      final cashFlow = await predictCashFlow(months: 1);
      if (cashFlow.predictions.isNotEmpty) {
        return cashFlow.predictions.first;
      }
      return _getEmptyMonthlyPrediction();
    } catch (e) {
      logError('Error getting next month prediction', e);
      return _getEmptyMonthlyPrediction();
    }
  }

  /// Predict specific category spending
  Future<double> predictCategorySpending(String categoryId, {int months = 1}) async {
    try {
      _initializeServices();
      final transactions = await _getAllTransactions();
      final categoryTransactions = transactions
          .where((t) => t.categoryId == categoryId)
          .toList();

      if (categoryTransactions.isEmpty) return 0.0;

      // Analyze category patterns
      final monthlySpending = <int, double>{};
      for (final transaction in categoryTransactions) {
        final monthKey = transaction.date.year * 12 + transaction.date.month;
        monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + transaction.amount;
      }

      if (monthlySpending.isEmpty) return 0.0;

      // Calculate average and trend
      final values = monthlySpending.values.toList();
      final average = values.reduce((a, b) => a + b) / values.length;
      final trend = _calculateTrend(monthlySpending);

      // Predict for specified months
      double prediction = 0.0;
      for (int i = 1; i <= months; i++) {
        prediction += average + (trend * i);
      }

      return max(0.0, prediction);
    } catch (e) {
      logError('Error predicting category spending', e);
      return 0.0;
    }
  }

  /// Check if cash flow will be positive
  Future<bool> willCashFlowBePositive({int months = 3}) async {
    try {
      final prediction = await predictCashFlow(months: months);
      return prediction.predictedNetFlow > 0;
    } catch (e) {
      logError('Error checking cash flow positivity', e);
      return false;
    }
  }

  /// Get cash flow warnings
  Future<List<String>> getCashFlowWarnings() async {
    try {
      final prediction = await predictCashFlow(months: 3);
      final warnings = <String>[];

      // Check for negative months
      for (final monthPrediction in prediction.negativeMonths) {
        warnings.add('Dự báo âm ${monthPrediction.monthName}: ${(monthPrediction.netFlow / 1000000).toStringAsFixed(1)}M');
      }

      // Check for low confidence
      if (prediction.confidence < 0.5) {
        warnings.add('Độ tin cậy dự báo thấp (${(prediction.confidence * 100).toInt()}%)');
      }

      // Check overall trend
      if (prediction.cashFlowTrend == 'Giảm') {
        warnings.add('Xu hướng dòng tiền đang giảm');
      }

      return warnings;
    } catch (e) {
      logError('Error getting cash flow warnings', e);
      return [];
    }
  }

  // Private prediction methods

  Future<Map<int, Map<String, double>>> _analyzeMonthlyData(
    List<TransactionModel> transactions,
  ) async {
    final monthlyData = <int, Map<String, double>>{};

    for (final transaction in transactions) {
      final monthKey = transaction.date.year * 12 + transaction.date.month;
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'income': 0.0, 'expenses': 0.0};
      }

      if (transaction.type == TransactionType.income) {
        monthlyData[monthKey]!['income'] = 
            monthlyData[monthKey]!['income']! + transaction.amount;
      } else {
        monthlyData[monthKey]!['expenses'] = 
            monthlyData[monthKey]!['expenses']! + transaction.amount;
      }
    }

    return monthlyData;
  }

  Future<List<MonthlyPrediction>> _generateMonthlyPredictions(
    Map<int, Map<String, double>> historicalData,
    int months,
  ) async {
    final predictions = <MonthlyPrediction>[];

    if (historicalData.isEmpty) {
      // Generate empty predictions
      for (int i = 1; i <= months; i++) {
        final futureDate = DateTime.now().add(Duration(days: 30 * i));
        predictions.add(MonthlyPrediction(
          month: DateTime(futureDate.year, futureDate.month),
          income: 0.0,
          expenses: 0.0,
          netFlow: 0.0,
          confidence: 0.0,
        ));
      }
      return predictions;
    }

    // Calculate averages and trends
    final incomeValues = historicalData.values.map((data) => data['income']!).toList();
    final expenseValues = historicalData.values.map((data) => data['expenses']!).toList();

    final avgIncome = incomeValues.isNotEmpty 
        ? incomeValues.reduce((a, b) => a + b) / incomeValues.length 
        : 0.0;
    final avgExpenses = expenseValues.isNotEmpty 
        ? expenseValues.reduce((a, b) => a + b) / expenseValues.length 
        : 0.0;

    // Calculate trends
    final incomeMonthlyData = <int, double>{};
    final expenseMonthlyData = <int, double>{};
    
    for (final entry in historicalData.entries) {
      incomeMonthlyData[entry.key] = entry.value['income']!;
      expenseMonthlyData[entry.key] = entry.value['expenses']!;
    }

    final incomeTrend = _calculateTrend(incomeMonthlyData);
    final expenseTrend = _calculateTrend(expenseMonthlyData);

    // Generate predictions for each month
    for (int i = 1; i <= months; i++) {
      final futureDate = DateTime.now().add(Duration(days: 30 * i));
      final month = DateTime(futureDate.year, futureDate.month);

      // Apply seasonal adjustments
      final seasonalFactor = _getSeasonalFactor(month.month);
      
      // Predict income and expenses
      final predictedIncome = max(0.0, (avgIncome + incomeTrend * i) * seasonalFactor);
      final predictedExpenses = max(0.0, (avgExpenses + expenseTrend * i) * seasonalFactor);
      final netFlow = predictedIncome - predictedExpenses;

      // Calculate confidence for this prediction
      final confidence = _calculateMonthlyConfidence(historicalData, i);

      predictions.add(MonthlyPrediction(
        month: month,
        income: predictedIncome,
        expenses: predictedExpenses,
        netFlow: netFlow,
        confidence: confidence,
      ));
    }

    return predictions;
  }

  double _calculateTrend(Map<int, double> monthlyData) {
    if (monthlyData.length < 2) return 0.0;
    
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    if (sortedEntries.length < 2) return 0.0;
    
    // Simple linear trend calculation
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < sortedEntries.length; i++) {
      final x = i.toDouble();
      final y = sortedEntries[i].value;
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    
    final n = sortedEntries.length;
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    return slope.isFinite ? slope : 0.0;
  }

  double _getSeasonalFactor(int month) {
    // Vietnamese seasonal factors
    const seasonalFactors = [
      1.15, // Jan - Tet season
      1.1,  // Feb
      1.0,  // Mar
      1.0,  // Apr
      1.05, // May
      1.0,  // Jun
      1.0,  // Jul
      1.0,  // Aug
      1.1,  // Sep - Back to school
      1.0,  // Oct
      1.05, // Nov
      1.2,  // Dec - Year-end/Christmas
    ];
    
    return seasonalFactors[month - 1];
  }

  double _calculateOverallConfidence(
    List<TransactionModel> transactions,
    Map<int, Map<String, double>> monthlyData,
  ) {
    double confidence = 0.0;

    // Data quality factors
    final dataPoints = transactions.length;
    final timeSpan = monthlyData.length;
    
    // More data = higher confidence
    confidence += (dataPoints / 200.0).clamp(0.0, 0.4); // Max 40% for data volume
    confidence += (timeSpan / 12.0).clamp(0.0, 0.3); // Max 30% for time span
    
    // Consistency factors
    if (monthlyData.isNotEmpty) {
      final incomeValues = monthlyData.values.map((data) => data['income']!).toList();
      final expenseValues = monthlyData.values.map((data) => data['expenses']!).toList();
      
      if (incomeValues.isNotEmpty) {
        final incomeConsistency = _calculateConsistency(incomeValues);
        confidence += incomeConsistency * 0.15; // Max 15%
      }
      
      if (expenseValues.isNotEmpty) {
        final expenseConsistency = _calculateConsistency(expenseValues);
        confidence += expenseConsistency * 0.15; // Max 15%
      }
    }

    return confidence.clamp(0.0, 1.0);
  }

  double _calculateConsistency(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final coefficientOfVariation = sqrt(variance) / mean;
    
    // Lower variation = higher consistency
    return (1.0 / (1.0 + coefficientOfVariation)).clamp(0.0, 1.0);
  }

  double _calculateMonthlyConfidence(
    Map<int, Map<String, double>> monthlyData,
    int futureMonth,
  ) {
    // Confidence decreases with distance into future
    final baseConfidence = _calculateOverallConfidence([], monthlyData);
    final distancePenalty = futureMonth * 0.1; // 10% reduction per month
    
    return (baseConfidence - distancePenalty).clamp(0.0, 1.0);
  }

  Future<List<String>> _identifyPredictionFactors(
    List<TransactionModel> transactions,
    Map<int, Map<String, double>> monthlyData,
  ) async {
    final factors = <String>[];

    // Data quality factors
    factors.add('Dựa trên ${transactions.length} giao dịch');
    factors.add('Phân tích ${monthlyData.length} tháng dữ liệu');

    // Income stability
    if (monthlyData.isNotEmpty) {
      final incomeValues = monthlyData.values.map((data) => data['income']!).toList();
      if (incomeValues.isNotEmpty) {
        final consistency = _calculateConsistency(incomeValues);
        if (consistency > 0.7) {
          factors.add('Thu nhập ổn định');
        } else {
          factors.add('Thu nhập không đều');
        }
      }
    }

    // Spending patterns
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    
    if (expenseTransactions.isNotEmpty) {
      final amounts = expenseTransactions.map((t) => t.amount).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      
      if (avgAmount > 1000000) {
        factors.add('Chi tiêu trung bình cao');
      } else {
        factors.add('Chi tiêu trung bình vừa phải');
      }
    }

    // Seasonal considerations
    final currentMonth = DateTime.now().month;
    if (currentMonth == 12 || currentMonth == 1) {
      factors.add('Giai đoạn cuối năm - chi tiêu có thể tăng');
    }

    return factors.take(5).toList(); // Limit to 5 key factors
  }

  // Helper methods

  Future<List<TransactionModel>> _getAllTransactions() async {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    return await _transactionService.getTransactionsByDateRange(
      oneYearAgo,
      DateTime.now(),
    );
  }

  CashFlowPrediction _getEmptyCashFlowPrediction() {
    return CashFlowPrediction(
      predictions: [],
      totalPredictedIncome: 0.0,
      totalPredictedExpenses: 0.0,
      confidence: 0.0,
      factors: ['Không đủ dữ liệu để dự đoán'],
    );
  }

  MonthlyPrediction _getEmptyMonthlyPrediction() {
    final nextMonth = DateTime.now().add(const Duration(days: 30));
    return MonthlyPrediction(
      month: DateTime(nextMonth.year, nextMonth.month),
      income: 0.0,
      expenses: 0.0,
      netFlow: 0.0,
      confidence: 0.0,
    );
  }
} 