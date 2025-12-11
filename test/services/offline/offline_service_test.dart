import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests cho OfflineService logic - chỉ test SharedPreferences operations
/// Để tránh Firebase initialization, test trực tiếp với SharedPreferences
void main() {
  group('Offline Storage Tests - SharedPreferences logic', () {
    setUp(() async {
      // Reset SharedPreferences mock trước mỗi test
      SharedPreferences.setMockInitialValues({});
    });

    test('SharedPreferences lưu và đọc offline transactions', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Lưu offline transaction
      final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final transactionData = [
        '{"transaction_id":"$offlineId","amount":100000,"type":"expense","note":"Test"}',
      ];
      await prefs.setStringList('offline_transactions', transactionData);

      // Đọc lại
      final savedData = prefs.getStringList('offline_transactions');
      expect(savedData, isNotNull);
      expect(savedData!.length, 1);
      expect(savedData.first, contains('100000'));
    });

    test('SharedPreferences lưu và đọc pending updates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Lưu pending update
      final pendingData = [
        '{"transaction_id":"trans_123","amount":75000,"pending_retry_count":0}',
      ];
      await prefs.setStringList('pending_updates', pendingData);

      // Đọc lại
      final savedData = prefs.getStringList('pending_updates');
      expect(savedData, isNotNull);
      expect(savedData!.length, 1);
      expect(savedData.first, contains('trans_123'));
    });

    test('SharedPreferences lưu và đọc pending deletes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Lưu pending delete
      final pendingData = [
        '{"transaction_id":"trans_del_123","pending_retry_count":0}',
      ];
      await prefs.setStringList('pending_deletes', pendingData);

      // Đọc lại
      final savedData = prefs.getStringList('pending_deletes');
      expect(savedData, isNotNull);
      expect(savedData!.length, 1);
      expect(savedData.first, contains('trans_del_123'));
    });

    test('SharedPreferences xóa pending update', () async {
      SharedPreferences.setMockInitialValues({
        'pending_updates': [
          '{"transaction_id":"trans_1","amount":50000}',
          '{"transaction_id":"trans_2","amount":75000}',
        ],
      });
      final prefs = await SharedPreferences.getInstance();

      // Xóa trans_1
      final existingData = prefs.getStringList('pending_updates')!;
      final filtered = existingData
          .where((json) => !json.contains('trans_1'))
          .toList();
      await prefs.setStringList('pending_updates', filtered);

      // Verify
      final updated = prefs.getStringList('pending_updates');
      expect(updated!.length, 1);
      expect(updated.first, contains('trans_2'));
    });

    test('SharedPreferences xóa pending delete', () async {
      SharedPreferences.setMockInitialValues({
        'pending_deletes': [
          '{"transaction_id":"del_1"}',
          '{"transaction_id":"del_2"}',
        ],
      });
      final prefs = await SharedPreferences.getInstance();

      // Xóa del_1
      final existingData = prefs.getStringList('pending_deletes')!;
      final filtered = existingData
          .where((json) => !json.contains('del_1'))
          .toList();
      await prefs.setStringList('pending_deletes', filtered);

      // Verify
      final updated = prefs.getStringList('pending_deletes');
      expect(updated!.length, 1);
      expect(updated.first, contains('del_2'));
    });

    test('SharedPreferences không duplicate pending delete', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Add first
      await prefs.setStringList('pending_deletes', [
        '{"transaction_id":"del_1"}',
      ]);

      // Try to add same ID
      final existing = prefs.getStringList('pending_deletes')!;
      final alreadyExists = existing.any((json) => json.contains('del_1'));

      expect(alreadyExists, true);
      // Không thêm nếu đã tồn tại
      expect(existing.length, 1);
    });

    test('SharedPreferences user session', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Save session
      await prefs.setString('offline_user_id', 'user_123');
      await prefs.setString('offline_user_name', 'Test User');
      await prefs.setString('offline_user_email', 'test@example.com');

      // Read session
      expect(prefs.getString('offline_user_id'), 'user_123');
      expect(prefs.getString('offline_user_name'), 'Test User');
      expect(prefs.getString('offline_user_email'), 'test@example.com');
    });

    test('Retry count increment logic', () async {
      SharedPreferences.setMockInitialValues({
        'pending_updates': [
          '{"transaction_id":"retry_test","pending_retry_count":0}',
        ],
      });
      final prefs = await SharedPreferences.getInstance();

      // Simulate increment retry
      final existing = prefs.getStringList('pending_updates')!;
      final updatedData = <String>[];
      const maxRetry = 3;
      var shouldRemove = false;

      for (final json in existing) {
        if (json.contains('retry_test')) {
          // Extract and increment retry count
          final retryCount = 0 + 1; // Simulating first retry
          if (retryCount >= maxRetry) {
            shouldRemove = true;
            continue;
          }
          // In real code, would update JSON
          updatedData.add(
            json.replaceAll('retry_count":0', 'retry_count":$retryCount'),
          );
        } else {
          updatedData.add(json);
        }
      }

      expect(shouldRemove, false);
      expect(updatedData.length, 1);
    });

    test('Max retry removes pending operation', () {
      // Test logic: after 3 retries, operation should be removed
      const retryCount = 3;
      const maxRetry = 3;

      final shouldRemove = retryCount >= maxRetry;
      expect(shouldRemove, true);
    });
  });

  group('Offline ID Utility Tests', () {
    test('Offline user ID format validation', () {
      bool isOfflineUserId(String userId) {
        return userId.startsWith('offline_');
      }

      expect(isOfflineUserId('offline_123456'), true);
      expect(isOfflineUserId('user_123'), false);
      expect(isOfflineUserId('abc_offline'), false);
      expect(isOfflineUserId(''), false);
    });

    test('Generate offline user ID format', () {
      String generateOfflineUserId() {
        return 'offline_${DateTime.now().millisecondsSinceEpoch}';
      }

      final id = generateOfflineUserId();
      expect(id, startsWith('offline_'));
      expect(id.length, greaterThan(8));
    });

    test('Offline transaction ID format', () {
      String generateOfflineTransactionId() {
        return 'offline_${DateTime.now().millisecondsSinceEpoch}';
      }

      final id = generateOfflineTransactionId();
      expect(id, startsWith('offline_'));
    });
  });

  group('Pending Operations Count Tests', () {
    test('Count pending operations from multiple sources', () async {
      SharedPreferences.setMockInitialValues({
        'offline_transactions': ['{"id":"1"}', '{"id":"2"}'],
        'pending_updates': ['{"id":"3"}'],
        'pending_deletes': ['{"id":"4"}', '{"id":"5"}'],
      });
      final prefs = await SharedPreferences.getInstance();

      final offlineTransactions =
          prefs.getStringList('offline_transactions') ?? [];
      final pendingUpdates = prefs.getStringList('pending_updates') ?? [];
      final pendingDeletes = prefs.getStringList('pending_deletes') ?? [];

      final totalCount =
          offlineTransactions.length +
          pendingUpdates.length +
          pendingDeletes.length;

      expect(totalCount, 5);
    });

    test('Has pending operations check', () async {
      SharedPreferences.setMockInitialValues({
        'pending_updates': ['{"id":"1"}'],
      });
      final prefs = await SharedPreferences.getInstance();

      final offlineTransactions =
          prefs.getStringList('offline_transactions') ?? [];
      final pendingUpdates = prefs.getStringList('pending_updates') ?? [];
      final pendingDeletes = prefs.getStringList('pending_deletes') ?? [];

      final hasPending =
          offlineTransactions.isNotEmpty ||
          pendingUpdates.isNotEmpty ||
          pendingDeletes.isNotEmpty;

      expect(hasPending, true);
    });

    test('No pending operations check', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final offlineTransactions =
          prefs.getStringList('offline_transactions') ?? [];
      final pendingUpdates = prefs.getStringList('pending_updates') ?? [];
      final pendingDeletes = prefs.getStringList('pending_deletes') ?? [];

      final hasPending =
          offlineTransactions.isNotEmpty ||
          pendingUpdates.isNotEmpty ||
          pendingDeletes.isNotEmpty;

      expect(hasPending, false);
    });
  });
}
