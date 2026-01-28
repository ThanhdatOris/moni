import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/config/app_config.dart';

import '../../../../../../utils/helpers/category_icon_helper.dart';
import '../../../../../models/assistant/chat_message_model.dart';
import '../../../../../services/providers/providers.dart';
import '../../../../history/transaction_detail_screen.dart';
import 'typing_dots.dart';

/// Widget hiển thị một tin nhắn trong cuộc hội thoại
class ChatMessageWidget extends ConsumerWidget {
  final ChatMessage message;
  final VoidCallback? onEditTransaction;
  final VoidCallback? onDelete;
  final bool isLast;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onEditTransaction,
    this.onDelete,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
            child: GestureDetector(
              onLongPress: () => _showOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFFFF6B35)
                      : Colors.white,
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
                      : Border.all(color: AppColors.grey200, width: 1),
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
                    if (!message.isUser && message.transactionId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildTransactionCategoryBadge(
                          ref,
                          message.transactionId!,
                        ),
                      ),
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
                      _buildAIMessage(message),

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
                        // Hiển thị khi có transactionId (không cần check [EDIT_BUTTON] marker vì đã được extract)
                        if (!message.isUser && message.transactionId != null)
                          TextButton.icon(
                            onPressed: () {
                              _editTransaction(
                                context,
                                ref,
                                message.transactionId!,
                              );
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Chỉnh sửa'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
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

  Widget _buildAIMessage(ChatMessage msg) {
    // Show typing dots if text is empty (loading state)
    if (msg.text.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Moni đang suy nghĩ',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            TypingDots(color: AppColors.primary, size: 5),
          ],
        ),
      );
    }

    // Clean up the text and separate edit button markers
    String cleanText = msg.text
        .replaceAll('[EDIT_BUTTON]', '')
        .replaceAll('[/EDIT_BUTTON]', '');

    // Nếu đã hiển thị badge danh mục ở header, loại bỏ dòng Danh mục trong nội dung
    if (!msg.isUser && msg.transactionId != null) {
      final filtered = cleanText
          .split('\n')
          .where((line) {
            final t = line.trimLeft().toLowerCase();
            if (t.startsWith('📁')) return false;
            if (t.contains('danh mục') || t.contains('danh muc')) return false;
            if (t.contains('category:')) return false;
            return true;
          })
          .toList()
          .join('\n');
      cleanText = filtered;
    }

    return SelectableText.rich(
      _parseMarkdownText(cleanText),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildTransactionCategoryBadge(WidgetRef ref, String transactionId) {
    // Sử dụng Riverpod providers thay vì GetIt
    // transactionByIdProvider là Provider.family, trả về TransactionModel? trực tiếp
    final transaction = ref.watch(transactionByIdProvider(transactionId));

    if (transaction == null) {
      return const SizedBox.shrink();
    }

    // Sử dụng category provider
    // categoryByIdProvider là Provider.family, trả về CategoryModel? trực tiếp
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));

    if (category == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CategoryIconHelper.buildIcon(
          category,
          size: 18,
          showBackground: true,
          backgroundColor: Colors.white,
          isCompact: true,
        ),
        const SizedBox(width: 8),
        Text(
          category.name,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  TextSpan _parseMarkdownText(String text) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        // Bold text
        spans.add(
          TextSpan(
            text: line.substring(2, line.length - 2),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        );
      } else if (line.startsWith('• ')) {
        // Bullet points
        spans.add(
          TextSpan(
            text: line,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
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
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return TextSpan(children: spans);
  }

  void _editTransaction(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
  ) async {
    try {
      // Sử dụng Riverpod provider để lấy transaction
      // transactionByIdProvider là Provider.family, trả về TransactionModel? trực tiếp
      final transaction = ref.read(transactionByIdProvider(transactionId));

      if (transaction == null) {
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
              margin: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                100,
              ), // ← Margin to avoid input area
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
        // Navigating to transaction detail screen
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
          // Transaction updated successfully
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
              margin: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                100,
              ), // ← Margin to avoid input area
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
            margin: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              100,
            ), // ← Margin to avoid input area
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

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Sao chép nội dung'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép vào bộ nhớ tạm'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text(
                'Xóa tin nhắn',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onDelete != null) {
                  onDelete!();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
