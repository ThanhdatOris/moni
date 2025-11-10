import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/constants/enums.dart';

import '../../core/injection_container.dart' as di;
import '../../models/transaction_model.dart';
import '../../utils/formatting/date_formatter.dart';
import '../data/transaction_service.dart';
import 'auth_providers.dart';

/// Service Provider
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return di.getIt<TransactionService>();
});

/// Base Provider - Query tất cả transactions (1 query duy nhất)
/// Cache toàn bộ transactions để các derived providers filter từ cache
final allTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final service = ref.watch(transactionServiceProvider);
  
  // Invalidate provider khi auth state thay đổi để đảm bảo stream được reconnect
  ref.listen(authStateProvider, (previous, next) {
    if (previous?.value != next.value) {
      // Auth state changed, invalidate để reconnect stream
      ref.invalidateSelf();
    }
  });
  
  // Query tất cả transactions không filter để cache
  // Keep alive để đảm bảo stream được giữ active khi không có listeners
  ref.keepAlive();
  return service.getTransactions();
});

/// Derived Provider - Transactions gần đây (filter từ cache)
final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final all = ref.watch(allTransactionsProvider).value ?? [];
  // Filter từ cache: lấy 10 transactions gần đây nhất
  return all
      .where((t) => !t.isDeleted)
      .take(10)
      .toList();
});

/// Derived Provider - Tổng thu nhập (tính từ cache)
final totalIncomeProvider = Provider<double>((ref) {
  final all = ref.watch(allTransactionsProvider).value ?? [];
  return all
      .where((t) => !t.isDeleted && t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Derived Provider - Tổng chi tiêu (tính từ cache)
final totalExpenseProvider = Provider<double>((ref) {
  final all = ref.watch(allTransactionsProvider).value ?? [];
  return all
      .where((t) => !t.isDeleted && t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Derived Provider - Số dư hiện tại (tính từ cache)
final currentBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseProvider);
  return income - expense;
});

/// Derived Provider - Transactions theo date range (filter từ cache)
final transactionsByDateRangeProvider = Provider.family<List<TransactionModel>, DateRange>((ref, range) {
  final all = ref.watch(allTransactionsProvider).value ?? [];
  return all
      .where((t) => 
          !t.isDeleted &&
          t.date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(range.end.add(const Duration(seconds: 1))))
      .toList();
});

/// Derived Provider - Transactions theo type (filter từ cache)
final transactionsByTypeProvider = Provider.family<List<TransactionModel>, TransactionType>((ref, type) {
  final all = ref.watch(allTransactionsProvider).value ?? [];
  return all
      .where((t) => !t.isDeleted && t.type == type)
      .toList();
});

/// Derived Provider - Transactions theo category (filter từ cache)
final transactionsByCategoryProvider = Provider.family<List<TransactionModel>, String>((ref, categoryId) {
  final all = ref.watch(allTransactionsProvider).value ?? [];
  return all
      .where((t) => !t.isDeleted && t.categoryId == categoryId)
      .toList();
});

/// Derived Provider - Transaction theo ID (tìm từ cache)
final transactionByIdProvider = Provider.family<TransactionModel?, String>((ref, transactionId) {
  final all = ref.watch(allTransactionsProvider).value ?? [];
  try {
    return all.firstWhere(
      (t) => t.transactionId == transactionId && !t.isDeleted,
      orElse: () => throw StateError('Transaction not found'),
    );
  } catch (e) {
    return null;
  }
});

/// Derived Provider - Recent transactions với limit tùy chỉnh
final recentTransactionsWithLimitProvider = Provider.family<List<TransactionModel>, int>((ref, limit) {
  final all = ref.watch(allTransactionsProvider).value ?? [];
  return all
      .where((t) => !t.isDeleted)
      .take(limit)
      .toList();
});

