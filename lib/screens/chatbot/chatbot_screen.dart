import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../constants/app_colors.dart';
import '../../models/chat_log_model.dart';
import '../../services/ai_processor_service.dart';
import '../../services/chat_log_service.dart';
import '../../services/conversation_service.dart';
import '../home/home_screen.dart';
import 'conversation_list_screen.dart';
import 'models/chat_message_model.dart';
import 'widgets/chat_input_widget.dart';
import 'widgets/chat_message_widget.dart';
import 'widgets/chatbot_overview_widget.dart';
import 'widgets/typing_indicator_widget.dart';

/// Màn hình chính của chatbot - hiển thị trong main navigation
class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatbotOverviewWidget();
  }
}

/// Màn hình chat đầy đủ - ẩn menubar
class FullChatScreen extends StatefulWidget {
  final String? conversationId; // ID của cuộc hội thoại hiện tại

  const FullChatScreen({super.key, this.conversationId});

  @override
  State<FullChatScreen> createState() => _FullChatScreenState();
}

class _FullChatScreenState extends State<FullChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _currentConversationId;
  String _conversationTitle = 'Moni AI Assistant'; // Tiêu đề mặc định

  // Services
  final GetIt _getIt = GetIt.instance;
  late final AIProcessorService _aiService;
  late final ChatLogService _chatLogService;
  late final ConversationService _conversationService;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();

    // Initialize services
    _aiService = _getIt<AIProcessorService>();
    _chatLogService = _getIt<ChatLogService>();
    _conversationService = _getIt<ConversationService>();

    // Initialize conversation and load chat history
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    try {
      // Lấy hoặc tạo conversation
      _currentConversationId = widget.conversationId ??
          await _conversationService.getOrCreateActiveConversation();

      // Load tiêu đề conversation nếu có conversation ID cụ thể
      await _loadConversationTitle();

      // Load chat history
      await _loadChatHistory();
    } catch (e) {
      _logger.e('Error initializing conversation: $e');
      // Fallback to welcome message if initialization fails
      _addWelcomeMessage();
    }
  }

  Future<void> _loadConversationTitle() async {
    try {
      if (_currentConversationId != null && !_currentConversationId!.startsWith('temp_')) {
        final conversation = await _conversationService.getConversation(_currentConversationId!);
        if (conversation != null && mounted) {
          setState(() {
            _conversationTitle = conversation.title;
          });
        }
      }
    } catch (e) {
      _logger.w('Error loading conversation title: $e');
      // Giữ tiêu đề mặc định nếu có lỗi
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      if (_currentConversationId == null) {
        _addWelcomeMessage();
        return;
      }

      // Nếu là temp conversation, không load history
      if (_currentConversationId!.startsWith('temp_')) {
        _addWelcomeMessage();
        return;
      }
      
      // Load chat logs từ Firestore
      final logs = await _chatLogService
          .getLogs(
            conversationId: _currentConversationId,
            limit: 20,
          )
          .timeout(const Duration(seconds: 15))
          .first
          .catchError((error) {
        _logger.w('Error loading chat logs: $error');
        return <ChatLogModel>[];
      });

      if (logs.isNotEmpty) {
        // Clear existing messages trước khi load
        _messages.clear();
        
        // Load chat messages
        for (final log in logs.reversed) {
          _messages.add(ChatMessage(
            text: log.question,
            isUser: true,
            timestamp: log.createdAt,
          ));
          _messages.add(ChatMessage(
            text: log.response,
            isUser: false,
            timestamp: log.createdAt,
            transactionId: log.transactionId,
          ));
        }
      } else {
        _addWelcomeMessage();
      }

      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    } catch (e) {
      _logger.e('Error loading chat history: $e');
      if (mounted) {
        _addWelcomeMessage();
        setState(() {});
      }
    }
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text:
          "Xin chào! Tôi là Moni AI - trợ lý tài chính thông minh của bạn! 👋\n\nTôi có thể giúp bạn:\n\n📊 Phân tích chi tiêu và thu nhập\n💰 Lập kế hoạch tiết kiệm\n💡 Tư vấn tài chính cá nhân\n🎯 Đặt và theo dõi mục tiêu tài chính\n❓ Trả lời câu hỏi về ứng dụng\n\nHãy cho tôi biết bạn cần hỗ trợ gì nhé! 😊",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: _navigateBackToChatbotTab,
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFFB56B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversationTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToConversationList,
            icon: const Icon(Icons.history_rounded,
                color: AppColors.textSecondary),
            tooltip: 'Quản lý hội thoại',
          ),
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            tooltip: 'Làm mới cuộc trò chuyện',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatMessageWidget(message: _messages[index]);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping) const TypingIndicatorWidget(),

          // Input area
          ChatInputWidget(
            controller: _messageController,
            onSendMessage: _sendMessage,
            isTyping: _isTyping,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Thêm tin nhắn người dùng
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Đảm bảo có conversation với tiêu đề động
      if (_currentConversationId == null) {
        _currentConversationId =
            await _conversationService.getOrCreateActiveConversation(
          firstQuestion: text,
        );
        
        // Load tiêu đề conversation mới được tạo
        await _loadConversationTitle();
      }

      // Gọi AI service
      final aiResponse = await _aiService.processChatInput(text);

      // Extract transactionId from AI response if it contains [EDIT_BUTTON:transactionId]
      String? transactionId;
      String cleanResponse = aiResponse;

      final editButtonRegex = RegExp(r'\[EDIT_BUTTON:([^\]]+)\]');
      final match = editButtonRegex.firstMatch(aiResponse);
      if (match != null) {
        transactionId = match.group(1);
        cleanResponse = aiResponse.replaceAll(editButtonRegex, '[EDIT_BUTTON]');
      }

      // Lưu log chat với thông tin giao dịch nếu có
      await _chatLogService.createLog(
        question: text,
        response: cleanResponse,
        conversationId: _currentConversationId!,
        transactionId: transactionId,
        transactionData: transactionId != null
            ? {
                'transactionId': transactionId,
                'createdAt': DateTime.now().toIso8601String(),
              }
            : null,
      );

      // Tăng message count cho conversation (chỉ khi không phải conversation tạm thời)
      if (!_currentConversationId!.startsWith('temp_')) {
        try {
          await _conversationService
              .incrementMessageCount(_currentConversationId!);
        } catch (e) {
          // Bỏ qua lỗi nếu không thể tăng message count
          _logger.e('Không thể tăng message count: $e');
        }
      }

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: cleanResponse,
          isUser: false,
          timestamp: DateTime.now(),
          transactionId: transactionId,
        ));
      });
    } catch (e) {
      // Fallback nếu có lỗi
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text:
              "Xin lỗi, tôi đang gặp một chút trục trặc. Vui lòng thử lại sau ít phút. 😅\n\nLỗi: ${e.toString()}",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
  }

  void _navigateToConversationList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConversationListScreen(),
      ),
    );
  }

  void _navigateBackToChatbotTab() {
    // Quay về màn hình trước đó, nếu không có thì về HomeScreen
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Nếu không có màn hình nào trong stack, tạo HomeScreen mới
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _currentConversationId = null;
      _conversationTitle = 'Moni AI Assistant'; // Reset về tiêu đề mặc định
      _messages.add(ChatMessage(
        text:
            "🔄 Cuộc trò chuyện đã được làm mới!\n\nTôi sẵn sàng hỗ trợ bạn với những câu hỏi mới về tài chính. Hãy bắt đầu bằng cách cho tôi biết bạn cần giúp đỡ gì nhé! 😊",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
