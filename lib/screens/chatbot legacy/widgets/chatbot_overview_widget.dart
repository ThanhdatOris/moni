import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_page_header.dart';
import '../chatbot_screen.dart';

/// Widget hiển thị overview của chatbot trong main navigation
class ChatbotOverviewWidget extends StatelessWidget {
  const ChatbotOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const CustomPageHeader(
              icon: Icons.smart_toy_rounded,
              title: 'Trợ lý AI',
              subtitle: 'Trợ lý tài chính thông minh của bạn',
            ),

            // Nội dung với padding 2 bên 20px - scroll dài theo screen
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Assistant Card
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const FullChatScreen(conversationId: null)),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withAlpha(77),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Moni AI Assistant',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Trợ lý AI sẵn sàng hỗ trợ bạn phân tích tài chính, lập kế hoạch tiết kiệm và trả lời mọi câu hỏi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withAlpha(77),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Online • Nhấn để chat',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Features List
                    const Text(
                      'Tính năng nổi bật',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Features items - không giới hạn chiều cao
                    _buildFeatureItem(
                      Icons.analytics_rounded,
                      'Phân tích chi tiêu',
                      'Phân tích chi tiêu theo danh mục và đưa ra gợi ý tối ưu hóa',
                      const Color(0xFF2196F3),
                    ),
                    _buildFeatureItem(
                      Icons.savings_rounded,
                      'Lập kế hoạch tiết kiệm',
                      'Hỗ trợ thiết lập mục tiêu và kế hoạch tiết kiệm phù hợp',
                      const Color(0xFF4CAF50),
                    ),
                    _buildFeatureItem(
                      Icons.lightbulb_rounded,
                      'Tư vấn tài chính',
                      'Đưa ra lời khuyên về đầu tư và quản lý tài chính cá nhân',
                      const Color(0xFFFF9800),
                    ),
                    _buildFeatureItem(
                      Icons.support_agent_rounded,
                      'Hỗ trợ 24/7',
                      'Trả lời câu hỏi và hỗ trợ sử dụng ứng dụng bất cứ lúc nào',
                      const Color(0xFF9C27B0),
                    ),

                    // Thêm khoảng trống ở cuối để đảm bảo scroll mượt
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      IconData icon, String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
