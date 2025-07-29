import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../constants/app_colors.dart';
import '../../../services/transaction_service.dart';
import '../../history/transaction_detail_screen.dart';
import '../models/chat_message_model.dart';

/// Widget hiển thị một tin nhắn trong cuộc hội thoại
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onEditTransaction;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onEditTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFFB56B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFFFF6B35) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: AppColors.grey200,
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Render content với markdown support
                  if (message.isUser)
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  else
                    _buildAIMessage(message.text),

                  const SizedBox(height: 8),

                  // Time and edit button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),

                      // Edit button for AI messages with transaction info
                      if (!message.isUser &&
                          message.text.contains('[EDIT_BUTTON]') &&
                          message.transactionId != null)
                        TextButton.icon(
                          onPressed: () {
                            print('🔧 DEBUG: Attempting to edit transaction: ${message.transactionId}');
                            _editTransaction(context, message.transactionId!);
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Chỉnh sửa'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),

                      if (message.isUser) ...[
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIMessage(String text) {
    // Clean up the text and separate edit button markers
    String cleanText =
        text.replaceAll('[EDIT_BUTTON]', '').replaceAll('[/EDIT_BUTTON]', '');

    return SelectableText.rich(
      _parseMarkdownText(cleanText),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  TextSpan _parseMarkdownText(String text) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        // Bold text
        spans.add(TextSpan(
          text: line.substring(2, line.length - 2),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ));
      } else if (line.startsWith('• ')) {
        // Bullet points
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ));
      } else if (line.contains('**')) {
        // Inline bold text
        spans.add(_parseInlineBold(line));
      } else {
        // Regular text
        spans.add(TextSpan(text: line));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans);
  }

  TextSpan _parseInlineBold(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before bold
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return TextSpan(children: spans);
  }

  void _editTransaction(BuildContext context, String transactionId) async {
    print('🔧 DEBUG: Starting _editTransaction with ID: $transactionId');
    
    try {
      // Lấy thông tin giao dịch từ service
      final transactionService = GetIt.instance<TransactionService>();
      print('🔧 DEBUG: Got TransactionService instance');
      
      final transaction =
          await transactionService.getTransaction(transactionId);
      print('🔧 DEBUG: Retrieved transaction: ${transaction?.transactionId}');

      if (transaction == null) {
        print('❌ DEBUG: Transaction not found for ID: $transactionId');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Không tìm thấy giao dịch để chỉnh sửa',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating, // ← Floating behavior
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100), // ← Margin to avoid input area
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      // Navigate đến màn hình chi tiết giao dịch (tab Edit)
      if (context.mounted) {
        print('🔧 DEBUG: Navigating to transaction detail screen');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
              initialTabIndex: 1, // Open on Edit tab
            ),
          ),
        );

        // Nếu có kết quả trả về (giao dịch đã được cập nhật)
        if (result != null && context.mounted) {
          print('✅ DEBUG: Transaction updated successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Giao dịch đã được cập nhật thành công!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating, // ← Floating behavior
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100), // ← Margin to avoid input area
              duration: const Duration(seconds: 2), // ← Shorter duration
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lỗi khi mở giao dịch: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating, // ← Floating behavior
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100), // ← Margin to avoid input area
            duration: const Duration(seconds: 3), // ← Slightly longer for error
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
