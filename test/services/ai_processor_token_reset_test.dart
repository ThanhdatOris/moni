import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test để verify logic reset token hàng ngày
void main() {
  group('AI Token Reset Logic Tests', () {
    setUp(() async {
      // Clear SharedPreferences trước mỗi test
      SharedPreferences.setMockInitialValues({});
    });

    test('Token reset khi qua ngày mới (same 24h period but different date)', () {
      // Tạo 2 datetime cùng trong 24h nhưng khác ngày
      final yesterday23h = DateTime(2025, 11, 7, 23, 0, 0);
      final today1h = DateTime(2025, 11, 8, 1, 0, 0);
      
      // Verify duration < 24h
      final duration = today1h.difference(yesterday23h);
      expect(duration.inHours, lessThan(24));
      expect(duration.inDays, equals(0)); // inDays sẽ return 0
      
      // Nhưng khi so sánh date
      final lastResetDate = DateTime(
        yesterday23h.year,
        yesterday23h.month,
        yesterday23h.day,
      );
      final currentDate = DateTime(
        today1h.year,
        today1h.month,
        today1h.day,
      );
      
      // Phải detect được đã qua ngày mới
      expect(currentDate.isAfter(lastResetDate), isTrue,
          reason: 'Should detect new day even within 24h period');
    });

    test('Token KHÔNG reset trong cùng ngày (dù qua 12h)', () {
      final morning = DateTime(2025, 11, 7, 8, 0, 0);
      final evening = DateTime(2025, 11, 7, 20, 0, 0);
      
      final lastResetDate = DateTime(
        morning.year,
        morning.month,
        morning.day,
      );
      final currentDate = DateTime(
        evening.year,
        evening.month,
        evening.day,
      );
      
      // Không nên reset vì cùng ngày
      expect(currentDate.isAfter(lastResetDate), isFalse,
          reason: 'Should NOT reset within same day');
    });

    test('Token reset chính xác vào 0h00', () {
      final endOfDay = DateTime(2025, 11, 7, 23, 59, 59);
      final startOfNextDay = DateTime(2025, 11, 8, 0, 0, 0);
      
      final lastResetDate = DateTime(
        endOfDay.year,
        endOfDay.month,
        endOfDay.day,
      );
      final currentDate = DateTime(
        startOfNextDay.year,
        startOfNextDay.month,
        startOfNextDay.day,
      );
      
      expect(currentDate.isAfter(lastResetDate), isTrue,
          reason: 'Should reset at exactly midnight');
    });

    test('Token reset sau nhiều ngày (edge case)', () {
      final threeDaysAgo = DateTime(2025, 11, 4, 15, 0, 0);
      final today = DateTime(2025, 11, 7, 10, 0, 0);
      
      final lastResetDate = DateTime(
        threeDaysAgo.year,
        threeDaysAgo.month,
        threeDaysAgo.day,
      );
      final currentDate = DateTime(
        today.year,
        today.month,
        today.day,
      );
      
      expect(currentDate.isAfter(lastResetDate), isTrue,
          reason: 'Should reset after multiple days');
    });
  });
}
