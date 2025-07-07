import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../core/di/injection_container.dart';
import '../services/anonymous_conversion_service.dart';
import '../services/offline_service.dart';
import '../services/offline_sync_service.dart';
import '../widgets/offline_status_banner.dart';

/// Example screen cho offline anonymous user
class OfflineAnonymousExampleScreen extends StatefulWidget {
  const OfflineAnonymousExampleScreen({super.key});

  @override
  State<OfflineAnonymousExampleScreen> createState() => _OfflineAnonymousExampleScreenState();
}

class _OfflineAnonymousExampleScreenState extends State<OfflineAnonymousExampleScreen> {
  late final OfflineService _offlineService;
  late final OfflineSyncService _syncService;
  late final AnonymousConversionService _conversionService;
  
  bool _isOnline = true;
  OfflineDataStats? _offlineStats;
  Map<String, dynamic>? _userSession;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeData();
    _startConnectivityMonitoring();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _initializeServices() {
    _offlineService = getIt<OfflineService>();
    _syncService = getIt<OfflineSyncService>();
    _conversionService = getIt<AnonymousConversionService>();
  }

  void _initializeData() {
    _loadOfflineStats();
    _loadUserSession();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadOfflineStats();
      }
    });
  }

  void _loadOfflineStats() async {
    try {
      final stats = await _syncService.getOfflineDataStats();
      if (mounted) {
        setState(() {
          _offlineStats = stats;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _loadUserSession() async {
    try {
      final session = await _offlineService.getOfflineUserSession();
      if (mounted) {
        setState(() {
          _userSession = session;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offline Anonymous User',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: _isOnline ? Colors.green : Colors.red,
            ),
            onPressed: _showConnectivityInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Status Banner
          OfflineStatusBanner(
            offlineService: _offlineService,
            syncService: _syncService,
            isAnonymousUser: true,
            onSyncPressed: _handleSyncPressed,
          ),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserSessionCard(),
                  const SizedBox(height: 16),
                  _buildOfflineStatsCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  const SizedBox(height: 16),
                  _buildConversionCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSessionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'User Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_userSession != null) ...[
              _buildInfoRow('User ID', _userSession!['userId'] ?? 'N/A'),
              _buildInfoRow('Name', _userSession!['userName'] ?? 'N/A'),
              _buildInfoRow('Email', _userSession!['email'] ?? 'N/A'),
              _buildInfoRow('Mode', _isOnline ? 'Online' : 'Offline'),
            ] else ...[
              const Text('No session data available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Offline Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_offlineStats != null) ...[
              _buildInfoRow('Transactions', '${_offlineStats!.transactionCount}'),
              _buildInfoRow('Categories', '${_offlineStats!.categoryCount}'),
              _buildInfoRow('Total Items', '${_offlineStats!.totalOfflineItems}'),
              _buildInfoRow('Last Sync', _offlineStats!.lastSyncTime?.toString() ?? 'Never'),
            ] else ...[
              const Text('Loading stats...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleSyncPressed,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleClearOfflineData,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Offline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upgrade, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Account Conversion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Convert your anonymous account to a full account to sync your data across devices.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isOnline ? _handleConversionPressed : null,
                icon: const Icon(Icons.person_add),
                label: const Text('Convert to Full Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showConnectivityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connectivity Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_isOnline ? "Online" : "Offline"}'),
            const SizedBox(height: 8),
            Text('Offline Items: ${_offlineStats?.totalOfflineItems ?? 0}'),
            const SizedBox(height: 8),
            Text('Last Sync: ${_offlineStats?.lastSyncTime?.toString() ?? "Never"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleSyncPressed() async {
    if (!_isOnline) {
      _showSnackBar('No internet connection', Colors.red);
      return;
    }

    try {
      _showSnackBar('Syncing data...', Colors.blue);
      
      final result = await _syncService.syncAllOfflineData();
      
      if (result.isSuccess) {
        _showSnackBar('Sync successful: ${result.successCount} items', Colors.green);
      } else {
        _showSnackBar('Sync failed: ${result.errors.first}', Colors.red);
      }
      
      _loadOfflineStats();
    } catch (e) {
      _showSnackBar('Error syncing: $e', Colors.red);
    }
  }

  void _handleClearOfflineData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Offline Data'),
        content: const Text('Are you sure you want to clear all offline data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _offlineService.clearAllOfflineData();
        _showSnackBar('Offline data cleared', Colors.green);
        _loadOfflineStats();
      } catch (e) {
        _showSnackBar('Error clearing data: $e', Colors.red);
      }
    }
  }

  void _handleConversionPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert Account'),
        content: const Text('This would open the account conversion flow.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Account conversion not implemented yet', Colors.orange);
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }
}
