import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart' as di;
import '../../models/chat_log_model.dart';
import '../analytics/chat_log_service.dart';

/// Service Provider
final chatLogServiceProvider = Provider<ChatLogService>((ref) {
  return di.getIt<ChatLogService>();
});

/// Base Provider - Query tất cả chat logs (1 query duy nhất)
/// Note: Có thể filter theo conversationId nếu cần
final allChatLogsProvider = StreamProvider<List<ChatLogModel>>((ref) {
  final service = ref.watch(chatLogServiceProvider);
  return service.getLogs();
});

/// Derived Provider - Chat logs theo conversation ID (filter từ cache)
final chatLogsByConversationProvider = Provider.family<List<ChatLogModel>, String>((ref, conversationId) {
  final all = ref.watch(allChatLogsProvider).value ?? [];
  return all
      .where((log) => log.conversationId == conversationId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Derived Provider - Chat log theo transaction ID (tìm từ cache)
final chatLogByTransactionIdProvider = Provider.family<ChatLogModel?, String>((ref, transactionId) {
  final all = ref.watch(allChatLogsProvider).value ?? [];
  try {
    return all.firstWhere(
      (log) => log.transactionId == transactionId,
      orElse: () => throw StateError('Chat log not found'),
    );
  } catch (e) {
    return null;
  }
});

/// Derived Provider - Recent chat logs với limit
final recentChatLogsProvider = Provider.family<List<ChatLogModel>, int>((ref, limit) {
  final all = ref.watch(allChatLogsProvider).value ?? [];
  return all.take(limit).toList();
});

