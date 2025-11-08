import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';
import '../../services/ui_optimization_service.dart';
import '../../widgets/assistant_error_card.dart';
import '../../widgets/assistant_loading_card.dart';
import 'widgets/chat_conversation_tab.dart';
import 'widgets/chat_history_tab.dart';
import 'widgets/chat_settings_tab.dart';

/// Enhanced Chatbot Screen with modern tabbed interface matching other modules
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  final UIOptimizationService _uiOptimization = UIOptimizationService();

  @override
  void initState() {
    super.initState();
    // Default to History tab (index 1) instead of Chat tab (index 0)
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(_onInnerTabChanged);
    _initializeChatbot();
    // Đồng bộ trạng thái menubar theo tab hiện tại sau frame đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) => _onInnerTabChanged());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onInnerTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onInnerTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Chỉ ẩn menubar khi ở tab Chat (index 0)
    if (_tabController.index == 0) {
      _uiOptimization.enterAssistantChatMode();
    } else {
      _uiOptimization.exitAssistantChatMode();
    }
  }

  Future<void> _initializeChatbot() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Initialize chatbot services and load conversation history
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate initialization

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Lỗi khởi tạo chatbot: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar only (no redundant header)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(11), // Giảm từ 12 xuống 11
              color:
                  Colors.teal.shade600, // Solid teal thay vì gradient primary
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade600
                      .withValues(alpha: 0.3), // Đổi màu shadow
                  blurRadius: 4, // Giảm từ 6 xuống 4
                  offset: const Offset(0, 1), // Giảm từ 2 xuống 1
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600), // Giảm từ 12 xuống 10
            unselectedLabelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: const [
              Tab(
                height: 32, // Giảm từ 40 xuống 32
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 14), // Giảm size từ 16 xuống 14
                    SizedBox(width: 4), // Giảm từ 6 xuống 4
                    Text('Chat'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 14),
                    SizedBox(width: 4),
                    Text('Lịch sử'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, size: 14), // Giảm size từ 16 xuống 14
                    SizedBox(width: 4), // Giảm từ 6 xuống 4
                    Text('Cài đặt'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content with loading/error handling
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: AssistantLoadingCard(
          showTitle: true,
        ),
      );
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: AssistantErrorCard(
          errorMessage: _errorMessage ?? 'Có lỗi xảy ra khi khởi tạo chatbot',
          onRetry: _initializeChatbot,
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        const ChatConversationTab(),
        ChatHistoryTab(tabController: _tabController),
        const ChatSettingsTab(),
      ],
    );
  }
}
