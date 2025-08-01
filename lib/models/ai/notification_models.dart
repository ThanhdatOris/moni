// =============================================================================
// AI NOTIFICATION MODELS
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// =============================================================================
// ENUMS
// =============================================================================

enum AlertImportance { low, medium, high }

enum RecurringInterval { daily, weekly, biWeekly, monthly }

enum NotificationFrequency { daily, weekly, monthly }

// =============================================================================
// CORE MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'data': data,
    };
  }

  factory AlertContext.fromJson(Map<String, dynamic> json) {
    return AlertContext(
      type: json['type'] ?? '',
      categoryId: json['categoryId'],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'peakHours': peakHours,
      'peakDays': peakDays,
      'averageTransactionsPerDay': averageTransactionsPerDay,
      'preferredNotificationTime': {
        'hour': preferredNotificationTime.hour,
        'minute': preferredNotificationTime.minute,
      },
    };
  }

  factory UserBehavior.fromJson(Map<String, dynamic> json) {
    final notificationTime = json['preferredNotificationTime'] ?? {'hour': 9, 'minute': 0};
    return UserBehavior(
      peakHours: List<int>.from(json['peakHours'] ?? []),
      peakDays: List<int>.from(json['peakDays'] ?? []),
      averageTransactionsPerDay: (json['averageTransactionsPerDay'] ?? 0).toDouble(),
      preferredNotificationTime: TimeOfDay(
        hour: notificationTime['hour'] ?? 9,
        minute: notificationTime['minute'] ?? 0,
      ),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      'type': type,
      'suitability': suitability,
    };
  }

  factory OptimalTime.fromJson(Map<String, dynamic> json) {
    final timeData = json['time'] ?? {'hour': 9, 'minute': 0};
    return OptimalTime(
      time: TimeOfDay(
        hour: timeData['hour'] ?? 9,
        minute: timeData['minute'] ?? 0,
      ),
      type: json['type'] ?? '',
      suitability: (json['suitability'] ?? 0).toDouble(),
    );
  }
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

// =============================================================================
// FINANCIAL MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'potentialSaving': potentialSaving,
      'confidence': confidence,
      'actionable': actionable,
      'action': action,
    };
  }

  factory FinancialOpportunity.fromJson(Map<String, dynamic> json) {
    return FinancialOpportunity(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      categoryId: json['categoryId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      potentialSaving: (json['potentialSaving'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      actionable: json['actionable'] ?? false,
      action: json['action'] ?? '',
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'categoryId': categoryId,
      'severity': severity,
      'title': title,
      'description': description,
      'probability': probability,
      'impact': impact,
      'mitigation': mitigation,
    };
  }

  factory FinancialRisk.fromJson(Map<String, dynamic> json) {
    return FinancialRisk(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      categoryId: json['categoryId'] ?? '',
      severity: json['severity'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
      impact: (json['impact'] ?? 0).toDouble(),
      mitigation: json['mitigation'] ?? '',
    );
  }
}
