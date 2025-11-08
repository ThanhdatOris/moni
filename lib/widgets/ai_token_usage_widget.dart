import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:moni/constants/app_colors.dart';
import '../services/ai_services/ai_processor_service.dart';

/// Widget hiển thị AI token usage cho user
class AITokenUsageWidget extends StatefulWidget {
  final bool showDetails;
  final bool compact;

  const AITokenUsageWidget({
    super.key,
    this.showDetails = true,
    this.compact = false,
  });

  @override
  State<AITokenUsageWidget> createState() => _AITokenUsageWidgetState();
}

class _AITokenUsageWidgetState extends State<AITokenUsageWidget> {
  final AIProcessorService _aiService = GetIt.instance<AIProcessorService>();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _aiService.getTokenUsageStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return const SizedBox.shrink();
    }

    final tokenCount = _stats!['dailyTokenCount'] as int;
    final tokenLimit = _stats!['dailyTokenLimit'] as int;
    final percentUsed = double.parse(_stats!['percentUsed']);
    final remaining = _stats!['remainingTokens'] as int;

    if (widget.compact) {
      return _buildCompactView(tokenCount, tokenLimit, percentUsed);
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.token, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'AI Token Usage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadStats,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentUsed / 100,
                minHeight: 20,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForUsage(percentUsed),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Used',
                  '$tokenCount',
                  Icons.trending_up,
                  _getColorForUsage(percentUsed),
                ),
                _buildStatItem(
                  'Remaining',
                  '$remaining',
                  Icons.battery_charging_full,
                  Colors.green,
                ),
                _buildStatItem(
                  'Limit',
                  '$tokenLimit',
                  Icons.flag,
                  Colors.grey,
                ),
              ],
            ),
            
            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              Text(
                'Usage: ${percentUsed.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _getColorForUsage(percentUsed),
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (_stats!['lastTokenReset'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Reset at: ${_formatResetTime(_stats!['lastTokenReset'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              Text(
                _getUsageMessage(percentUsed),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(int tokenCount, int tokenLimit, double percentUsed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getColorForUsage(percentUsed).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getColorForUsage(percentUsed).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.token,
            size: 16,
            color: _getColorForUsage(percentUsed),
          ),
          const SizedBox(width: 6),
          Text(
            '$tokenCount / $tokenLimit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getColorForUsage(percentUsed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getColorForUsage(double percent) {
    if (percent >= 90) return Colors.red;
    if (percent >= 80) return Colors.orange;
    if (percent >= 60) return Colors.amber;
    return Colors.green;
  }

  String _getUsageMessage(double percent) {
    if (percent >= 90) {
      return '⚠️ Bạn sắp hết quota AI hôm nay!';
    } else if (percent >= 80) {
      return '💡 Hãy sử dụng AI một cách hợp lý.';
    } else if (percent >= 50) {
      return '✅ Bạn đang sử dụng AI khá nhiều.';
    } else {
      return '🎉 Bạn còn nhiều quota để sử dụng AI!';
    }
  }

  String _formatResetTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final tomorrow = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day + 1,
      );
      return '${tomorrow.day}/${tomorrow.month}/${tomorrow.year} 00:00';
    } catch (e) {
      return 'Unknown';
    }
  }
}
