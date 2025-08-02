import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/chat_conversation_tab.dart';

/// Simple conversation service for chatbot state management
class ConversationService {
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;
  ConversationService._internal();

  static const String _conversationsKey = 'chatbot_conversations';
  static const String _currentConversationKey = 'current_conversation_id';
  static const String _welcomeShownKey = 'welcome_message_shown';

  // Current conversation state
  String? _currentConversationId;
  List<ChatMessage> _currentMessages = [];
  bool _welcomeMessageShown = false;

  // Getters
  String? get currentConversationId => _currentConversationId;
  List<ChatMessage> get currentMessages => List.unmodifiable(_currentMessages);
  bool get welcomeMessageShown => _welcomeMessageShown;

  /// Initialize the conversation service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentConversationId = prefs.getString(_currentConversationKey);
    _welcomeMessageShown = prefs.getBool(_welcomeShownKey) ?? false;
    
    if (_currentConversationId != null) {
      await _loadCurrentConversation();
    }
  }

  /// Start a new conversation
  Future<void> startNewConversation() async {
    _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentMessages.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentConversationKey, _currentConversationId!);
    
    // Add welcome message if not shown before
    if (!_welcomeMessageShown) {
      addWelcomeMessage();
      _welcomeMessageShown = true;
      await prefs.setBool(_welcomeShownKey, true);
    }
  }

  /// Add welcome message to current conversation
  void addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: '👋 Xin chào! Tôi là AI Assistant của Moni. Tôi có thể giúp bạn:\n\n• Phân tích tài chính cá nhân\n• Lập kế hoạch ngân sách\n• Tư vấn đầu tư\n• Theo dõi chi tiêu\n\nBạn muốn tôi hỗ trợ điều gì?',
      isFromUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.welcome,
    );
    
    _currentMessages.insert(0, welcomeMessage);
  }

  /// Add message to current conversation
  Future<void> addMessage(ChatMessage message) async {
    _currentMessages.add(message);
    await _saveCurrentConversation();
  }

  /// Get conversation history
  Future<List<ConversationSummary>> getConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getStringList(_conversationsKey) ?? [];
    
    return conversationsJson.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return ConversationSummary.fromJson(data);
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
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
      lastMessage: _currentMessages.last.content,
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
  }

  /// Load conversation by ID
  Future<void> _loadCurrentConversation() async {
    // For now, start fresh - could implement message persistence later
    _currentMessages.clear();
  }

  /// Generate conversation title from messages
  String _generateConversationTitle() {
    if (_currentMessages.isEmpty) return 'Cuộc trò chuyện mới';
    
    final userMessages = _currentMessages
        .where((msg) => msg.isFromUser && msg.type == ChatMessageType.text)
        .toList();
    
    if (userMessages.isEmpty) return 'Cuộc trò chuyện mới';
    
    final firstMessage = userMessages.first.content;
    if (firstMessage.length <= 30) return firstMessage;
    
    return '${firstMessage.substring(0, 30)}...';
  }

  /// Clear all conversation history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_conversationsKey);
    await prefs.remove(_currentConversationKey);
    await prefs.remove(_welcomeShownKey);
    
    _currentConversationId = null;
    _currentMessages.clear();
    _welcomeMessageShown = false;
  }

  /// Reset welcome message flag
  Future<void> resetWelcomeMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeShownKey, false);
    _welcomeMessageShown = false;
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

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    lastMessage: json['lastMessage'] as String,
    lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    messageCount: json['messageCount'] as int,
  );
}
