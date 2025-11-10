import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/injection_container.dart' as di;
import '../../models/budget_alert_model.dart';
import '../analytics/budget_alert_service.dart';

/// Service Provider
final budgetAlertServiceProvider = Provider<BudgetAlertService>((ref) {
  return di.getIt<BudgetAlertService>();
});

/// Base Provider - Query tất cả alerts (1 query duy nhất)
final allAlertsProvider = StreamProvider<List<BudgetAlertModel>>((ref) {
  final service = ref.watch(budgetAlertServiceProvider);
  return service.getAlerts();
});

/// Derived Provider - Active alerts (filter từ cache)
final activeAlertsProvider = Provider<List<BudgetAlertModel>>((ref) {
  final all = ref.watch(allAlertsProvider).value ?? [];
  return all
      .where((a) => a.isEnabled && a.isActive)
      .toList();
});

/// Derived Provider - Alert theo ID (tìm từ cache)
final alertByIdProvider = Provider.family<BudgetAlertModel?, String>((ref, alertId) {
  final all = ref.watch(allAlertsProvider).value ?? [];
  try {
    return all.firstWhere(
      (a) => a.alertId == alertId,
      orElse: () => throw StateError('Alert not found'),
    );
  } catch (e) {
    return null;
  }
});

/// Derived Provider - Enabled alerts (filter từ cache)
final enabledAlertsProvider = Provider<List<BudgetAlertModel>>((ref) {
  final all = ref.watch(allAlertsProvider).value ?? [];
  return all.where((a) => a.isEnabled).toList();
});

