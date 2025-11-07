import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../constants/app_colors.dart';
import '../../models/chat_log_model.dart';
import '../../services/services.dart';
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
  
  // ✅ NEW: Flag để theo dõi đã hiển thị welcome message trong session
  static bool _hasShownWelcomeInSession = false;

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
        // ✅ IMPROVED: Chỉ hiển thị welcome nếu không có conversation (UI only, không lưu DB)
        if (_messages.isEmpty && !_hasShownWelcomeInSession) {
          _addWelcomeMessage();
          _hasShownWelcomeInSession = true;
        }
        return;
      }

      // Nếu là temp conversation, không load history
      if (_currentConversationId!.startsWith('temp_')) {
        // ✅ IMPROVED: Temp conversation cũng hiển thị welcome (UI only)
        if (_messages.isEmpty && !_hasShownWelcomeInSession) {
          _addWelcomeMessage();
          _hasShownWelcomeInSession = true;
        }
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
        // ✅ IMPROVED: Build new messages list from actual chat logs
        final List<ChatMessage> newMessages = [];
        
        // Load actual chat messages from database
        for (final log in logs.reversed) {
          newMessages.add(ChatMessage(
            text: log.question,
            isUser: true,
            timestamp: log.createdAt,
          ));
          newMessages.add(ChatMessage(
            text: log.response,
            isUser: false,
            timestamp: log.createdAt,
            transactionId: log.transactionId,
          ));
        }
        
        // ✅ IMPROVED: Replace messages in single setState to avoid flash
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(newMessages);
          });
          _scrollToBottom();
        }
      } else {
        // ✅ IMPROVED: Nếu có conversation nhưng không có chat logs → hiển thị welcome (UI only)
        if (_messages.isEmpty && !_hasShownWelcomeInSession) {
          _addWelcomeMessage();
          _hasShownWelcomeInSession = true;
        }
      }
    } catch (e) {
      _logger.e('Error loading chat history: $e');
      if (mounted) {
        // ✅ IMPROVED: Lỗi loading → hiển thị welcome như fallback (UI only)
        if (_messages.isEmpty && !_hasShownWelcomeInSession) {
          _addWelcomeMessage();
          _hasShownWelcomeInSession = true;
        }
      }
    }
  }

  void _addWelcomeMessage() {
    // ✅ IMPORTANT: Đây chỉ là UI message, KHÔNG lưu vào database
    // Welcome message chỉ hiển thị để giới thiệu tính năng, không phải chat log thực sự
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
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
            tooltip: 'Tạo cuộc trò chuyện mới', // ✅ Updated tooltip
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

      // ✅ IMPROVED: Kiểm tra nếu response là error message từ service
      final isErrorResponse = _isErrorResponse(aiResponse);

      // Extract transactionId from AI response if it contains [EDIT_BUTTON:transactionId]
      String? transactionId;
      String cleanResponse = aiResponse;

      if (!isErrorResponse) {
        final editButtonRegex = RegExp(r'\[EDIT_BUTTON:([^\]]+)\]');
        final match = editButtonRegex.firstMatch(aiResponse);
        if (match != null) {
          transactionId = match.group(1);
          cleanResponse = aiResponse.replaceAll(editButtonRegex, '[EDIT_BUTTON]');
        }

        // ✅ IMPROVED: Chỉ lưu chat log nếu không phải error response
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
      } else {
        // ✅ NEW: Log error nhưng không lưu vào chat history
        _logger.w('AI service returned error response, not saving to chat log');
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
      // ✅ SIMPLIFIED: Service đã xử lý tất cả logic lỗi
      _logger.e('Error in _sendMessage: $e');
      
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "😅 Đã có lỗi không mong muốn trong ứng dụng. Vui lòng thử lại.\n\nNếu vấn đề tiếp tục, hãy khởi động lại ứng dụng! 🔄",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
  }

  void _navigateToConversationList() {
    // ✅ ADDED: Navigation guard to prevent stack accumulation
    final routeStack = Navigator.of(context);
    
    // Check if ConversationListScreen is already in the stack
    bool conversationListExists = false;
    routeStack.popUntil((route) {
      if (route.settings.name?.contains('ConversationListScreen') == true) {
        conversationListExists = true;
      }
      return true; // Don't actually pop, just check
    });
    
    if (conversationListExists) {
      // ConversationListScreen already exists in stack, not pushing
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConversationListScreen(),
      ),
    );
  }

  void _navigateBackToChatbotTab() {
    // ✅ SIMPLIFIED: Simple pop logic
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        // Successfully popped back
      } else {
        // Cannot pop, navigator stack is empty
      }
    } catch (e) {
      // Error in navigation: $e
    }
  }

  void _clearChat() async {
    // ✅ CHANGED: Create new conversation instead of just clearing frontend
    try {
      // Create new conversation
      final newConversationId = await _conversationService.createConversation(
        title: 'Cuộc trò chuyện mới',
      );
      
      setState(() {
        _messages.clear();
        _currentConversationId = newConversationId; // Set to new conversation
        _conversationTitle = 'Cuộc trò chuyện mới'; // Set new title
        // ✅ IMPROVED: Reset welcome flag, nhưng không hiển thị message ngay
        // User sẽ thấy welcome message khi load lại conversation (nếu không có chat logs)
        _hasShownWelcomeInSession = false;
      });
      
      // ✅ NEW: Load chat history để hiển thị welcome message nếu cần
      await _loadChatHistory();
      
      // Created new conversation: $newConversationId
    } catch (e) {
      // Error creating new conversation: $e
      
      // Fallback to old behavior if conversation creation fails
      setState(() {
        _messages.clear();
        _currentConversationId = null;
        _conversationTitle = 'Moni AI Assistant'; // Reset về tiêu đề mặc định
        // ✅ IMPROVED: Reset welcome flag, nhưng không hiển thị message ngay
        _hasShownWelcomeInSession = false;
      });
      
      // ✅ NEW: Load chat history để hiển thị welcome message nếu cần
      await _loadChatHistory();
    }
    
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

  /// ✅ NEW: Kiểm tra nếu AI response là error message
  bool _isErrorResponse(String response) {
    // Kiểm tra các pattern error message từ AI service
    final errorIndicators = [
      '🤖 AI đang quá tải',
      '⏰ Bạn đã gửi quá nhiều',
      '🔐 Có vấn đề với xác thực',
      '📶 Kết nối mạng không ổn định',
      '💳 Đã vượt quá giới hạn',
      '🤖 Mô hình AI tạm thời',
      '📝 Yêu cầu không hợp lệ',
      '🔧 Máy chủ AI đang gặp sự cố',
      '⚠️ Nội dung tin nhắn không phù hợp',
      '😅 Đã có lỗi không mong muốn',
      'Mã lỗi:', // Indicator của generic error
    ];

    return errorIndicators.any((indicator) => response.contains(indicator));
  }
}
