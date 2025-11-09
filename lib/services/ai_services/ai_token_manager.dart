import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages AI token quota and rate limiting
/// - Daily token limit (10k/day/user)
/// - Google API rate limiting (12 calls/minute)
/// - Firestore sync for cross-device tracking
/// - Local backup with SharedPreferences
class AITokenManager {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Rate limiting for Google API (15 requests/minute for free tier)
  DateTime? _lastApiCall;
  static const Duration _minApiInterval = Duration(milliseconds: 500);
  final List<DateTime> _apiCallTimestamps = []; // Track calls in last minute
  static const int _maxCallsPerMinute = 12; // Conservative limit (free tier = 15)

  // Token usage tracking
  int _dailyTokenCount = 0;
  DateTime? _lastTokenReset;
  static const int _dailyTokenLimit = 10000;

  // SharedPreferences keys for persistent storage
  static const String _keyTokenCount = 'ai_daily_token_count';
  static const String _keyLastTokenReset = 'ai_last_token_reset';

  AITokenManager() {
    _loadTokenUsage();
  }

  /// Get current daily token limit
  int get dailyTokenLimit => _dailyTokenLimit;

  /// Get current daily token count
  int get dailyTokenCount => _dailyTokenCount;

  /// Check if user has exceeded token quota
  bool hasExceededQuota(int estimatedTokens) {
    return _dailyTokenCount + estimatedTokens > _dailyTokenLimit;
  }

  /// Check rate limit and token usage before making API call
  Future<void> checkRateLimit() async {
    // Remove timestamps older than 1 minute
    final now = DateTime.now();
    _apiCallTimestamps
        .removeWhere((time) => now.difference(time).inSeconds > 60);

    // Check if we've hit the per-minute limit
    if (_apiCallTimestamps.length >= _maxCallsPerMinute) {
      final oldestCall = _apiCallTimestamps.first;
      final timeSinceOldest = now.difference(oldestCall);
      final waitTime = const Duration(seconds: 60) - timeSinceOldest;

      if (waitTime.inMilliseconds > 0) {
        _logger.w(
            '⏳ Rate limit approaching (${_apiCallTimestamps.length}/$_maxCallsPerMinute). Waiting ${waitTime.inSeconds}s...');
        await Future.delayed(waitTime);
      }
    }

    // Check minimum interval between calls
    if (_lastApiCall != null) {
      final timeSinceLastCall = now.difference(_lastApiCall!);
      if (timeSinceLastCall < _minApiInterval) {
        final waitTime = _minApiInterval - timeSinceLastCall;
        await Future.delayed(waitTime);
      }
    }

    // Record this API call
    _lastApiCall = DateTime.now();
    _apiCallTimestamps.add(_lastApiCall!);
  }

  /// Update token count after API call
  Future<void> updateTokenCount(int tokensUsed) async {
    // Check if we need to reset (new day)
    await _checkAndResetIfNewDay();

    _dailyTokenCount += tokensUsed;

    // Save to both local and cloud
    await _saveTokenUsage();

    _logger.d(
        '📊 Token usage: $_dailyTokenCount/$_dailyTokenLimit (${(_dailyTokenCount / _dailyTokenLimit * 100).toStringAsFixed(1)}%)');
  }

  /// Load token usage from Firestore (priority) or SharedPreferences (backup)
  Future<void> _loadTokenUsage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user logged in, using local token tracking only');
        await _loadFromLocal();
        return;
      }

      // Try to load from Firestore first
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_usage')
          .doc('token_tracking')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _dailyTokenCount = data['dailyTokenCount'] ?? 0;

        if (data['lastReset'] != null) {
          _lastTokenReset = (data['lastReset'] as Timestamp).toDate();
        }

        // Check if we need to reset based on Firestore data
        await _checkAndResetIfNewDay();

        _logger.i(
            '📁 Loaded token usage from Firestore: $_dailyTokenCount/$_dailyTokenLimit');
      } else {
        // No Firestore data - check if we have local data to migrate
        await _loadFromLocal();

        // If we have local data, sync to Firestore
        if (_lastTokenReset != null) {
          await _checkAndResetIfNewDay();
          await _saveTokenUsage();
          _logger.i('📤 Migrated local token data to Firestore');
        } else {
          // Brand new user - initialize
          _dailyTokenCount = 0;
          _lastTokenReset = DateTime.now();
          await _saveTokenUsage();
          _logger.i('🆕 Initialized new token tracking for user');
        }
      }
    } catch (e) {
      _logger.e('❌ Error loading token usage from Firestore: $e');
      await _loadFromLocal();
    }
  }

  /// Load token usage from local SharedPreferences
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyTokenCount = prefs.getInt(_keyTokenCount) ?? 0;

      final lastResetString = prefs.getString(_keyLastTokenReset);
      if (lastResetString != null) {
        _lastTokenReset = DateTime.parse(lastResetString);
      }

      await _checkAndResetIfNewDay();
      _logger.d('📁 Loaded token usage from local: $_dailyTokenCount');
    } catch (e) {
      _logger.e('❌ Error loading token usage from local: $e');
      _dailyTokenCount = 0;
      _lastTokenReset = DateTime.now();
    }
  }

  /// Save token usage to both Firestore and SharedPreferences
  Future<void> _saveTokenUsage() async {
    try {
      // Save to SharedPreferences (local backup)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTokenCount, _dailyTokenCount);
      if (_lastTokenReset != null) {
        await prefs.setString(_keyLastTokenReset, _lastTokenReset!.toIso8601String());
      }

      // Save to Firestore (cloud sync)
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_usage')
            .doc('token_tracking')
            .set({
          'dailyTokenCount': _dailyTokenCount,
          'lastReset': _lastTokenReset != null
              ? Timestamp.fromDate(_lastTokenReset!)
              : FieldValue.serverTimestamp(),
          'dailyLimit': _dailyTokenLimit,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      _logger.e('❌ Error saving token usage: $e');
    }
  }

  /// Check if it's a new day and reset token count if needed
  Future<void> _checkAndResetIfNewDay() async {
    if (_lastTokenReset == null) {
      _lastTokenReset = DateTime.now();
      _dailyTokenCount = 0;
      return;
    }

    final now = DateTime.now();
    final lastReset = _lastTokenReset!;

    // Compare dates (year, month, day) - reset at midnight
    final isNewDay = now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day;

    if (isNewDay) {
      _logger.i('🔄 New day detected, resetting token count');
      _dailyTokenCount = 0;
      _lastTokenReset = now;
      await _saveTokenUsage();
    }
  }

  /// Get token usage statistics
  Future<Map<String, dynamic>> getTokenUsageStats() async {
    await _checkAndResetIfNewDay();

    return {
      'dailyTokenCount': _dailyTokenCount,
      'dailyTokenLimit': _dailyTokenLimit,
      'percentUsed': (_dailyTokenCount / _dailyTokenLimit * 100).toStringAsFixed(1),
      'remainingTokens': _dailyTokenLimit - _dailyTokenCount,
      'lastReset': _lastTokenReset?.toIso8601String(),
      'recentCallsCount': _apiCallTimestamps.length,
      'maxCallsPerMinute': _maxCallsPerMinute,
    };
  }

  /// Force reset token quota (admin tool)
  Future<void> forceResetTokenQuota() async {
    _dailyTokenCount = 0;
    _lastTokenReset = DateTime.now();
    await _saveTokenUsage();
    _logger.i('🔧 Token quota manually reset');
  }
}
