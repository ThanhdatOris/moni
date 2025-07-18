import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_budget_model.dart';
import '../models/transaction_model.dart';
import '../services/ai_analytics_service.dart';
import '../services/ai_budget_agent_service.dart';
import '../services/base_service.dart';

/// AI Notification Agent - Intelligent notification scheduling and management
class AINotificationAgent extends BaseService {
  static final AINotificationAgent _instance = AINotificationAgent._internal();
  factory AINotificationAgent() => _instance;
  AINotificationAgent._internal();

  final AIBudgetAgentService _budgetService = AIBudgetAgentService();
  final AIAnalyticsService _analyticsService = AIAnalyticsService();
  final _uuid = const Uuid();

  Timer? _schedulingTimer;
  bool _isRunning = false;
  List<ScheduledNotification> _scheduledNotifications = [];

  /// Start intelligent notification agent
  Future<void> startAgent() async {
    if (_isRunning) return;

    _isRunning = true;
    logInfo('Starting AI Notification Agent');

    // Load existing scheduled notifications
    await _loadScheduledNotifications();

    // Schedule intelligent notifications
    await scheduleIntelligentNotifications();

    // Set up periodic scheduling (every hour)
    _schedulingTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _processScheduledNotifications(),
    );
  }

  /// Stop notification agent
  void stopAgent() {
    _isRunning = false;
    _schedulingTimer?.cancel();
    _schedulingTimer = null;
    logInfo('Stopped AI Notification Agent');
  }

  /// Intelligent notification scheduling based on user behavior
  Future<void> scheduleIntelligentNotifications() async {
    try {
      if (currentUserId == null) return;

      logInfo('Scheduling intelligent notifications');

      final userBehavior = await _analyzeUserBehavior();
      final optimalTimes =
          await _calculateOptimalNotificationTimes(userBehavior);

      // Clear existing scheduled notifications
      _scheduledNotifications.clear();

      // Schedule different types of notifications
      await _scheduleBudgetNotifications(optimalTimes);
      await _scheduleInsightNotifications(optimalTimes);
      await _scheduleRecommendationNotifications(optimalTimes);
      await _scheduleReportNotifications(optimalTimes);

      // Save scheduled notifications
      await _saveScheduledNotifications();

      logInfo(
          'Scheduled ${_scheduledNotifications.length} intelligent notifications');
    } catch (e) {
      logError('Error scheduling intelligent notifications', e);
    }
  }

  /// Send context-aware alert
  Future<void> sendContextualAlert(AlertContext context) async {
    try {
      final message = await _generateContextualMessage(context);
      final importance = await _calculateImportance(context);
      final timing = await _calculateOptimalTiming(context);

      await _sendAlert(message, importance, timing);

      logInfo('Sent contextual alert: ${context.type}');
    } catch (e) {
      logError('Error sending contextual alert', e);
    }
  }

  /// Provide proactive financial advice
  Future<void> provideProactiveAdvice() async {
    try {
      if (currentUserId == null) return;

      logInfo('Providing proactive financial advice');

      final opportunities = await _identifyOpportunities();
      final risks = await _identifyRisks();

      for (final opportunity in opportunities) {
        await _sendOpportunityNotification(opportunity);
      }

      for (final risk in risks) {
        await _sendRiskAlert(risk);
      }

      logInfo(
          'Sent ${opportunities.length} opportunities and ${risks.length} risk alerts');
    } catch (e) {
      logError('Error providing proactive advice', e);
    }
  }

  /// Send intelligent alert with AI-generated content
  Future<void> sendIntelligentAlert({
    required String title,
    required String message,
    required Map<String, dynamic> data,
    AlertImportance importance = AlertImportance.medium,
  }) async {
    try {
      final notification = IntelligentNotification(
        id: _uuid.v4(),
        type: 'alert',
        title: title,
        message: message,
        data: data,
        importance: importance,
        createdAt: DateTime.now(),
        scheduledAt: DateTime.now(),
        userId: currentUserId!,
      );

      await _deliverNotification(notification);

      logInfo('Sent intelligent alert: $title');
    } catch (e) {
      logError('Error sending intelligent alert', e);
    }
  }

  /// Send budget adjustment suggestion
  Future<void> sendBudgetAdjustmentSuggestion(
    BudgetAdjustmentSuggestion suggestion,
  ) async {
    try {
      final notification = IntelligentNotification(
        id: _uuid.v4(),
        type: 'budget_adjustment',
        title: 'Budget Adjustment Suggestion',
        message: 'Consider adjusting your ${suggestion.budgetId} budget',
        data: {
          'budgetId': suggestion.budgetId,
          'currentLimit': suggestion.currentLimit,
          'suggestedLimit': suggestion.suggestedLimit,
          'reason': suggestion.reason,
          'confidence': suggestion.confidence,
        },
        importance: AlertImportance.medium,
        createdAt: DateTime.now(),
        scheduledAt: DateTime.now(),
        userId: currentUserId!,
      );

      await _deliverNotification(notification);

      logInfo('Sent budget adjustment suggestion');
    } catch (e) {
      logError('Error sending budget adjustment suggestion', e);
    }
  }

  /// Send intelligent report
  Future<void> sendIntelligentReport({
    required List<AIInsight> insights,
    required List<BudgetRecommendation> recommendations,
    required BudgetAnalytics analytics,
    required NotificationFrequency frequency,
  }) async {
    try {
      final reportTitle = _generateReportTitle(frequency);
      final reportMessage =
          _generateReportMessage(insights, recommendations, analytics);

      final notification = IntelligentNotification(
        id: _uuid.v4(),
        type: 'report',
        title: reportTitle,
        message: reportMessage,
        data: {
          'insights': insights.map((i) => i.toJson()).toList(),
          'recommendations': recommendations.map((r) => r.toJson()).toList(),
          'analytics': analytics.toJson(),
          'frequency': frequency.name,
        },
        importance: AlertImportance.low,
        createdAt: DateTime.now(),
        scheduledAt: DateTime.now(),
        userId: currentUserId!,
      );

      await _deliverNotification(notification);

      logInfo('Sent intelligent report: $reportTitle');
    } catch (e) {
      logError('Error sending intelligent report', e);
    }
  }

  // Private methods

  Future<void> _loadScheduledNotifications() async {
    try {
      final snapshot = await firestore
          .collection('scheduled_notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('scheduledAt', isGreaterThan: DateTime.now())
          .get();

      _scheduledNotifications = snapshot.docs
          .map((doc) => ScheduledNotification.fromFirestore(doc))
          .toList();

      logInfo(
          'Loaded ${_scheduledNotifications.length} scheduled notifications');
    } catch (e) {
      logError('Error loading scheduled notifications', e);
    }
  }

  Future<void> _saveScheduledNotifications() async {
    try {
      final batch = firestore.batch();

      for (final notification in _scheduledNotifications) {
        final docRef = firestore
            .collection('scheduled_notifications')
            .doc(notification.id);
        batch.set(docRef, notification.toFirestore());
      }

      await batch.commit();
      logInfo(
          'Saved ${_scheduledNotifications.length} scheduled notifications');
    } catch (e) {
      logError('Error saving scheduled notifications', e);
    }
  }

  Future<void> _processScheduledNotifications() async {
    try {
      final now = DateTime.now();
      final dueNotifications = _scheduledNotifications
          .where((n) => n.scheduledAt.isBefore(now))
          .toList();

      for (final notification in dueNotifications) {
        await _deliverScheduledNotification(notification);
        _scheduledNotifications.remove(notification);
      }

      if (dueNotifications.isNotEmpty) {
        await _saveScheduledNotifications();
        logInfo('Processed ${dueNotifications.length} due notifications');
      }
    } catch (e) {
      logError('Error processing scheduled notifications', e);
    }
  }

  Future<UserBehavior> _analyzeUserBehavior() async {
    try {
      // Analyze user's transaction patterns to determine optimal notification times
      final transactions = await _getRecentTransactions();

      // Analyze transaction times
      final hourlyActivity = <int, int>{};
      final dayOfWeekActivity = <int, int>{};

      for (final transaction in transactions) {
        final hour = transaction.date.hour;
        final dayOfWeek = transaction.date.weekday;

        hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
        dayOfWeekActivity[dayOfWeek] = (dayOfWeekActivity[dayOfWeek] ?? 0) + 1;
      }

      // Find peak activity times
      final peakHours = hourlyActivity.entries
          .where((e) => e.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final peakDays = dayOfWeekActivity.entries
          .where((e) => e.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return UserBehavior(
        peakHours: peakHours.take(3).map((e) => e.key).toList(),
        peakDays: peakDays.take(3).map((e) => e.key).toList(),
        averageTransactionsPerDay: transactions.length / 30,
        preferredNotificationTime:
            _calculatePreferredNotificationTime(peakHours),
      );
    } catch (e) {
      logError('Error analyzing user behavior', e);
      return UserBehavior(
        peakHours: [9, 12, 18], // Default times
        peakDays: [1, 2, 3, 4, 5], // Weekdays
        averageTransactionsPerDay: 3.0,
        preferredNotificationTime: TimeOfDay(hour: 9, minute: 0),
      );
    }
  }

  Future<List<OptimalTime>> _calculateOptimalNotificationTimes(
    UserBehavior behavior,
  ) async {
    final optimalTimes = <OptimalTime>[];

    // Morning notifications (budget alerts, insights)
    optimalTimes.add(OptimalTime(
      time: TimeOfDay(hour: 8, minute: 0),
      type: 'morning',
      suitability: 0.8,
    ));

    // Afternoon notifications (recommendations, tips)
    optimalTimes.add(OptimalTime(
      time: TimeOfDay(hour: 14, minute: 0),
      type: 'afternoon',
      suitability: 0.6,
    ));

    // Evening notifications (daily summary, insights)
    optimalTimes.add(OptimalTime(
      time: TimeOfDay(hour: 19, minute: 0),
      type: 'evening',
      suitability: 0.9,
    ));

    // User-specific optimal time
    optimalTimes.add(OptimalTime(
      time: behavior.preferredNotificationTime,
      type: 'user_preferred',
      suitability: 1.0,
    ));

    return optimalTimes;
  }

  Future<void> _scheduleBudgetNotifications(
      List<OptimalTime> optimalTimes) async {
    final budgets = await _budgetService.getUserBudgets();

    for (final budget in budgets) {
      if (budget.settings.smartNotifications) {
        // Schedule daily budget check
        final dailyTime =
            optimalTimes.firstWhere((t) => t.type == 'morning').time;

        _scheduledNotifications.add(ScheduledNotification(
          id: _uuid.v4(),
          userId: currentUserId!,
          type: 'budget_check',
          title: 'Daily Budget Check',
          message: 'Checking your ${budget.categoryId} budget',
          data: {'budgetId': budget.id},
          scheduledAt: _getNextScheduledTime(dailyTime),
          importance: AlertImportance.medium,
          recurring: true,
          recurringInterval: RecurringInterval.daily,
        ));
      }
    }
  }

  Future<void> _scheduleInsightNotifications(
      List<OptimalTime> optimalTimes) async {
    final eveningTime =
        optimalTimes.firstWhere((t) => t.type == 'evening').time;

    // Schedule weekly insights
    _scheduledNotifications.add(ScheduledNotification(
      id: _uuid.v4(),
      userId: currentUserId!,
      type: 'weekly_insights',
      title: 'Weekly Spending Insights',
      message: 'Here are your spending insights for this week',
      data: {},
      scheduledAt: _getNextWeeklyTime(eveningTime),
      importance: AlertImportance.low,
      recurring: true,
      recurringInterval: RecurringInterval.weekly,
    ));
  }

  Future<void> _scheduleRecommendationNotifications(
      List<OptimalTime> optimalTimes) async {
    final afternoonTime =
        optimalTimes.firstWhere((t) => t.type == 'afternoon').time;

    // Schedule bi-weekly recommendations
    _scheduledNotifications.add(ScheduledNotification(
      id: _uuid.v4(),
      userId: currentUserId!,
      type: 'recommendations',
      title: 'Smart Budget Recommendations',
      message: 'We have new budget recommendations for you',
      data: {},
      scheduledAt: _getNextBiWeeklyTime(afternoonTime),
      importance: AlertImportance.medium,
      recurring: true,
      recurringInterval: RecurringInterval.biWeekly,
    ));
  }

  Future<void> _scheduleReportNotifications(
      List<OptimalTime> optimalTimes) async {
    final userPreferredTime =
        optimalTimes.firstWhere((t) => t.type == 'user_preferred').time;

    // Schedule monthly reports
    _scheduledNotifications.add(ScheduledNotification(
      id: _uuid.v4(),
      userId: currentUserId!,
      type: 'monthly_report',
      title: 'Monthly Financial Report',
      message: 'Your monthly financial report is ready',
      data: {},
      scheduledAt: _getNextMonthlyTime(userPreferredTime),
      importance: AlertImportance.high,
      recurring: true,
      recurringInterval: RecurringInterval.monthly,
    ));
  }

  Future<String> _generateContextualMessage(AlertContext context) async {
    switch (context.type) {
      case 'budget_exceeded':
        return 'You\'ve exceeded your ${context.categoryId} budget by ${context.amount.toStringAsFixed(0)}';
      case 'unusual_spending':
        return 'Unusual spending detected: ${context.amount.toStringAsFixed(0)} on ${context.categoryId}';
      case 'savings_opportunity':
        return 'You can save ${context.amount.toStringAsFixed(0)} by optimizing your ${context.categoryId} spending';
      case 'payment_due':
        return 'Payment due: ${context.description}';
      default:
        return 'Financial alert: ${context.description}';
    }
  }

  Future<AlertImportance> _calculateImportance(AlertContext context) async {
    switch (context.type) {
      case 'budget_exceeded':
        return context.amount > 100000
            ? AlertImportance.high
            : AlertImportance.medium;
      case 'unusual_spending':
        return AlertImportance.high;
      case 'savings_opportunity':
        return AlertImportance.low;
      case 'payment_due':
        return AlertImportance.high;
      default:
        return AlertImportance.medium;
    }
  }

  Future<DateTime> _calculateOptimalTiming(AlertContext context) async {
    final now = DateTime.now();

    switch (context.type) {
      case 'budget_exceeded':
      case 'unusual_spending':
        return now; // Immediate
      case 'savings_opportunity':
        return now.add(const Duration(hours: 2)); // Delayed
      case 'payment_due':
        return now.add(const Duration(minutes: 5)); // Slight delay
      default:
        return now.add(const Duration(minutes: 30)); // Default delay
    }
  }

  Future<void> _sendAlert(
    String message,
    AlertImportance importance,
    DateTime timing,
  ) async {
    final notification = IntelligentNotification(
      id: _uuid.v4(),
      type: 'alert',
      title: 'Financial Alert',
      message: message,
      data: {},
      importance: importance,
      createdAt: DateTime.now(),
      scheduledAt: timing,
      userId: currentUserId!,
    );

    if (timing.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      await _deliverNotification(notification);
    } else {
      _scheduledNotifications
          .add(ScheduledNotification.fromNotification(notification));
      await _saveScheduledNotifications();
    }
  }

  Future<List<FinancialOpportunity>> _identifyOpportunities() async {
    final opportunities = <FinancialOpportunity>[];

    try {
      // Get spending analysis
      final analysis = await _analyticsService.analyzeSpendingPatterns();

      // Identify categories with decreasing trends
      for (final entry in analysis.monthlyTrends.entries) {
        final trend = entry.value;
        if (trend.trend < -1000) {
          // Decreasing by 1000+ per month
          opportunities.add(FinancialOpportunity(
            id: _uuid.v4(),
            type: 'spending_decrease',
            categoryId: entry.key,
            title: 'Spending Decrease Detected',
            description:
                'Your ${entry.key} spending has decreased by ${trend.trend.abs().toStringAsFixed(0)} per month',
            potentialSaving: trend.trend.abs(),
            confidence: trend.confidence,
            actionable: true,
            action: 'Consider reallocating this budget to other categories',
          ));
        }
      }

      // Identify budget optimization opportunities
      final budgets = await _budgetService.getUserBudgets();
      for (final budget in budgets) {
        if (budget.analytics.averageSpending < budget.monthlyLimit * 0.7) {
          opportunities.add(FinancialOpportunity(
            id: _uuid.v4(),
            type: 'budget_optimization',
            categoryId: budget.categoryId,
            title: 'Budget Optimization',
            description:
                'You consistently spend 30% less than your ${budget.categoryId} budget',
            potentialSaving:
                budget.monthlyLimit - budget.analytics.averageSpending,
            confidence: 0.8,
            actionable: true,
            action: 'Consider reducing this budget and increasing savings',
          ));
        }
      }
    } catch (e) {
      logError('Error identifying opportunities', e);
    }

    return opportunities;
  }

  Future<List<FinancialRisk>> _identifyRisks() async {
    final risks = <FinancialRisk>[];

    try {
      // Get budget data
      final budgets = await _budgetService.getUserBudgets();

      // Identify high-risk budgets
      for (final budget in budgets) {
        if (budget.riskScore > 0.8) {
          risks.add(FinancialRisk(
            id: _uuid.v4(),
            type: 'budget_risk',
            categoryId: budget.categoryId,
            severity: budget.riskScore > 0.9 ? 'high' : 'medium',
            title: 'Budget Risk Alert',
            description: 'High risk of exceeding ${budget.categoryId} budget',
            probability: budget.riskScore,
            impact: budget.monthlyLimit * 0.1, // 10% of budget
            mitigation: 'Reduce spending or increase budget limit',
          ));
        }
      }

      // Identify spending anomalies
      final anomalies = await _analyticsService.detectAdvancedAnomalies();
      for (final anomaly in anomalies) {
        if (anomaly.severity == 'high') {
          risks.add(FinancialRisk(
            id: _uuid.v4(),
            type: 'spending_anomaly',
            categoryId: anomaly.transaction.categoryId,
            severity: 'high',
            title: 'Spending Anomaly',
            description: anomaly.description,
            probability: anomaly.confidence,
            impact: anomaly.transaction.amount,
            mitigation: 'Review transaction and verify if legitimate',
          ));
        }
      }
    } catch (e) {
      logError('Error identifying risks', e);
    }

    return risks;
  }

  Future<void> _sendOpportunityNotification(
      FinancialOpportunity opportunity) async {
    await sendIntelligentAlert(
      title: opportunity.title,
      message: opportunity.description,
      data: {
        'type': 'opportunity',
        'opportunityId': opportunity.id,
        'categoryId': opportunity.categoryId,
        'potentialSaving': opportunity.potentialSaving,
        'action': opportunity.action,
      },
      importance: AlertImportance.low,
    );
  }

  Future<void> _sendRiskAlert(FinancialRisk risk) async {
    await sendIntelligentAlert(
      title: risk.title,
      message: risk.description,
      data: {
        'type': 'risk',
        'riskId': risk.id,
        'categoryId': risk.categoryId,
        'severity': risk.severity,
        'mitigation': risk.mitigation,
      },
      importance: risk.severity == 'high'
          ? AlertImportance.high
          : AlertImportance.medium,
    );
  }

  Future<void> _deliverNotification(
      IntelligentNotification notification) async {
    try {
      // Save notification to database
      await firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      // Send push notification (implementation depends on your push service)
      await _sendPushNotification(notification);

      logInfo('Delivered notification: ${notification.title}');
    } catch (e) {
      logError('Error delivering notification', e);
    }
  }

  Future<void> _deliverScheduledNotification(
      ScheduledNotification notification) async {
    try {
      final intelligentNotification = IntelligentNotification(
        id: notification.id,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        data: notification.data,
        importance: notification.importance,
        createdAt: notification.scheduledAt,
        scheduledAt: notification.scheduledAt,
        userId: notification.userId,
      );

      await _deliverNotification(intelligentNotification);

      // If recurring, schedule next occurrence
      if (notification.recurring) {
        final nextNotification = _scheduleNextRecurrence(notification);
        if (nextNotification != null) {
          _scheduledNotifications.add(nextNotification);
        }
      }

      // Remove from scheduled notifications
      await firestore
          .collection('scheduled_notifications')
          .doc(notification.id)
          .delete();
    } catch (e) {
      logError('Error delivering scheduled notification', e);
    }
  }

  Future<void> _sendPushNotification(
      IntelligentNotification notification) async {
    // Implementation depends on your push notification service
    // This is a placeholder for the actual push notification logic
    logInfo('Push notification sent: ${notification.title}');
  }

  // Helper methods

  Future<List<TransactionModel>> _getRecentTransactions() async {
    // Implementation depends on your transaction service
    return [];
  }

  TimeOfDay _calculatePreferredNotificationTime(
      List<MapEntry<int, int>> peakHours) {
    if (peakHours.isEmpty) return const TimeOfDay(hour: 9, minute: 0);

    // Find the most active hour that's reasonable for notifications
    for (final entry in peakHours) {
      if (entry.key >= 8 && entry.key <= 20) {
        // Between 8 AM and 8 PM
        return TimeOfDay(hour: entry.key, minute: 0);
      }
    }

    return const TimeOfDay(hour: 9, minute: 0);
  }

  DateTime _getNextScheduledTime(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  DateTime _getNextWeeklyTime(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Find next Sunday
    while (scheduled.weekday != 7) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }

  DateTime _getNextBiWeeklyTime(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Find next occurrence 2 weeks from now
    scheduled = scheduled.add(const Duration(days: 14));

    return scheduled;
  }

  DateTime _getNextMonthlyTime(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, 1, time.hour, time.minute);

    // First day of next month
    if (now.month == 12) {
      scheduled = DateTime(now.year + 1, 1, 1, time.hour, time.minute);
    } else {
      scheduled = DateTime(now.year, now.month + 1, 1, time.hour, time.minute);
    }

    return scheduled;
  }

  ScheduledNotification? _scheduleNextRecurrence(
      ScheduledNotification notification) {
    if (!notification.recurring) return null;

    DateTime nextTime;

    switch (notification.recurringInterval) {
      case RecurringInterval.daily:
        nextTime = notification.scheduledAt.add(const Duration(days: 1));
        break;
      case RecurringInterval.weekly:
        nextTime = notification.scheduledAt.add(const Duration(days: 7));
        break;
      case RecurringInterval.biWeekly:
        nextTime = notification.scheduledAt.add(const Duration(days: 14));
        break;
      case RecurringInterval.monthly:
        nextTime = DateTime(
          notification.scheduledAt.month == 12
              ? notification.scheduledAt.year + 1
              : notification.scheduledAt.year,
          notification.scheduledAt.month == 12
              ? 1
              : notification.scheduledAt.month + 1,
          notification.scheduledAt.day,
          notification.scheduledAt.hour,
          notification.scheduledAt.minute,
        );
        break;
    }

    return notification.copyWith(
      id: _uuid.v4(),
      scheduledAt: nextTime,
    );
  }

  String _generateReportTitle(NotificationFrequency frequency) {
    switch (frequency) {
      case NotificationFrequency.daily:
        return 'Daily Financial Summary';
      case NotificationFrequency.weekly:
        return 'Weekly Financial Report';
      case NotificationFrequency.monthly:
        return 'Monthly Financial Analysis';
      default:
        return 'Financial Report';
    }
  }

  String _generateReportMessage(
    List<AIInsight> insights,
    List<BudgetRecommendation> recommendations,
    BudgetAnalytics analytics,
  ) {
    final insightCount = insights.length;
    final recommendationCount = recommendations.length;
    final totalSpending = analytics.totalSpending;

    return 'You have $insightCount insights and $recommendationCount recommendations. '
        'Total spending: ${totalSpending.toStringAsFixed(0)}';
  }
}

// Supporting classes

enum AlertImportance { low, medium, high }

enum RecurringInterval { daily, weekly, biWeekly, monthly }

class AlertContext {
  final String type;
  final String? categoryId;
  final double amount;
  final String description;
  final Map<String, dynamic> data;

  AlertContext({
    required this.type,
    this.categoryId,
    required this.amount,
    required this.description,
    required this.data,
  });
}

class UserBehavior {
  final List<int> peakHours;
  final List<int> peakDays;
  final double averageTransactionsPerDay;
  final TimeOfDay preferredNotificationTime;

  UserBehavior({
    required this.peakHours,
    required this.peakDays,
    required this.averageTransactionsPerDay,
    required this.preferredNotificationTime,
  });
}

class OptimalTime {
  final TimeOfDay time;
  final String type;
  final double suitability;

  OptimalTime({
    required this.time,
    required this.type,
    required this.suitability,
  });
}

class IntelligentNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final AlertImportance importance;
  final DateTime createdAt;
  final DateTime scheduledAt;
  final String userId;

  IntelligentNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.importance,
    required this.createdAt,
    required this.scheduledAt,
    required this.userId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'importance': importance.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'userId': userId,
    };
  }

  factory IntelligentNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IntelligentNotification(
      id: doc.id,
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      importance: AlertImportance.values[data['importance'] ?? 0],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }
}

class ScheduledNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime scheduledAt;
  final AlertImportance importance;
  final bool recurring;
  final RecurringInterval recurringInterval;

  ScheduledNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.scheduledAt,
    required this.importance,
    required this.recurring,
    required this.recurringInterval,
  });

  ScheduledNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? scheduledAt,
    AlertImportance? importance,
    bool? recurring,
    RecurringInterval? recurringInterval,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      importance: importance ?? this.importance,
      recurring: recurring ?? this.recurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'importance': importance.index,
      'recurring': recurring,
      'recurringInterval': recurringInterval.index,
    };
  }

  factory ScheduledNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      importance: AlertImportance.values[data['importance'] ?? 0],
      recurring: data['recurring'] ?? false,
      recurringInterval:
          RecurringInterval.values[data['recurringInterval'] ?? 0],
    );
  }

  factory ScheduledNotification.fromNotification(
      IntelligentNotification notification) {
    return ScheduledNotification(
      id: notification.id,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      data: notification.data,
      scheduledAt: notification.scheduledAt,
      importance: notification.importance,
      recurring: false,
      recurringInterval: RecurringInterval.daily,
    );
  }
}

class FinancialOpportunity {
  final String id;
  final String type;
  final String categoryId;
  final String title;
  final String description;
  final double potentialSaving;
  final double confidence;
  final bool actionable;
  final String action;

  FinancialOpportunity({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.potentialSaving,
    required this.confidence,
    required this.actionable,
    required this.action,
  });
}

class FinancialRisk {
  final String id;
  final String type;
  final String categoryId;
  final String severity;
  final String title;
  final String description;
  final double probability;
  final double impact;
  final String mitigation;

  FinancialRisk({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.severity,
    required this.title,
    required this.description,
    required this.probability,
    required this.impact,
    required this.mitigation,
  });
}

// Extension classes for compatibility
extension BudgetAnalyticsExtension on BudgetAnalytics {
  Map<String, dynamic> toJson() {
    return {
      'totalBudgets': totalBudgets,
      'totalSpending': totalSpending,
      'averageUtilization': averageUtilization,
      'riskDistribution': riskDistribution,
      'topCategories': topCategories,
    };
  }
}

extension BudgetRecommendationExtension on BudgetRecommendation {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'suggestedLimit': suggestedLimit,
      'category': category,
      'confidence': confidence,
    };
  }
}
