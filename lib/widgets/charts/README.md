# Module Charts - Cấu trúc mới

Module charts đã được tái cấu trúc theo yêu cầu mới với bố cục rõ ràng và tương tác tốt hơn.

## Cấu trúc mới

```
lib/widgets/charts/
├── models/
│   └── chart_data_model.dart          # Models cho dữ liệu chart
├── components/
│   ├── donut_chart.dart               # Donut chart component
│   ├── trend_bar_chart.dart           # Bar chart component
│   ├── filter.dart                    # Filter component (date + transaction type)
│   ├── category_list.dart             # Interactive category list
│   └── financial_overview_cards.dart  # Financial overview cards
├── financial_charts_screen.dart       # Screen chính kết hợp tất cả
├── index.dart                         # Export tất cả components
└── README.md                          # Hướng dẫn sử dụng
```

## Bố cục mới

### ExpenseChartSection Container
```
┌─────────────────────────────────────┐
│ HEADER: Title + Chart Type Toggle   │
├─────────────────────────────────────┤
│ BODY:                               │
│ ┌─────────────────────────────────┐ │
│ │ ROW 1: Filter                   │ │
│ │ (Date + Transaction Type)       │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ROW 2: Main Chart               │ │
│ │ (Donut/Trend)                   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ROW 3: Top 5 Categories         │ │
│ │ + Show More                     │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Components chính

### 1. ExpenseChartSection (Container chính)
- **Header**: Title + Chart type toggle (Phân bổ/Xu hướng)
- **Body**: 
  - Filter row (date + transaction type)
  - Main chart row (donut/trend)
  - Categories row (top 5 + show more)

### 2. ChartFilter
- **Date Filter**: Gradient cam với navigation tháng
- **Transaction Type Filter**: Chi tiêu/Thu nhập với overview cards

### 3. CategoryList
- **Interactive Categories**: Có thể touch để expand/collapse
- **Navigation**: Touch category để navigate đến history
- **Show More**: Expand để xem tất cả categories

### 4. DonutChart & TrendBarChart
- **Real Data**: Tích hợp với ChartDataService
- **Responsive**: Tự động điều chỉnh theo kích thước màn hình
- **Interactive**: Touch để xem chi tiết

## Services

### ChartDataService
Service xử lý dữ liệu thực từ Firebase:

```dart
// Đăng ký trong dependency injection
getIt.registerLazySingleton<ChartDataService>(() => ChartDataService(
  transactionService: getIt<TransactionService>(),
  categoryService: getIt<CategoryService>(),
));

// Sử dụng
final chartDataService = GetIt.instance<ChartDataService>();
```

#### Methods chính:
- `getDonutChartData()`: Lấy dữ liệu phân bổ chi tiêu theo danh mục
- `getTrendChartData()`: Lấy dữ liệu xu hướng thu chi theo thời gian
- `getFinancialOverviewData()`: Lấy dữ liệu tổng quan tài chính

## Sử dụng

### 1. Sử dụng ExpenseChartSection
```dart
ExpenseChartSection(
  onCategoryTap: () {
    // Handle category tap
  },
  onNavigateToHistory: () {
    // Navigate to history screen
  },
  onRefresh: () {
    // Refresh data
  },
)
```

### 2. Sử dụng ChartFilter
```dart
ChartFilter(
  selectedDate: _selectedDate,
  selectedTransactionType: _selectedTransactionType,
  financialOverviewData: _financialOverviewData,
  isLoading: _isLoading,
  onDateChanged: (date) {
    // Handle date change
  },
  onTransactionTypeChanged: (type) {
    // Handle transaction type change
  },
)
```

### 3. Sử dụng CategoryList
```dart
CategoryList(
  data: _chartData,
  isCompact: isCompact,
  onCategoryTap: (item) {
    // Handle category item tap
  },
  onNavigateToHistory: () {
    // Navigate to history
  },
)
```

## Features mới

### ✅ Đã tích hợp
- **Cấu trúc mới**: Header + Body với layout rõ ràng
- **Interactive Categories**: Touch để expand/collapse và navigate
- **Responsive Design**: Tự động điều chỉnh theo kích thước màn hình
- **Real Data**: Tích hợp với Firebase thông qua ChartDataService
- **Error Handling**: Xử lý lỗi và retry mechanism
- **Loading States**: Hiển thị loading state khi tải dữ liệu

### 🎯 Tính năng chính
- **Chart Type Toggle**: Chuyển đổi giữa Donut và Trend chart
- **Date Navigation**: Điều hướng tháng với gradient cam
- **Transaction Type Filter**: Lọc theo Chi tiêu/Thu nhập
- **Category Expansion**: Show more/Thu gọn danh sách categories
- **Category Navigation**: Touch category để xem chi tiết trong history

### 🔧 Technical Features
- **Component Modularity**: Tách biệt các component để dễ maintain
- **State Management**: Quản lý state local cho từng component
- **Performance**: Lazy loading và caching dữ liệu
- **Accessibility**: Hỗ trợ accessibility cho người dùng khuyết tật

## Migration Guide

### Từ cấu trúc cũ sang mới:
1. **ExpenseChartSection**: Đã được tái cấu trúc hoàn toàn
2. **ChartFilter**: Đơn giản hóa, loại bỏ overview cards
3. **CategoryList**: Component mới thay thế phần categories cũ
4. **Navigation**: Thêm callback `onNavigateToHistory`

### Breaking Changes:
- Thay đổi cấu trúc ExpenseChartSection
- Thêm parameter `onNavigateToHistory` 
- Loại bỏ một số method helper không cần thiết 