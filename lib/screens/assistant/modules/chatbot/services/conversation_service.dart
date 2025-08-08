import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/chat_message_model.dart';
import '../../../services/real_data_service.dart';

/// Enhanced conversation service with ChangeNotifier for real-time updates
class ConversationService extends ChangeNotifier {
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;
  ConversationService._internal();

  static const String _conversationsKey = 'chatbot_conversations';
  static const String _currentConversationKey = 'current_conversation_id';

  // Current conversation state
  String? _currentConversationId;
  final List<ChatMessage> _currentMessages = [];
  final RealDataService _realDataService = GetIt.instance<RealDataService>();

  // Getters
  String? get currentConversationId => _currentConversationId;
  List<ChatMessage> get currentMessages => List.unmodifiable(_currentMessages);

  /// Initialize the conversation service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentConversationId = prefs.getString(_currentConversationKey);
    // Real data service already initialized via DI

    // Load existing conversation if available, otherwise start new one
    if (_currentConversationId != null) {
      await _loadCurrentConversation();
    } else {
      await startNewConversation();
    }
  }

  /// Start a new conversation
  Future<void> startNewConversation() async {
    _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentMessages.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentConversationKey, _currentConversationId!);

    // Always add welcome message for new conversations
    await addWelcomeMessage();
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
    notifyListeners(); // Notify UI about changes
  }

  /// Load specific conversation by ID
  Future<void> loadConversation(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson =
          prefs.getString('conversation_messages_$conversationId');

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

        _currentConversationId = conversationId;
        notifyListeners(); // Notify UI about conversation change
      }
    } catch (e) {
      // Handle error loading conversation
      print('Error loading conversation $conversationId: $e');
    }
  }

  /// Get conversation history
  Future<List<ConversationSummary>> getConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getStringList(_conversationsKey) ?? [];

    return conversationsJson.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return ConversationSummary.fromJson(data);
    }).toList()
      ..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
  }

  /// Save current conversation
  Future<void> _saveCurrentConversation() async {
    if (_currentConversationId == null || _currentMessages.isEmpty) return;

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
        .map((message) => {
              'text': message.text,
              'isUser': message.isUser,
              'timestamp': message.timestamp.toIso8601String(),
              'transactionId': message.transactionId,
            })
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
      final messagesJson =
          prefs.getString('conversation_messages_$_currentConversationId');

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
      print('Error loading current conversation: $e');
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
      String conversationId, String newTitle) async {
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
      print('Error renaming conversation: $e');
    }
  }

  /// Delete specific conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = prefs.getStringList(_conversationsKey) ?? [];

      // Remove conversation from list
      conversations.removeWhere((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return data['id'] == conversationId;
      });

      // Remove conversation messages
      await prefs.remove('conversation_messages_$conversationId');

      // Update list
      await prefs.setStringList(_conversationsKey, conversations);

      // If this was current conversation, start new one
      if (_currentConversationId == conversationId) {
        await startNewConversation();
      }

      notifyListeners();
    } catch (e) {
      print('Error deleting conversation: $e');
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
      final transactions =
          await _realDataService.getRecentTransactions(limit: 5);
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
