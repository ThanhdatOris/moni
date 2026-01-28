import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moni/config/app_config.dart';
import 'package:provider/provider.dart';

import '../../../../../models/assistant/chat_message_model.dart';
import '../../../../../providers/connectivity_provider.dart';
import '../../../../../services/ai_services/ai_services.dart';
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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  bool _isKeyboardVisible = false;

  final AIProcessorService _aiService = GetIt.instance<AIProcessorService>();
  final ConversationService _conversationService = ConversationService();
  final UIOptimizationService _uiOptimization = UIOptimizationService();
  final GenUIService _genUIService = GenUIService();
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showQuickActions = true;
  int _streamingMessageIndex = -1; // Index của message đang stream
  List<String> _dynamicQuickActions = []; // GenUI-generated quick actions

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

    // Listen for focus changes
    _focusNode.addListener(_onFocusChange);

    WidgetsBinding.instance.addObserver(this);

    // FIX: Ensure keyboard is closed on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });
  }

  void _onFocusChange() {
    _uiOptimization.setChatFocused(_focusNode.hasFocus);
  }

  Future<void> _initializeConversation() async {
    await _conversationService.initialize();

    // Generate initial quick actions với GenUI
    _updateDynamicQuickActions();

    // Do NOT auto-create conversation here!
    // Let the user explicitly choose to start new or select from history

    setState(() {
      _messages = List.from(_conversationService.currentMessages);
    });
  }

  void _onConversationChanged() {
    if (mounted) {
      setState(() {
        _messages = List.from(_conversationService.currentMessages);
      });
      // Use delayed scroll to ensure ListView has rendered
      _scrollToBottom(delayed: true);
    }
  }

  @override
  void dispose() {
    _conversationService.removeListener(_onConversationChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = newValue;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // ✅ CHECK OFFLINE TRƯỚC KHI GỬI
    final connectivity = context.read<ConnectivityProvider>();
    if (connectivity.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💬 Chat AI cần kết nối internet. Hãy thử lại khi online!',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

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
      // Create placeholder message for streaming
      final aiMessage = ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _streamingMessageIndex = _messages.length;
        _messages.add(aiMessage);
        _isTyping = false;
      });

      // Use streaming for better UX - sử dụng method từ AIProcessorService
      // Method này tự động xử lý function calls và token management
      String fullResponse = '';

      // Pass history for context (excluding the placeholder AI message)
      final historyContext = _messages.take(_messages.length - 1).toList();

      await for (final chunk in _aiService.processChatInputStream(
        text.trim(),
        history: historyContext,
      )) {
        fullResponse += chunk;

        // Update streaming message in real-time
        if (mounted &&
            _streamingMessageIndex >= 0 &&
            _streamingMessageIndex < _messages.length) {
          setState(() {
            _messages[_streamingMessageIndex] = ChatMessage(
              text: fullResponse,
              isUser: false,
              timestamp: _messages[_streamingMessageIndex].timestamp,
            );
          });
          _scrollToBottom();
        }
      }

      // Extract transactionId from final response (if any)
      String? transactionId;
      String messageText = fullResponse;
      final editButtonRegex = RegExp(r'\[EDIT_BUTTON:([^\]]+)\]');
      final match = editButtonRegex.firstMatch(messageText);
      if (match != null) {
        transactionId = match.group(1);
        messageText = messageText.replaceAll(editButtonRegex, '[EDIT_BUTTON]');
      }

      // Finalize message
      final finalMessageIndex = _streamingMessageIndex;
      if (mounted &&
          finalMessageIndex >= 0 &&
          finalMessageIndex < _messages.length) {
        setState(() {
          _messages[finalMessageIndex] = ChatMessage(
            text: messageText,
            isUser: false,
            timestamp: _messages[finalMessageIndex].timestamp,
            transactionId: transactionId,
          );
          _streamingMessageIndex = -1;
        });

        // Save AI response to ConversationService
        await _conversationService.addMessage(_messages[finalMessageIndex]);

        // Update dynamic quick actions với GenUI sau khi có response mới
        _updateDynamicQuickActions();
      } else if (fullResponse.isNotEmpty) {
        // Fallback: create message if index is invalid
        final finalMessage = ChatMessage(
          text: messageText,
          isUser: false,
          timestamp: DateTime.now(),
          transactionId: transactionId,
        );
        await _conversationService.addMessage(finalMessage);

        // Update dynamic quick actions với GenUI
        _updateDynamicQuickActions();
      }
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
    _scrollToBottom();
  }

  void _deleteMessage(ChatMessage message) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin nhắn?'),
        content: const Text('Bạn có chắc chắn muốn xóa tin nhắn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _conversationService.deleteMessage(message);
      // Update UI explicitly if needed, but listener should handle it
      // _onConversationChanged will trigger setState
    }
  }

  void _scrollToBottom({bool delayed = false}) {
    void doScroll() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    if (delayed) {
      // For conversation loading, wait a bit longer for ListView to render
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => doScroll());
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => doScroll());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có cuộc trò chuyện nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bắt đầu cuộc trò chuyện mới hoặc\nchọn từ lịch sử để tiếp tục',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Button to create new conversation
            ElevatedButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo cuộc trò chuyện mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Hint to go to history tab
            TextButton.icon(
              onPressed: () {
                // Find ChatbotScreen's TabController and switch to History tab
                // Using a simple approach - this will be handled by parent
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '💡 Chuyển sang tab "Lịch sử" để xem các cuộc trò chuyện trước',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.history, size: 18, color: Colors.grey[600]),
              label: Text(
                'Xem lịch sử trò chuyện',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Start a new conversation explicitly
  Future<void> _startNewConversation() async {
    try {
      await _conversationService.startNewConversation();
      setState(() {
        _messages = List.from(_conversationService.currentMessages);
      });
      _updateDynamicQuickActions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo cuộc trò chuyện: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        return ChatMessageWidget(
          message: message,
          isLast: isLast,
          onDelete: () => _deleteMessage(message),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
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

  /// Update dynamic quick actions với GenUI
  Future<void> _updateDynamicQuickActions() async {
    try {
      final actions = await _genUIService.generateQuickActions(_messages);
      if (mounted) {
        setState(() {
          _dynamicQuickActions = actions;
        });
      }
    } catch (e) {
      // Fallback về default actions nếu có lỗi
      if (mounted) {
        setState(() {
          _dynamicQuickActions = [
            'Phân tích chi tiêu tháng này',
            'Kế hoạch tiết kiệm',
            'Đầu tư 10 triệu',
            'Tips quản lý tài chính',
          ];
        });
      }
    }
  }

  Widget _buildQuickActions() {
    // Sử dụng GenUI-generated actions nếu có, nếu không dùng default
    final quickActions = _dynamicQuickActions.isNotEmpty
        ? _dynamicQuickActions
        : [
            'Phân tích chi tiêu tháng này',
            'Kế hoạch tiết kiệm',
            'Đầu tư 10 triệu',
            'Tips quản lý tài chính',
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0),
              Colors.white,
            ],
            stops: const [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstOut,
        child: SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < quickActions.length - 1 ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => _sendMessage(action),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        action,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        final isOffline = connectivity.isOffline;
        return AnimatedBuilder(
          animation: _uiOptimization,
          builder: (context, child) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                // FIX: Sử dụng _isKeyboardVisible từ WidgetsBindingObserver để đảm bảo chính xác
                _isKeyboardVisible ? 12.0 : 120.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                // Giảm/loại bỏ hiệu ứng đổ bóng hướng lên gây cảm giác "vệt xám" che nội dung phía trên
                boxShadow: const [],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: isOffline ? 0.5 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOffline ? Colors.grey[200] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _messageController,
                          enabled: !isOffline,
                          decoration: InputDecoration(
                            hintText: isOffline
                                ? 'Cần internet để chat...'
                                : 'Nhập tin nhắn...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            prefixIcon: isOffline
                                ? Icon(
                                    Icons.wifi_off_rounded,
                                    size: 18,
                                    color: Colors.orange.shade600,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isOffline ? 8 : 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: _sendMessage,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isOffline
                        ? null
                        : () => _sendMessage(_messageController.text),
                    child: Opacity(
                      opacity: isOffline ? 0.5 : 1.0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: isOffline
                              ? LinearGradient(
                                  colors: [Colors.grey, Colors.grey.shade400],
                                )
                              : LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.8),
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
