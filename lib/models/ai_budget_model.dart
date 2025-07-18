import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Enum for budget health status
enum BudgetHealthStatus {
  excellent,
  good,
  warning,
  critical,
  unknown
}

/// Enum for notification frequency
enum NotificationFrequency {
  realTime,
  daily,
  weekly,
  monthly,
  custom
}

/// AI Budget Model with intelligent features
class AIBudgetModel extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final double monthlyLimit;
  final double weeklyLimit;
  final double dailyLimit;
  final AIBudgetSettings settings;
  final AIBudgetAnalytics analytics;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // AI-specific properties
  final double predictedSpending;
  final double riskScore;
  final BudgetHealthStatus healthStatus;
  final List<AIInsight> insights;
  final List<AIRecommendation> recommendations;

  const AIBudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.monthlyLimit,
    required this.weeklyLimit,
    required this.dailyLimit,
    required this.settings,
    required this.analytics,
    required this.createdAt,
    required this.updatedAt,
    required this.predictedSpending,
    required this.riskScore,
    required this.healthStatus,
    required this.insights,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    categoryId,
    monthlyLimit,
    weeklyLimit,
    dailyLimit,
    settings,
    analytics,
    createdAt,
    updatedAt,
    predictedSpending,
    riskScore,
    healthStatus,
    insights,
    recommendations,
  ];

  AIBudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? monthlyLimit,
    double? weeklyLimit,
    double? dailyLimit,
    AIBudgetSettings? settings,
    AIBudgetAnalytics? analytics,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? predictedSpending,
    double? riskScore,
    BudgetHealthStatus? healthStatus,
    List<AIInsight>? insights,
    List<AIRecommendation>? recommendations,
  }) {
    return AIBudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      weeklyLimit: weeklyLimit ?? this.weeklyLimit,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      settings: settings ?? this.settings,
      analytics: analytics ?? this.analytics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      predictedSpending: predictedSpending ?? this.predictedSpending,
      riskScore: riskScore ?? this.riskScore,
      healthStatus: healthStatus ?? this.healthStatus,
      insights: insights ?? this.insights,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  /// Firebase-compatible serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'monthlyLimit': monthlyLimit,
      'weeklyLimit': weeklyLimit,
      'dailyLimit': dailyLimit,
      'settings': settings.toFirestore(),
      'analytics': analytics.toFirestore(),
      'predictedSpending': predictedSpending,
      'riskScore': riskScore,
      'healthStatus': healthStatus.index,
      'insights': insights.map((i) => i.toFirestore()).toList(),
      'recommendations': recommendations.map((r) => r.toFirestore()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory AIBudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIBudgetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      monthlyLimit: (data['monthlyLimit'] ?? 0).toDouble(),
      weeklyLimit: (data['weeklyLimit'] ?? 0).toDouble(),
      dailyLimit: (data['dailyLimit'] ?? 0).toDouble(),
      settings: AIBudgetSettings.fromFirestore(data['settings'] ?? {}),
      analytics: AIBudgetAnalytics.fromFirestore(data['analytics'] ?? {}),
      predictedSpending: (data['predictedSpending'] ?? 0).toDouble(),
      riskScore: (data['riskScore'] ?? 0).toDouble(),
      healthStatus: BudgetHealthStatus.values[data['healthStatus'] ?? 0],
      insights: (data['insights'] as List?)
          ?.map((i) => AIInsight.fromFirestore(i))
          .toList() ?? [],
      recommendations: (data['recommendations'] as List?)
          ?.map((r) => AIRecommendation.fromFirestore(r))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Create from JSON
  factory AIBudgetModel.fromJson(Map<String, dynamic> json) {
    return AIBudgetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      monthlyLimit: (json['monthlyLimit'] ?? 0).toDouble(),
      weeklyLimit: (json['weeklyLimit'] ?? 0).toDouble(),
      dailyLimit: (json['dailyLimit'] ?? 0).toDouble(),
      settings: AIBudgetSettings.fromJson(json['settings'] ?? {}),
      analytics: AIBudgetAnalytics.fromJson(json['analytics'] ?? {}),
      predictedSpending: (json['predictedSpending'] ?? 0).toDouble(),
      riskScore: (json['riskScore'] ?? 0).toDouble(),
      healthStatus: BudgetHealthStatus.values[json['healthStatus'] ?? 0],
      insights: (json['insights'] as List?)
          ?.map((i) => AIInsight.fromJson(i))
          .toList() ?? [],
      recommendations: (json['recommendations'] as List?)
          ?.map((r) => AIRecommendation.fromJson(r))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'monthlyLimit': monthlyLimit,
      'weeklyLimit': weeklyLimit,
      'dailyLimit': dailyLimit,
      'settings': settings.toJson(),
      'analytics': analytics.toJson(),
      'predictedSpending': predictedSpending,
      'riskScore': riskScore,
      'healthStatus': healthStatus.index,
      'insights': insights.map((i) => i.toJson()).toList(),
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// AI Budget Settings
class AIBudgetSettings extends Equatable {
  final bool autoAdjustment;
  final bool smartNotifications;
  final bool predictiveAlerts;
  final NotificationFrequency frequency;
  final double alertThreshold;
  final bool learningMode;
  final bool proactiveAdvice;
  final bool riskAnalysis;

  const AIBudgetSettings({
    required this.autoAdjustment,
    required this.smartNotifications,
    required this.predictiveAlerts,
    required this.frequency,
    required this.alertThreshold,
    required this.learningMode,
    required this.proactiveAdvice,
    required this.riskAnalysis,
  });

  @override
  List<Object?> get props => [
    autoAdjustment,
    smartNotifications,
    predictiveAlerts,
    frequency,
    alertThreshold,
    learningMode,
    proactiveAdvice,
    riskAnalysis,
  ];

  AIBudgetSettings copyWith({
    bool? autoAdjustment,
    bool? smartNotifications,
    bool? predictiveAlerts,
    NotificationFrequency? frequency,
    double? alertThreshold,
    bool? learningMode,
    bool? proactiveAdvice,
    bool? riskAnalysis,
  }) {
    return AIBudgetSettings(
      autoAdjustment: autoAdjustment ?? this.autoAdjustment,
      smartNotifications: smartNotifications ?? this.smartNotifications,
      predictiveAlerts: predictiveAlerts ?? this.predictiveAlerts,
      frequency: frequency ?? this.frequency,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      learningMode: learningMode ?? this.learningMode,
      proactiveAdvice: proactiveAdvice ?? this.proactiveAdvice,
      riskAnalysis: riskAnalysis ?? this.riskAnalysis,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'autoAdjustment': autoAdjustment,
      'smartNotifications': smartNotifications,
      'predictiveAlerts': predictiveAlerts,
      'frequency': frequency.index,
      'alertThreshold': alertThreshold,
      'learningMode': learningMode,
      'proactiveAdvice': proactiveAdvice,
      'riskAnalysis': riskAnalysis,
    };
  }

  factory AIBudgetSettings.fromFirestore(Map<String, dynamic> data) {
    return AIBudgetSettings(
      autoAdjustment: data['autoAdjustment'] ?? false,
      smartNotifications: data['smartNotifications'] ?? true,
      predictiveAlerts: data['predictiveAlerts'] ?? true,
      frequency: NotificationFrequency.values[data['frequency'] ?? 1],
      alertThreshold: (data['alertThreshold'] ?? 0.8).toDouble(),
      learningMode: data['learningMode'] ?? true,
      proactiveAdvice: data['proactiveAdvice'] ?? true,
      riskAnalysis: data['riskAnalysis'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => toFirestore();
  factory AIBudgetSettings.fromJson(Map<String, dynamic> json) => 
      AIBudgetSettings.fromFirestore(json);
}

/// AI Budget Analytics
class AIBudgetAnalytics extends Equatable {
  final double averageSpending;
  final double spendingVariance;
  final Map<String, double> spendingPatterns;
  final List<SpendingTrend> trends;
  final double confidenceScore;
  final DateTime lastAnalyzed;
  final int totalTransactions;
  final double accuracyRate;

  const AIBudgetAnalytics({
    required this.averageSpending,
    required this.spendingVariance,
    required this.spendingPatterns,
    required this.trends,
    required this.confidenceScore,
    required this.lastAnalyzed,
    required this.totalTransactions,
    required this.accuracyRate,
  });

  @override
  List<Object?> get props => [
    averageSpending,
    spendingVariance,
    spendingPatterns,
    trends,
    confidenceScore,
    lastAnalyzed,
    totalTransactions,
    accuracyRate,
  ];

  AIBudgetAnalytics copyWith({
    double? averageSpending,
    double? spendingVariance,
    Map<String, double>? spendingPatterns,
    List<SpendingTrend>? trends,
    double? confidenceScore,
    DateTime? lastAnalyzed,
    int? totalTransactions,
    double? accuracyRate,
  }) {
    return AIBudgetAnalytics(
      averageSpending: averageSpending ?? this.averageSpending,
      spendingVariance: spendingVariance ?? this.spendingVariance,
      spendingPatterns: spendingPatterns ?? this.spendingPatterns,
      trends: trends ?? this.trends,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      lastAnalyzed: lastAnalyzed ?? this.lastAnalyzed,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      accuracyRate: accuracyRate ?? this.accuracyRate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'averageSpending': averageSpending,
      'spendingVariance': spendingVariance,
      'spendingPatterns': spendingPatterns,
      'trends': trends.map((t) => t.toFirestore()).toList(),
      'confidenceScore': confidenceScore,
      'lastAnalyzed': Timestamp.fromDate(lastAnalyzed),
      'totalTransactions': totalTransactions,
      'accuracyRate': accuracyRate,
    };
  }

  factory AIBudgetAnalytics.fromFirestore(Map<String, dynamic> data) {
    return AIBudgetAnalytics(
      averageSpending: (data['averageSpending'] ?? 0).toDouble(),
      spendingVariance: (data['spendingVariance'] ?? 0).toDouble(),
      spendingPatterns: Map<String, double>.from(data['spendingPatterns'] ?? {}),
      trends: (data['trends'] as List?)
          ?.map((t) => SpendingTrend.fromFirestore(t))
          .toList() ?? [],
      confidenceScore: (data['confidenceScore'] ?? 0).toDouble(),
      lastAnalyzed: (data['lastAnalyzed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalTransactions: data['totalTransactions'] ?? 0,
      accuracyRate: (data['accuracyRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => toFirestore();
  factory AIBudgetAnalytics.fromJson(Map<String, dynamic> json) => 
      AIBudgetAnalytics.fromFirestore(json);
}

/// AI Insight
class AIInsight extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final double importance;
  final DateTime createdAt;
  final bool isActionable;
  final String? actionText;
  final Map<String, dynamic>? actionData;

  const AIInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.importance,
    required this.createdAt,
    required this.isActionable,
    this.actionText,
    this.actionData,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    importance,
    createdAt,
    isActionable,
    actionText,
    actionData,
  ];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'importance': importance,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActionable': isActionable,
      'actionText': actionText,
      'actionData': actionData,
    };
  }

  factory AIInsight.fromFirestore(Map<String, dynamic> data) {
    return AIInsight(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      importance: (data['importance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActionable: data['isActionable'] ?? false,
      actionText: data['actionText'],
      actionData: data['actionData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => toFirestore();
  factory AIInsight.fromJson(Map<String, dynamic> json) => 
      AIInsight.fromFirestore(json);
}

/// AI Recommendation
class AIRecommendation extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type;
  final double priority;
  final DateTime createdAt;
  final bool isImplemented;
  final String? implementation;
  final double? estimatedImpact;

  const AIRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.createdAt,
    required this.isImplemented,
    this.implementation,
    this.estimatedImpact,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    priority,
    createdAt,
    isImplemented,
    implementation,
    estimatedImpact,
  ];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'isImplemented': isImplemented,
      'implementation': implementation,
      'estimatedImpact': estimatedImpact,
    };
  }

  factory AIRecommendation.fromFirestore(Map<String, dynamic> data) {
    return AIRecommendation(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      priority: (data['priority'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isImplemented: data['isImplemented'] ?? false,
      implementation: data['implementation'],
      estimatedImpact: (data['estimatedImpact'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => toFirestore();
  factory AIRecommendation.fromJson(Map<String, dynamic> json) => 
      AIRecommendation.fromFirestore(json);
}

/// Spending Trend
class SpendingTrend extends Equatable {
  final String period;
  final double value;
  final double change;
  final String direction;
  final DateTime date;

  const SpendingTrend({
    required this.period,
    required this.value,
    required this.change,
    required this.direction,
    required this.date,
  });

  @override
  List<Object?> get props => [period, value, change, direction, date];

  Map<String, dynamic> toFirestore() {
    return {
      'period': period,
      'value': value,
      'change': change,
      'direction': direction,
      'date': Timestamp.fromDate(date),
    };
  }

  factory SpendingTrend.fromFirestore(Map<String, dynamic> data) {
    return SpendingTrend(
      period: data['period'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      change: (data['change'] ?? 0).toDouble(),
      direction: data['direction'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
