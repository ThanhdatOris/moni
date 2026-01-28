import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:moni/services/analytics/chat_log_service.dart';
import 'package:moni/services/analytics/conversation_service.dart' as cloud;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../models/assistant/chat_message_model.dart';
import '../../../services/real_data_service.dart';

/// Enhanced conversation service with ChangeNotifier for real-time updates
class ConversationService extends ChangeNotifier {
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;
  ConversationService._internal();

  static const String _conversationsKey = 'chatbot_conversations';
  static const String _currentConversationKey = 'current_conversation_id';
  static const String _deletedConversationsKey = 'deleted_conversation_ids';

  // Cloud services
  final cloud.ConversationService _cloudConversationService =
      cloud.ConversationService();
  final ChatLogService _chatLogService = ChatLogService();

  // Current conversation state
  String? _currentConversationId;
  final List<ChatMessage> _currentMessages = [];
  final RealDataService _realDataService = GetIt.instance<RealDataService>();

  // Getters
  String? get currentConversationId => _currentConversationId;
  List<ChatMessage> get currentMessages => List.unmodifiable(_currentMessages);

  /// Initialize the conversation service
  /// Note: Does NOT auto-create new conversation. Call startNewConversation() explicitly if needed.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentConversationId = prefs.getString(_currentConversationKey);
    // Real data service already initialized via DI

    // Sync history from cloud in background
    _syncHistoryFromCloud();

    // Only load existing conversation if available
    // Do NOT auto-create new conversation to avoid redundant conversations
    if (_currentConversationId != null) {
      await _loadCurrentConversation();
    }
    // If no conversation, leave it empty - UI should show "select or create" prompt
  }

  /// Sync conversation history from Cloud to Local
  Future<void> _syncHistoryFromCloud() async {
    try {
      // Get conversations from Firestore (using stream but taking first snapshot)
      final conversationsStream = _cloudConversationService.getConversations();
      final cloudConversations = await conversationsStream.first;

      if (cloudConversations.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final localJsonList = prefs.getStringList(_conversationsKey) ?? [];

      // Get list of deleted conversation IDs to skip
      final deletedIds = prefs.getStringList(_deletedConversationsKey) ?? [];
      final deletedIdsSet = deletedIds.toSet();

      // Convert local JSONs to map for easier merging
      final Map<String, ConversationSummary> localMap = {};
      for (final json in localJsonList) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final summary = ConversationSummary.fromJson(data);
        localMap[summary.id] = summary;
      }

      // Merge cloud data (skip deleted ones)
      bool hasChanges = false;
      for (final cloudConv in cloudConversations) {
        // Skip if this conversation was deleted locally
        if (deletedIdsSet.contains(cloudConv.conversationId)) {
          continue;
        }

        // If cloud conversation is newer or doesn't exist locally
        if (!localMap.containsKey(cloudConv.conversationId) ||
            cloudConv.updatedAt.isAfter(
              localMap[cloudConv.conversationId]!.lastUpdate,
            )) {
          localMap[cloudConv.conversationId] = ConversationSummary(
            id: cloudConv.conversationId,
            title: cloudConv.title,
            lastMessage: '...', // Placeholder, will be updated when loaded
            lastUpdate: cloudConv.updatedAt,
            messageCount: cloudConv.messageCount,
          );
          hasChanges = true;
        }
      }

      if (hasChanges) {
        final updatedList = localMap.values
            .map((s) => jsonEncode(s.toJson()))
            .toList();
        await prefs.setStringList(_conversationsKey, updatedList);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ConversationService] Error syncing from cloud: $e');
    }
  }

  /// Start a new conversation
  Future<void> startNewConversation() async {
    // Generate unique ID with timestamp + random to avoid collisions
    // Or use cloud service to generate ID if online
    try {
      // Try to create on cloud first to get valid ID
      final cloudId = await _cloudConversationService
          .createConversationWithTitle(firstQuestion: 'New Conversation');
      _currentConversationId = cloudId;
    } catch (e) {
      // Fallback to local ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      _currentConversationId = 'temp_${timestamp}_$random';
    }

    _currentMessages.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentConversationKey, _currentConversationId!);

    // Always add welcome message for new conversations
    await addWelcomeMessage();

    // Save conversation immediately so it appears in history
    await _saveCurrentConversation();
    notifyListeners();
  }

  /// Add welcome message to current conversation
  Future<void> addWelcomeMessage() async {
    String welcomeContent =
        '👋 Xin chào! Tôi là AI Assistant của Moni. Tôi có thể giúp bạn:\n\n• Phân tích tài chính cá nhân\n• Lập kế hoạch ngân sách\n• Tư vấn đầu tư\n• Theo dõi chi tiêu\n\nBạn muốn tôi hỗ trợ điều gì?';

    // Try to add real data context
    try {
      final summary = await _realDataService.getSpendingSummary();
      if (summary.isNotEmpty) {
        final balance = summary['balance'] as double? ?? 0;
        final transactionCount = summary['transaction_count'] as int? ?? 0;

        if (transactionCount > 0) {
          welcomeContent +=
              '\n\n📊 Tôi thấy bạn có $transactionCount giao dịch. ';
          if (balance > 0) {
            welcomeContent += 'Tình hình tài chính khá tốt! 👍';
          } else {
            welcomeContent += 'Hãy cùng xem xét ngân sách nhé! 💡';
          }
        }
      }
    } catch (e) {
      // Use default message if real data fails
    }

    final welcomeMessage = ChatMessage(
      text: welcomeContent,
      isUser: false,
      timestamp: DateTime.now(),
    );

    _currentMessages.insert(0, welcomeMessage);
  }

  /// Add message to current conversation
  Future<void> addMessage(ChatMessage message) async {
    _currentMessages.add(message);
    await _saveCurrentConversation();

    // Sync to Cloud
    if (_currentConversationId != null && message.text.isNotEmpty) {
      try {
        // Create chat log in cloud
        await _chatLogService.createLog(
          question: message.isUser ? message.text : '',
          response: !message.isUser ? message.text : '',
          conversationId: _currentConversationId!,
          transactionId: message.transactionId,
        );

        // Update conversation stats
        await _cloudConversationService.incrementMessageCount(
          _currentConversationId!,
        );

        // Update title if it's the first user message
        if (message.isUser &&
            _currentMessages.where((m) => m.isUser).length == 1) {
          await _cloudConversationService.updateConversationTitle(
            conversationId: _currentConversationId!,
            newTitle: message.text.length > 30
                ? '${message.text.substring(0, 30)}...'
                : message.text,
          );
        }
      } catch (e) {
        // Ignore cloud sync errors, local is primary for UI
      }
    }

    notifyListeners(); // Notify UI about changes
  }

  /// Delete a specific message
  Future<void> deleteMessage(ChatMessage message) async {
    _currentMessages.remove(message);
    await _saveCurrentConversation();
    notifyListeners();
  }

  /// Load specific conversation by ID
  Future<void> loadConversation(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(
        'conversation_messages_$conversationId',
      );

      _currentMessages.clear();
      bool loadedFromLocal = false;

      if (messagesJson != null) {
        final messagesList = jsonDecode(messagesJson) as List;
        if (messagesList.isNotEmpty) {
          for (final messageData in messagesList) {
            final message = ChatMessage(
              text: messageData['text'] as String,
              isUser: messageData['isUser'] as bool,
              timestamp: DateTime.parse(messageData['timestamp'] as String),
              transactionId: messageData['transactionId'] as String?,
            );
            _currentMessages.add(message);
          }
          loadedFromLocal = true;
        }
      }

      // If local is empty, try to load from Cloud
      if (!loadedFromLocal) {
        try {
          // Use getLogsOnce for reliable fetching
          final logs = await _chatLogService.getLogsOnce(
            conversationId: conversationId,
          );

          if (logs.isNotEmpty) {
            // Convert logs to messages
            // Note: ChatLogModel has question AND response in one doc
            // We need to split them into separate messages and sort by time
            final List<ChatMessage> cloudMessages = [];

            for (final log in logs) {
              // User question
              if (log.question.isNotEmpty) {
                cloudMessages.add(
                  ChatMessage(
                    text: log.question,
                    isUser: true,
                    timestamp: log.createdAt,
                  ),
                );
              }
              // AI response
              if (log.response.isNotEmpty) {
                cloudMessages.add(
                  ChatMessage(
                    text: log.response,
                    isUser: false,
                    timestamp: log.createdAt.add(
                      const Duration(milliseconds: 100),
                    ), // Ensure response is after question
                    transactionId: log.transactionId,
                  ),
                );
              }
            }

            // Sort by timestamp
            cloudMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

            _currentMessages.addAll(cloudMessages);

            // Save to local for next time
            if (_currentMessages.isNotEmpty) {
              await _saveConversationMessages(conversationId);
            }
          } else {
            // If truly empty (new conversation), add welcome
            await addWelcomeMessage();
          }
        } catch (e) {
          // Cloud load failed, just add welcome
          await addWelcomeMessage();
        }
      }

      _currentConversationId = conversationId;

      // Save current conversation ID to persist selection
      await prefs.setString(_currentConversationKey, conversationId);

      notifyListeners(); // Notify UI about conversation change
    } catch (e) {
      // Handle error loading conversation
      // print('Error loading conversation $conversationId: $e');
    }
  }

  /// Get conversation history
  Future<List<ConversationSummary>> getConversationHistory() async {
    // Trigger background sync
    _syncHistoryFromCloud();

    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getStringList(_conversationsKey) ?? [];

    return conversationsJson.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return ConversationSummary.fromJson(data);
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
  }

  /// Save current conversation
  Future<void> _saveCurrentConversation() async {
    // Don't save if no conversation ID
    if (_currentConversationId == null) return;

    // Save even with only welcome message, but skip if truly empty
    if (_currentMessages.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final conversations = prefs.getStringList(_conversationsKey) ?? [];

    // Create conversation summary
    final summary = ConversationSummary(
      id: _currentConversationId!,
      title: _generateConversationTitle(),
      lastMessage: _currentMessages.last.text,
      lastUpdate: DateTime.now(),
      messageCount: _currentMessages.length,
    );

    // Remove existing conversation with same ID
    conversations.removeWhere((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return data['id'] == _currentConversationId;
    });

    // Add updated conversation
    conversations.add(jsonEncode(summary.toJson()));

    // Keep only last 50 conversations
    if (conversations.length > 50) {
      conversations.removeRange(0, conversations.length - 50);
    }

    await prefs.setStringList(_conversationsKey, conversations);

    // Save individual messages for this conversation
    await _saveConversationMessages(_currentConversationId!);
  }

  /// Save conversation messages separately for loading
  Future<void> _saveConversationMessages(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesData = _currentMessages
        .map(
          (message) => {
            'text': message.text,
            'isUser': message.isUser,
            'timestamp': message.timestamp.toIso8601String(),
            'transactionId': message.transactionId,
          },
        )
        .toList();

    await prefs.setString(
      'conversation_messages_$conversationId',
      jsonEncode(messagesData),
    );
  }

  /// Load conversation by ID
  Future<void> _loadCurrentConversation() async {
    if (_currentConversationId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(
        'conversation_messages_$_currentConversationId',
      );

      if (messagesJson != null) {
        final messagesList = jsonDecode(messagesJson) as List;
        _currentMessages.clear();

        for (final messageData in messagesList) {
          final message = ChatMessage(
            text: messageData['text'] as String,
            isUser: messageData['isUser'] as bool,
            timestamp: DateTime.parse(messageData['timestamp'] as String),
            transactionId: messageData['transactionId'] as String?,
          );
          _currentMessages.add(message);
        }
      } else {
        // No messages found, start with welcome message
        _currentMessages.clear();
        await addWelcomeMessage();
      }
    } catch (e) {
      // print('Error loading current conversation: $e');
      _currentMessages.clear();
      await addWelcomeMessage();
    }
  }

  /// Generate conversation title from messages
  String _generateConversationTitle() {
    if (_currentMessages.isEmpty) return 'Cuộc trò chuyện mới';

    final userMessages = _currentMessages.where((msg) => msg.isUser).toList();

    if (userMessages.isEmpty) return 'Cuộc trò chuyện mới';

    final firstMessage = userMessages.first.text;
    if (firstMessage.length <= 30) return firstMessage;

    return '${firstMessage.substring(0, 30)}...';
  }

  /// Rename conversation
  Future<void> renameConversation(
    String conversationId,
    String newTitle,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = prefs.getStringList(_conversationsKey) ?? [];

      // Find and update conversation
      for (int i = 0; i < conversations.length; i++) {
        final data = jsonDecode(conversations[i]) as Map<String, dynamic>;
        if (data['id'] == conversationId) {
          data['title'] = newTitle;
          conversations[i] = jsonEncode(data);
          break;
        }
      }

      await prefs.setStringList(_conversationsKey, conversations);
      notifyListeners();
    } catch (e) {
      // print('Error renaming conversation: $e');
    }
  }

  /// Delete specific conversation
  Future<void> deleteConversation(String conversationId) async {
    debugPrint(
      '[ConversationService] deleteConversation called for: $conversationId',
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = prefs.getStringList(_conversationsKey) ?? [];
      debugPrint(
        '[ConversationService] Current conversations count: ${conversations.length}',
      );

      // Remove conversation from local list
      final beforeCount = conversations.length;
      conversations.removeWhere((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return data['id'] == conversationId;
      });
      debugPrint(
        '[ConversationService] Removed ${beforeCount - conversations.length} conversations',
      );

      // Remove conversation messages locally
      await prefs.remove('conversation_messages_$conversationId');

      // Update local list
      await prefs.setStringList(_conversationsKey, conversations);

      // Add to deleted IDs list to prevent re-sync from cloud
      final deletedIds = prefs.getStringList(_deletedConversationsKey) ?? [];
      if (!deletedIds.contains(conversationId)) {
        deletedIds.add(conversationId);
        await prefs.setStringList(_deletedConversationsKey, deletedIds);
        debugPrint('[ConversationService] Added to deleted IDs list');
      }

      debugPrint(
        '[ConversationService] Updated conversations list, new count: ${conversations.length}',
      );

      // If this was current conversation, clear it (don't auto-create new)
      if (_currentConversationId == conversationId) {
        debugPrint(
          '[ConversationService] Deleted current conversation, clearing state',
        );
        _currentConversationId = null;
        _currentMessages.clear();
        await prefs.remove(_currentConversationKey);
      }

      // Also delete from cloud (fire and forget, don't wait)
      _cloudConversationService.deleteConversation(conversationId).catchError((
        e,
      ) {
        debugPrint('[ConversationService] Error deleting from cloud: $e');
      });

      notifyListeners();
      debugPrint(
        '[ConversationService] deleteConversation completed successfully',
      );
    } catch (e) {
      debugPrint('[ConversationService] Error deleting conversation: $e');
    }
  }

  /// Clear all conversation history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_conversationsKey);
    await prefs.remove(_currentConversationKey);

    _currentConversationId = null;
    _currentMessages.clear();
    notifyListeners();
  }

  /// Get financial context for AI responses
  Future<Map<String, dynamic>> getFinancialContext() async {
    try {
      return await _realDataService.getSpendingSummary();
    } catch (e) {
      return {};
    }
  }

  /// Get recent transactions context
  Future<String> getRecentTransactionsContext() async {
    try {
      final transactions = await _realDataService.getRecentTransactions(
        limit: 5,
      );
      if (transactions.isEmpty) return 'Chưa có giao dịch nào gần đây.';

      String context = 'Giao dịch gần đây:\n';
      for (final transaction in transactions) {
        final typeIcon = transaction.type.value == 'income' ? '💰' : '💸';
        context +=
            '$typeIcon ${transaction.amount.toStringAsFixed(0)}đ - ${transaction.note ?? "Không ghi chú"}\n';
      }
      return context;
    } catch (e) {
      return 'Không thể lấy thông tin giao dịch.';
    }
  }
}

/// Conversation summary model
class ConversationSummary {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastUpdate;
  final int messageCount;

  ConversationSummary({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastUpdate,
    required this.messageCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lastMessage': lastMessage,
    'lastUpdate': lastUpdate.toIso8601String(),
    'messageCount': messageCount,
  };

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        lastMessage: json['lastMessage'] as String,
        lastUpdate: DateTime.parse(json['lastUpdate'] as String),
        messageCount: json['messageCount'] as int,
      );
}
