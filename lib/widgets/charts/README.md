# Module Charts - Phiên bản mới với Real Data

Module charts mới được thiết kế theo bố cục từ hình ảnh mẫu, cung cấp giao diện đơn giản và trực quan cho việc hiển thị dữ liệu tài chính với real data từ Firebase.

## Cấu trúc

```
lib/widgets/charts/
├── models/
│   └── chart_data_model.dart          # Models cho dữ liệu chart
├── components/
│   ├── donut_chart.dart               # Donut chart component
│   ├── trend_bar_chart.dart           # Bar chart component
│   └── financial_overview_cards.dart  # Financial overview cards
├── financial_charts_screen.dart       # Screen chính kết hợp tất cả
├── test_charts.dart                   # Test screen để kiểm tra
├── index.dart                         # Export tất cả components
└── README.md                          # Hướng dẫn sử dụng
```

## Services

### ChartDataService
Service mới được tạo để xử lý dữ liệu thực từ Firebase:

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

## Components

### 1. DonutChart
- Hiển thị phân bổ chi tiêu theo danh mục từ real data
- Có labels hiển thị phần trăm và icon
- Bao gồm danh sách chi tiết danh mục với tabs
- Tự động fallback về mock data nếu không có dữ liệu thực

### 2. TrendBarChart
- Hiển thị xu hướng thu chi theo thời gian từ real data
- Có thể chuyển đổi giữa các khoảng thời gian
- Hiển thị cả thu và chi trong cùng một bar
- Tự động fallback về mock data nếu không có dữ liệu thực

### 3. FinancialOverviewCards
- Hiển thị tổng thu chi từ real data
- Có navigation để chuyển đổi tháng
- Hiển thị so sánh với tháng trước
- Tự động fallback về mock data nếu không có dữ liệu thực

## Models

### ChartDataModel
```dart
class ChartDataModel {
  final String category;    // Tên danh mục
  final double amount;      // Số tiền
  final double percentage;  // Phần trăm
  final String icon;        // Icon name
  final String color;       // Màu sắc (hex)
  final String type;        // 'expense' hoặc 'income'
}
```

### FinancialOverviewData
```dart
class FinancialOverviewData {
  final double totalExpense;    // Tổng chi tiêu
  final double totalIncome;     // Tổng thu nhập
  final double changeAmount;    // Số tiền thay đổi
  final String changePeriod;    // Khoảng thời gian so sánh
  final bool isIncrease;        // Tăng hay giảm
}
```

### TrendData
```dart
class TrendData {
  final String period;      // Khoảng thời gian
  final double expense;     // Chi tiêu
  final double income;      // Thu nhập
  final String label;       // Label hiển thị
}
```

## Cách sử dụng với Real Data

### 1. Sử dụng trong ExpenseChartSection (Đã tích hợp)
```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../core/di/injection_container.dart';
import '../services/chart_data_service.dart';
import 'charts/index.dart';

class ExpenseChartSection extends StatefulWidget {
  // ...
}

class _ExpenseChartSectionState extends State<ExpenseChartSection> {
  late final ChartDataService _chartDataService;
  List<ChartDataModel> _chartData = [];
  List<TrendData> _trendData = [];
  FinancialOverviewData? _financialOverviewData;

  @override
  void initState() {
    super.initState();
    _chartDataService = GetIt.instance<ChartDataService>();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    await Future.wait([
      _loadChartData(startDate, endDate),
      _loadTrendData(),
      _loadFinancialOverviewData(startDate, endDate),
    ]);
  }

  Future<void> _loadChartData(DateTime startDate, DateTime endDate) async {
    final data = await _chartDataService.getDonutChartData(
      startDate: startDate,
      endDate: endDate,
    );
    setState(() {
      _chartData = data;
    });
  }
}
```

### 2. Sử dụng DonutChart với Real Data
```dart
DonutChart(
  data: _chartData, // Dữ liệu từ ChartDataService
  size: 250,
  onCategoryTap: () {
    // Handle category tap
  },
)
```

### 3. Sử dụng TrendBarChart với Real Data
```dart
TrendBarChart(
  data: _trendData, // Dữ liệu từ ChartDataService
  height: 200,
  onTap: () {
    // Handle chart tap
  },
)
```

### 4. Sử dụng FinancialOverviewCards với Real Data
```dart
FinancialOverviewCards(
  data: _financialOverviewData, // Dữ liệu từ ChartDataService
  isLoading: _isLoading,
  onAllocationTap: () {
    // Handle allocation tap
  },
  onTrendTap: () {
    // Handle trend tap
  },
  onComparisonTap: () {
    // Handle comparison tap
  },
)
```

## Real Data Features

### ✅ Đã tích hợp
- **Real Data từ Firebase**: Lấy dữ liệu thực từ Firestore
- **Fallback to Mock Data**: Tự động sử dụng mock data nếu không có dữ liệu thực
- **Error Handling**: Xử lý lỗi khi không thể kết nối database
- **Loading States**: Hiển thị loading khi đang tải dữ liệu
- **Period Selection**: Hỗ trợ chọn khoảng thời gian (tháng, tuần, năm)
- **Category Mapping**: Map emoji icons từ category sang icon names
- **Color Conversion**: Convert int colors sang hex strings
- **Data Aggregation**: Tính toán tổng, phần trăm, xu hướng

### 🔄 Data Flow
1. **User Authentication**: Kiểm tra user đã đăng nhập
2. **Date Range**: Xác định khoảng thời gian cần lấy dữ liệu
3. **Firestore Query**: Query giao dịch từ Firestore
4. **Data Processing**: Tính toán và xử lý dữ liệu
5. **Category Mapping**: Map categories và icons
6. **UI Update**: Cập nhật giao diện với dữ liệu thực

### 📊 Data Sources
- **Transactions**: Từ `TransactionService` và Firestore
- **Categories**: Từ `CategoryService` và Firestore
- **User Data**: Từ Firebase Auth
- **Period Data**: Tính toán từ DateTime

## Testing

### Test Screen
Sử dụng `TestChartsScreen` để kiểm tra các components:

```dart
// Navigate to test screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const TestChartsScreen()),
);
```

### Mock Data
Nếu không có dữ liệu thực, module sẽ tự động sử dụng mock data:
- Donut chart: 5 danh mục chính với dữ liệu mẫu
- Trend chart: 3 tháng gần nhất với dữ liệu mẫu
- Financial overview: Tổng thu chi với so sánh tháng trước

## Performance

### ✅ Optimizations
- **Parallel Loading**: Load dữ liệu song song với `Future.wait`
- **Caching**: Sử dụng CategoryService cache
- **Efficient Queries**: Tối ưu Firestore queries
- **Memory Management**: Proper disposal và state management
- **Error Recovery**: Fallback mechanisms

### 📈 Scalability
- **Pagination**: Có thể thêm pagination cho large datasets
- **Real-time Updates**: Có thể thêm real-time listeners
- **Offline Support**: Tích hợp với OfflineService
- **Data Compression**: Có thể thêm data compression

## TODO

- [x] ✅ Kết nối với real data services
- [x] ✅ Implement error handling và loading states
- [x] ✅ Thêm fallback to mock data
- [ ] Implement navigation đến các màn hình chi tiết
- [ ] Thêm animations cho chart transitions
- [ ] Implement period selection (tháng, tuần, năm)
- [ ] Thêm export functionality
- [ ] Implement real-time data updates
- [ ] Thêm offline support
- [ ] Implement data caching
- [ ] Thêm analytics tracking 