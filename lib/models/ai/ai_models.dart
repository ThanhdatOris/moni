// =============================================================================
// AI MODELS BARREL EXPORT
// =============================================================================

import 'analytics_models.dart' as analytics_models;
// =============================================================================
// TYPE ALIASES FOR BACKWARD COMPATIBILITY
// =============================================================================

// Create aliases to avoid conflicts with existing models
import 'budget_models.dart' as budget_models;
import 'notification_models.dart' as notification_models;

// Extensions
export 'ai_extensions.dart';
// Analytics models
export 'analytics_models.dart';
// Budget models
export 'budget_models.dart';
// Notification models
export 'notification_models.dart';

// Export with different names to avoid conflicts
typedef NewSpendingAnalysis = budget_models.SpendingAnalysis;
typedef NewBudgetPrediction = budget_models.BudgetPrediction;
typedef NewBudgetRecommendation = budget_models.BudgetRecommendation;
typedef NewUserProfile = budget_models.UserProfile;
typedef NewBudgetAnalytics = budget_models.BudgetAnalytics;
typedef NewBudgetAdjustmentSuggestion = budget_models.BudgetAdjustmentSuggestion;
typedef NewAIInsight = budget_models.AIInsight;

typedef NewAlertContext = notification_models.AlertContext;
typedef NewUserBehavior = notification_models.UserBehavior;
typedef NewOptimalTime = notification_models.OptimalTime;
typedef NewIntelligentNotification = notification_models.IntelligentNotification;
typedef NewScheduledNotification = notification_models.ScheduledNotification;
typedef NewFinancialOpportunity = notification_models.FinancialOpportunity;
typedef NewFinancialRisk = notification_models.FinancialRisk;

typedef NewSpendingPatternAnalysis = analytics_models.SpendingPatternAnalysis;
typedef NewSpendingAnomaly = analytics_models.SpendingAnomaly;
typedef NewCashFlowPrediction = analytics_models.CashFlowPrediction;
typedef NewFinancialHealthScore = analytics_models.FinancialHealthScore;
