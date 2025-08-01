# Utils Directory - Cấu trúc và Hướng dẫn sử dụng

## 📁 Cấu trúc thư mục utils (Đã hợp nhất)

```
lib/utils/
├── README.md                           # Documentation này
├── index.dart                          # Export tất cả utils
│
├── formatting/                         # Formatting utilities
│   ├── currency_formatter.dart         # Currency formatting (VNĐ)
│   └── date_formatter.dart             # Unified date formatting & DateRange
│
├── validation/                         # Validation utilities
│   └── input_validator.dart            # Input validation (email, phone, amount, etc.)
│
├── helpers/                            # Helper utilities
│   ├── category_icon_helper.dart       # Category icon handling
│   ├── date_helper.dart                # Legacy date helper (hidden DateRange)
│   ├── string_helper.dart              # String utilities
│   └── list_helper.dart                # List utilities
│
├── logging/                            # Logging utilities
│   └── logging_utils.dart              # Logging wrapper
│
└── extensions/                         # Extension methods
    ├── string_extensions.dart          # String extensions
    ├── date_extensions.dart            # Date extensions
    └── list_extensions.dart            # List extensions
```

## 🔄 **Những thay đổi chính sau hợp nhất:**

### **1. Unified DateFormatter**
- ✅ **Hợp nhất** `DateFormatter` và `DateHelper` thành một class duy nhất
- ✅ **Unified DateRange** - chỉ có một DateRange class
- ✅ **Comprehensive methods** - tất cả date utilities trong một nơi
- ✅ **Extensions** - convenient methods cho DateTime

### **2. Organized Structure**
- ✅ **Formatting** - currency, date formatting
- ✅ **Validation** - input validation
- ✅ **Helpers** - string, list, category helpers
- ✅ **Extensions** - convenient extensions
- ✅ **Logging** - logging utilities

### **3. Backward Compatibility**
- ✅ **Legacy exports** - vẫn import được từ paths cũ
- ✅ **Hide conflicts** - ẩn DateRange trùng lặp
- ✅ **Clean imports** - không duplicate exports

## 🎯 Nguyên tắc thiết kế

### 1. **Single Responsibility**
- Mỗi file chỉ chịu trách nhiệm cho một domain cụ thể
- Không có duplicate functionality

### 2. **Consistent API**
- Naming convention nhất quán
- Method signatures tương tự nhau
- Error handling standardized

### 3. **Performance First**
- Lazy initialization khi cần
- Caching cho expensive operations
- Memory efficient

### 4. **Type Safety**
- Strong typing cho tất cả methods
- Null safety đầy đủ
- Generic types khi phù hợp

## 📖 Hướng dẫn sử dụng

### Import utils
```dart
// Import tất cả utils
import 'package:moni/utils/index.dart';

// Import specific utils
import 'package:moni/utils/formatting/currency_formatter.dart';
import 'package:moni/utils/validation/input_validator.dart';
```

### Sử dụng formatting
```dart
// Currency formatting
final formatted = CurrencyFormatter.formatAmount(1000000); // "1,000,000"
final withCurrency = CurrencyFormatter.formatVND(1000000); // "1,000,000đ"

// Date formatting
final dateStr = DateFormatter.formatDate(DateTime.now()); // "25/12/2024"
final relative = DateFormatter.formatRelativeTime(date); // "2 giờ trước"

// DateRange
final range = DateRange(start: startDate, end: endDate);
final displayText = range.displayText; // "25/12 - 31/12/2024"
```

### Sử dụng validation
```dart
// Input validation
final isValid = InputValidator.isValidEmail('test@example.com');
final amountValid = InputValidator.isValidAmount('1000000');
final phoneValid = InputValidator.isValidPhone('0123456789');
```

### Sử dụng helpers
```dart
// String helpers
final capitalized = StringHelper.capitalize('hello world'); // "Hello World"
final truncated = StringHelper.truncate('long text', 10); // "long text..."

// List helpers
final grouped = ListHelper.groupBy(transactions, (t) => t.categoryId);
final sorted = ListHelper.sortBy(transactions, (t) => t.date);
```

### Sử dụng extensions
```dart
// String extensions
final text = 'hello world'.capitalize; // "Hello World"
final isValid = 'test@email.com'.isValidEmail; // true

// Date extensions
final isToday = date.isToday; // true
final formatted = date.formatDate; // "25/12/2024"
final relative = date.relativeDateText; // "Hôm nay"

// List extensions
final grouped = transactions.groupBy((t) => t.categoryId);
final sorted = transactions.sortBy((t) => t.amount);
final filtered = transactions.filter((t) => t.amount > 100000);
```

## 🚀 Migration Guide

### Từ DateHelper cũ:
```dart
// Cũ
import 'package:moni/utils/date_helper.dart';
final dateStr = DateHelper.formatDate(date);

// Mới
import 'package:moni/utils/formatting/date_formatter.dart';
final dateStr = DateFormatter.formatDate(date);
// Hoặc dùng extension
final dateStr = date.formatDate;
```

### Từ DateFormatter cũ:
```dart
// Cũ
import 'package:moni/utils/date_formatter.dart';
final relative = DateFormatter.formatRelativeTime(date);

// Mới
import 'package:moni/utils/formatting/date_formatter.dart';
final relative = DateFormatter.formatRelativeTime(date);
// Hoặc dùng extension
final relative = date.formatRelativeTime;
```

### Từ DateRange cũ:
```dart
// Cũ - có thể từ nhiều nơi khác nhau
final range = DateRange(start, end);

// Mới - unified từ DateFormatter
import 'package:moni/utils/formatting/date_formatter.dart';
final range = DateRange(start: start, end: end);
```

## ✅ **Lợi ích sau hợp nhất:**

1. **Không duplicate** - một DateRange, một DateFormatter
2. **Consistent API** - tất cả date methods trong một nơi
3. **Extensions** - convenient methods cho DateTime
4. **Organized** - cấu trúc rõ ràng, dễ maintain
5. **Backward compatible** - code cũ vẫn chạy được
6. **Type safe** - strong typing, null safety
7. **Performance** - optimized methods 