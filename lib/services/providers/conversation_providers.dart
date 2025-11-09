import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart' as di;
import '../../models/conversation_model.dart';
import '../analytics/conversation_service.dart';

/// Service Provider
final conversationServiceProvider = Provider<ConversationService>((ref) {
  return di.getIt<ConversationService>();
});

/// Base Provider - Query tất cả conversations (1 query duy nhất)
final allConversationsProvider = StreamProvider<List<ConversationModel>>((ref) {
  final service = ref.watch(conversationServiceProvider);
  return service.getConversations();
});

/// Derived Provider - Conversation theo ID (tìm từ cache)
final conversationByIdProvider = Provider.family<ConversationModel?, String>((ref, conversationId) {
  final all = ref.watch(allConversationsProvider).value ?? [];
  try {
    return all.firstWhere(
      (c) => c.conversationId == conversationId,
      orElse: () => throw StateError('Conversation not found'),
    );
  } catch (e) {
    return null;
  }
});

/// Derived Provider - Active conversations (filter từ cache)
final activeConversationsProvider = Provider<List<ConversationModel>>((ref) {
  final all = ref.watch(allConversationsProvider).value ?? [];
  return all.where((c) => c.isActive).toList();
});

/// Derived Provider - Recent conversations với limit
final recentConversationsProvider = Provider.family<List<ConversationModel>, int>((ref, limit) {
  final all = ref.watch(allConversationsProvider).value ?? [];
  return all.take(limit).toList();
});

