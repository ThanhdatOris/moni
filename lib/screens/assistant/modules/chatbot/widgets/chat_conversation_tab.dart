import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:moni/config/app_config.dart';
import '../../../../../services/ai_services/ai_services.dart';
import '../../../../../models/assistant/chat_message_model.dart';
import '../../../services/ui_optimization_service.dart';
import '../services/conversation_service.dart';
import 'chat_message_widget.dart';

/// Modern conversation tab with enhanced chat interface
class ChatConversationTab extends StatefulWidget {
  const ChatConversationTab({super.key});

  @override
  State<ChatConversationTab> createState() => _ChatConversationTabState();
}

class _ChatConversationTabState extends State<ChatConversationTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AIProcessorService _aiService = GetIt.instance<AIProcessorService>();
  final ConversationService _conversationService = ConversationService();
  final UIOptimizationService _uiOptimization = UIOptimizationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showQuickActions = true;

  @override
  void initState() {
    super.initState();
    _initializeConversation();

    // Set active module cho UI optimization
    _uiOptimization.setActiveModule('chatbot');

    // Listen for text field focus
    _messageController.addListener(() {
      _uiOptimization.setTyping(_messageController.text.isNotEmpty);
    });

    // Listen for conversation changes
    _conversationService.addListener(_onConversationChanged);
  }

  Future<void> _initializeConversation() async {
    await _conversationService.initialize();

    if (_conversationService.currentConversationId == null) {
      await _conversationService.startNewConversation();
    }

    setState(() {
      _messages = List.from(_conversationService.currentMessages);
    });
  }

  void _onConversationChanged() {
    if (mounted) {
      setState(() {
        _messages = List.from(_conversationService.currentMessages);
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _conversationService.removeListener(_onConversationChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
      _showQuickActions = false;
    });

    // Save user message
    await _conversationService.addMessage(userMessage);

    _messageController.clear();
    _scrollToBottom();

    try {
      // Direct AI call without wrapper layers
      final response = await _aiService.processChatInput(text.trim());

      // Extract transactionId from EDIT_BUTTON marker in text
      String? transactionId;
      String messageText = response;

      final editButtonRegex = RegExp(r'\[EDIT_BUTTON:([^\]]+)\]');
      final match = editButtonRegex.firstMatch(messageText);
      if (match != null) {
        transactionId = match.group(1);
        // Remove the marker from display text but keep [EDIT_BUTTON] for widget detection
        messageText = messageText.replaceAll(editButtonRegex, '[EDIT_BUTTON]');
      }

      final aiMessage = ChatMessage(
        text: messageText,
        isUser: false,
        timestamp: DateTime.now(),
        transactionId: transactionId,
      );

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });

      // Save AI response
      await _conversationService.addMessage(aiMessage);
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Xin lỗi, có lỗi xảy ra khi xử lý tin nhắn. Vui lòng thử lại.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isTyping = false;
      });

      // Save error message
      await _conversationService.addMessage(errorMessage);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Messages list với dynamic padding cho menubar
          Expanded(
            child: AnimatedBuilder(
              animation: _uiOptimization,
              builder: (context, child) {
                // Không thêm bottom spacing nhân tạo ở đây để tránh khoảng xám giữa danh sách và gợi ý/input
                return _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList();
              },
            ),
          ),

          // Quick actions (when visible)
          if (_showQuickActions) _buildQuickActions(),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bắt đầu cuộc trò chuyện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hỏi tôi về tài chính, đầu tư, hay ngân sách',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 16, 16, _showQuickActions ? 0 : 16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        final isLast = index == _messages.length - 1;
        return ChatMessageWidget(message: message, isLast: isLast);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: Duration(milliseconds: 600 + (index * 200)),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đang nhập...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final quickActions = [
      'Phân tích chi tiêu tháng này',
      'Kế hoạch tiết kiệm',
      'Đầu tư 10 triệu',
      'Tips quản lý tài chính',
    ];

    return Container(
      // Dùng padding thay vì margin để khoảng cách 6px là nền trắng
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Câu hỏi gợi ý:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: quickActions
                .map(
                  (action) => GestureDetector(
                    onTap: () => _sendMessage(action),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        action,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        // Giảm/loại bỏ hiệu ứng đổ bóng hướng lên gây cảm giác "vệt xám" che nội dung phía trên
        boxShadow: const [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8)
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
