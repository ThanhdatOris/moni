import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../constants/app_colors.dart';
import '../../../../widgets/custom_page_header.dart';
import '../../../assistant/models/agent_request_model.dart';
import '../../../assistant/services/global_agent_service.dart';

/// Budget AI Module Screen - Intelligent budget suggestions
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final GlobalAgentService _agentService = GetIt.instance<GlobalAgentService>();
  final TextEditingController _incomeController = TextEditingController();
  bool _isLoading = false;
  String? _budgetSuggestion;
  
  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const CustomPageHeader(
              icon: Icons.account_balance_wallet_outlined,
              title: 'AI Budget',
              subtitle: 'Gợi ý ngân sách thông minh',
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input Section
                    _buildInputSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Budget Suggestions
                    Expanded(
                      child: _buildBudgetSection(),
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

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin thu nhập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Thu nhập hàng tháng (VND)',
                hintText: 'Ví dụ: 15000000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateBudgetSuggestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Tạo gợi ý ngân sách'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _analyzeBudgetPattern,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Phân tích'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Gợi ý ngân sách AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _budgetSuggestion != null
                  ? SingleChildScrollView(
                      child: Text(
                        _budgetSuggestion!,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nhập thu nhập và nhấn "Tạo gợi ý ngân sách"\nđể nhận tư vấn từ AI',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
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

  Future<void> _generateBudgetSuggestion() async {
    final incomeText = _incomeController.text.trim();
    if (incomeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập thu nhập hàng tháng')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final request = AgentRequest.budget(
        message: 'Tạo gợi ý ngân sách chi tiết cho thu nhập $incomeText VND/tháng. '
                'Bao gồm: phân bổ theo danh mục, mục tiêu tiết kiệm, và lời khuyên thực tế.',
        parameters: {
          'income': incomeText,
          'currency': 'VND',
          'goals': ['saving', 'emergency_fund', 'investment'],
        },
      );
      
      final response = await _agentService.processRequest(request);
      
      if (mounted) {
        if (response.isSuccess) {
          setState(() {
            _budgetSuggestion = response.message;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.error ?? "Không thể tạo gợi ý"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _analyzeBudgetPattern() async {
    setState(() => _isLoading = true);
    
    try {
      final request = AgentRequest.budget(
        message: 'Phân tích mô hình chi tiêu hiện tại của tôi và đưa ra lời khuyên '
                'để tối ưu hóa ngân sách. Bao gồm những khoản chi không cần thiết '
                'và cơ hội tiết kiệm.',
        parameters: {
          'analysis_type': 'pattern_analysis',
          'include_recommendations': true,
        },
      );
      
      final response = await _agentService.processRequest(request);
      
      if (mounted) {
        if (response.isSuccess) {
          setState(() {
            _budgetSuggestion = response.message;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.error ?? "Không thể phân tích"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
