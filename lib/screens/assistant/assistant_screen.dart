import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/custom_page_header.dart';
import 'modules/analytics/analytics_screen.dart';
import 'modules/budget/budget_screen.dart';
import 'modules/chatbot/chatbot_screen.dart';
import 'modules/reports/reports_screen.dart';
import 'widgets/assistant_module_card.dart';

/// Main Assistant Screen - Hub for all AI and analytics features
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Page Header
            const CustomPageHeader(
              icon: Icons.smart_toy_rounded,
              title: 'Trợ lý thông minh',
              subtitle: 'AI Assistant & Analytics Hub',
            ),
            
            // Module Cards Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // Chatbot Card - Updated to functional module
                    AssistantModuleCard(
                      title: 'AI Chatbot',
                      subtitle: 'Chat với AI thông minh',
                      icon: Icons.smart_toy_rounded,
                      gradient: const [AppColors.primary, AppColors.primaryDark],
                      onTap: () => _navigateToChatbot(context),
                    ),
                    
                    // Analytics Card  
                    AssistantModuleCard(
                      title: 'Phân tích thông minh',
                      subtitle: 'Báo cáo và insights',
                      icon: Icons.analytics_outlined,
                      gradient: const [Color(0xFF2196F3), Color(0xFF1976D2)],
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const AnalyticsScreen())
                      ),
                    ),
                    
                    // Budget AI Card
                    AssistantModuleCard(
                      title: 'AI Budget',
                      subtitle: 'Gợi ý ngân sách thông minh',
                      icon: Icons.account_balance_wallet_outlined,
                      gradient: const [Color(0xFF4CAF50), Color(0xFF388E3C)],
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const BudgetScreen())
                      ),
                    ),
                    
                    // Reports Card
                    AssistantModuleCard(
                      title: 'Báo cáo',
                      subtitle: 'Xuất báo cáo chi tiết',
                      icon: Icons.description_outlined,
                      gradient: const [Color(0xFFFF9800), Color(0xFFF57C00)],
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const ReportsScreen())
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToChatbot(BuildContext context) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const FullChatScreen())
    );
  }
}
