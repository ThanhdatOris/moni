import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/constants/enums.dart';

import '../../core/injection_container.dart' as di;
import '../../models/report_model.dart';
import '../analytics/report_service.dart';

/// Service Provider
final reportServiceProvider = Provider<ReportService>((ref) {
  return di.getIt<ReportService>();
});

/// Base Provider - Query tất cả reports (1 query duy nhất)
final allReportsProvider = StreamProvider<List<ReportModel>>((ref) {
  final service = ref.watch(reportServiceProvider);
  return service.getReports();
});

/// Derived Provider - Report theo ID (tìm từ cache)
final reportByIdProvider = Provider.family<ReportModel?, String>((ref, reportId) {
  final all = ref.watch(allReportsProvider).value ?? [];
  try {
    return all.firstWhere(
      (r) => r.reportId == reportId,
      orElse: () => throw StateError('Report not found'),
    );
  } catch (e) {
    return null;
  }
});

/// Derived Provider - Reports theo type (filter từ cache)
final reportsByTypeProvider = Provider.family<List<ReportModel>, ReportType>((ref, type) {
  final all = ref.watch(allReportsProvider).value ?? [];
  return all.where((r) => r.type == type).toList();
});

/// Derived Provider - Recent reports với limit
final recentReportsProvider = Provider.family<List<ReportModel>, int>((ref, limit) {
  final all = ref.watch(allReportsProvider).value ?? [];
  return all.take(limit).toList();
});

