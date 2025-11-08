# Riverpod Providers - State Management Layer

## Tổng quan

Folder này chứa tất cả Riverpod providers để quản lý state và cache dữ liệu từ Firestore, giảm số lượng queries từ ~47 xuống ~8 queries.

---

## Cấu trúc

```
lib/services/providers/
├── providers.dart              # Export tất cả providers
├── auth_providers.dart         # Auth & User providers
├── transaction_providers.dart  # Transaction providers
├── category_providers.dart      # Category providers
├── budget_providers.dart       # Budget providers
├── conversation_providers.dart # Conversation providers
├── alert_providers.dart        # Budget alert providers
├── chat_log_providers.dart     # Chat log providers
└── report_providers.dart        # Report providers
```

---

## Cách sử dụng

### 1. Import providers

```dart
import 'package:moni/services/providers/providers.dart';
```

### 2. Wrap app với ProviderScope

```dart
// lib/main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 3. Sử dụng trong Widgets

#### ConsumerWidget (StatelessWidget với Riverpod):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/services/providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final transactions = ref.watch(recentTransactionsProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    
    return Scaffold(
      // ...
    );
  }
}
```

#### ConsumerStatefulWidget (StatefulWidget với Riverpod):

```dart
class AddTransactionScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesByTypeProvider(TransactionType.expense));
    // ...
  }
}
```

---

## Available Providers

### Transaction Providers

```dart
// Base provider - Query tất cả transactions (1 query)
final allTransactionsProvider = StreamProvider<List<TransactionModel>>(...);

// Derived providers - Filter từ cache (0 queries mới)
final recentTransactionsProvider = Provider<List<TransactionModel>>(...);
final totalIncomeProvider = Provider<double>(...);
final totalExpenseProvider = Provider<double>(...);
final currentBalanceProvider = Provider<double>(...);
final transactionsByDateRangeProvider = Provider.family<List<TransactionModel>, DateRange>(...);
final transactionsByTypeProvider = Provider.family<List<TransactionModel>, TransactionType>(...);
final transactionsByCategoryProvider = Provider.family<List<TransactionModel>, String>(...);
final transactionByIdProvider = Provider.family<TransactionModel?, String>(...);
final recentTransactionsWithLimitProvider = Provider.family<List<TransactionModel>, int>(...);
```

### Category Providers

```dart
// Base provider - Query tất cả categories (1 query)
final allCategoriesProvider = StreamProvider<List<CategoryModel>>(...);

// Derived providers - Filter từ cache (0 queries mới)
final categoriesByTypeProvider = Provider.family<List<CategoryModel>, TransactionType>(...);
final parentCategoriesProvider = Provider.family<List<CategoryModel>, TransactionType?>(...);
final childCategoriesProvider = Provider.family<List<CategoryModel>, String>(...);
final defaultCategoriesProvider = Provider.family<List<CategoryModel>, TransactionType?>(...);
final categoryByIdProvider = Provider.family<CategoryModel?, String>(...);
final expenseCategoriesProvider = Provider<List<CategoryModel>>(...);
final incomeCategoriesProvider = Provider<List<CategoryModel>>(...);
```

### Budget Providers

```dart
// Base provider - Query tất cả budgets (1 query)
final allBudgetsProvider = StreamProvider<List<BudgetModel>>(...);

// Derived providers
final budgetByCategoryProvider = Provider.family<BudgetModel?, String>(...);
final activeBudgetsProvider = Provider<List<BudgetModel>>(...);
final budgetSummaryProvider = Provider<Map<String, dynamic>>(...);
```

### Auth Providers

```dart
final authServiceProvider = Provider<AuthService>(...);
final authStateProvider = StreamProvider<User?>(...);
final currentUserProvider = Provider<User?>(...);
final isAuthenticatedProvider = Provider<bool>(...);
```

---

## Examples

### Example 1: Hiển thị transactions gần đây

```dart
class RecentTransactionsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider);
    
    if (transactions.isEmpty) {
      return Text('Chưa có giao dịch');
    }
    
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return TransactionItem(transaction: transactions[index]);
      },
    );
  }
}
```

### Example 2: Tính tổng thu nhập và chi tiêu

```dart
class BalanceWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final balance = ref.watch(currentBalanceProvider);
    
    return Column(
      children: [
        Text('Thu nhập: ${CurrencyFormatter.formatAmount(income)}'),
        Text('Chi tiêu: ${CurrencyFormatter.formatAmount(expense)}'),
        Text('Số dư: ${CurrencyFormatter.formatAmount(balance)}'),
      ],
    );
  }
}
```

### Example 3: Filter categories theo type

```dart
class CategoryListWidget extends ConsumerWidget {
  final TransactionType type;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesByTypeProvider(type));
    
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryItem(category: categories[index]);
      },
    );
  }
}
```

### Example 4: Transactions theo date range

```dart
class MonthlyTransactionsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final range = DateRange(start, end);
    
    final transactions = ref.watch(transactionsByDateRangeProvider(range));
    
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return TransactionItem(transaction: transactions[index]);
      },
    );
  }
}
```

---

## Cache Invalidation

### Khi có write operations (create/update/delete):

```dart
// Trong Notifier hoặc method
Future<void> createTransaction(TransactionModel transaction) async {
  final service = ref.read(transactionServiceProvider);
  await service.createTransaction(transaction);
  
  // Invalidate cache để refetch
  ref.invalidate(allTransactionsProvider);
}
```

---

## Migration từ GetIt

### Trước (GetIt):

```dart
class _HomeScreenState extends State<HomeScreen> {
  late final TransactionService _transactionService;
  
  @override
  void initState() {
    _transactionService = GetIt.instance<TransactionService>();
    _loadTransactions();
  }
  
  void _loadTransactions() {
    _transactionService.getRecentTransactions().listen((transactions) {
      setState(() => _transactions = transactions);
    });
  }
}
```

### Sau (Riverpod):

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider);
    
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return TransactionItem(transaction: transactions[index]);
      },
    );
  }
}
```

---

## Lợi ích

1. ✅ **Giảm queries**: ~47 queries → ~8 queries (giảm 67%)
2. ✅ **Better performance**: Data từ cache, load nhanh hơn
3. ✅ **Automatic cleanup**: Riverpod tự dispose subscriptions
4. ✅ **Reactive updates**: UI tự động update khi data thay đổi
5. ✅ **Type-safe**: Compile-time type checking

---

## Best Practices

1. **Sử dụng `ref.watch()`** cho data cần reactive updates
2. **Sử dụng `ref.read()`** cho one-time reads hoặc trong callbacks
3. **Invalidate cache** khi có write operations
4. **Sử dụng `Provider.family`** cho providers với parameters
5. **Không import Riverpod trong services** - chỉ trong providers

---

*Cập nhật: $(date)*

