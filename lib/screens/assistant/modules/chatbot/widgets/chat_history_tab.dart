import 'package:flutter/material.dart';

import 'package:moni/config/app_config.dart';
import '../services/conversation_service.dart';

/// Chat history tab showing conversation history
class ChatHistoryTab extends StatefulWidget {
  final TabController? tabController;

  const ChatHistoryTab({
    super.key,
    this.tabController,
  });

  @override
  State<ChatHistoryTab> createState() => _ChatHistoryTabState();
}

class _ChatHistoryTabState extends State<ChatHistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ConversationService _conversationService = ConversationService();
  List<ConversationSummary> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
  }

  Future<void> _loadConversationHistory() async {
    setState(() => _isLoading = true);

    try {
      final conversations = await _conversationService.getConversationHistory();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải lịch sử: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statistics và New Conversation button
          _buildHeader(),

          const SizedBox(height: 16),

          // Conversation list với spacing cho menubar
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _buildConversationList(),
                ),
                // Bottom spacing for menubar
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const double h = 104;
    return Column(
      children: [
        SizedBox(
          height: h,
          child: Row(
            children: [
              Expanded(
                child: _headerStat(
                  icon: Icons.chat_bubble_outline,
                  title: 'Cuộc trò chuyện',
                  value: '${_conversations.length}',
                  color: AppColors.primary,
                  height: h,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _headerStat(
                  icon: Icons.message,
                  title: 'Tin nhắn',
                  value:
                      '${_conversations.fold(0, (count, c) => count + c.messageCount)}',
                  color: AppColors.info,
                  height: h,
                ),
              ),
              const SizedBox(width: 12),
              _headerActions(h),
            ],
          ),
        ),
        //const SizedBox(height: 12),
      ],
    );
  }

  Widget _headerStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required double height,
  }) =>
      _buildStatCard(
        icon: icon,
        title: title,
        value: value,
        color: color,
        height: height,
      );

  Widget _headerActions(double height) => SizedBox(
        width: 56,
        height: height,
        child: Column(
          children: [
            Expanded(
              child: _buildSquareIconButton(
                icon: Icons.refresh,
                color: AppColors.info,
                onPressed: _loadConversationHistory,
                tooltip: 'Làm mới',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildSquareIconButton(
                icon: Icons.add,
                color: AppColors.success,
                onPressed: _createNewConversation,
                tooltip: 'Tạo mới',
              ),
            ),
          ],
        ),
      );

  Widget _buildSquareIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final button = Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox.expand(),
      ),
    );

    final stack = Stack(
      children: [
        Positioned.fill(child: button),
        const Positioned.fill(
          child: IgnorePointer(child: SizedBox()),
        ),
        Positioned.fill(
          child: Center(
            child: Icon(icon, color: AppColors.textWhite, size: 22),
          ),
        ),
      ],
    );

    return tooltip == null ? stack : Tooltip(message: tooltip, child: stack);
  }

  Future<void> _createNewConversation() async {
    try {
      await _conversationService.startNewConversation();

      // Switch to Chat tab (index 0) để người dùng có thể chat ngay
      widget.tabController?.animateTo(0);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tạo cuộc trò chuyện mới!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Refresh conversation list
      await _loadConversationHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tạo cuộc trò chuyện: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    double? height,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
    return height != null ? SizedBox(height: height, child: card) : card;
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationCard(conversation);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu trò chuyện với AI để xem lịch sử',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(ConversationSummary conversation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _openConversation(conversation),
          onLongPress: () => _showConversationOptions(conversation),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conversation.messageCount} tin nhắn',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                conversation.lastMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatRelativeTime(conversation.lastUpdate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openConversation(ConversationSummary conversation) async {
    try {
      // Load conversation in service
      await _conversationService.loadConversation(conversation.id);

      // Switch to Chat tab (index 0)
      widget.tabController?.animateTo(0);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tải cuộc trò chuyện: ${conversation.title}'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải cuộc trò chuyện: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showConversationOptions(
      ConversationSummary conversation) async {
    // Đảm bảo không có TextField nào đang focus trước khi mở sheet
    FocusScope.of(context).unfocus();

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              conversation.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Đổi tên cuộc trò chuyện'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa cuộc trò chuyện'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(conversation);
              },
            ),
          ],
        ),
      ),
    );

    // Khi sheet đóng, tiếp tục unfocus để tránh bàn phím tự bật lại
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  void _showRenameDialog(ConversationSummary conversation) {
    final controller = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi tên cuộc trò chuyện'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                // Cache Navigator before async gap
                final navigator = Navigator.of(dialogContext);
                
                await _conversationService.renameConversation(
                    conversation.id, newTitle);
                await _loadConversationHistory();
                
                // Use cached navigator instead of context
                navigator.pop();
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ConversationSummary conversation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: Text(
            'Bạn có chắc muốn xóa cuộc trò chuyện "${conversation.title}"?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Cache Navigator before async gap
              final navigator = Navigator.of(dialogContext);
              
              await _conversationService.deleteConversation(conversation.id);
              await _loadConversationHistory();
              
              // Use cached navigator instead of context
              navigator.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
