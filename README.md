# App Quản lý tài chính cá nhân Moni 💰

Ứng dụng quản lý tài chính cá nhân thông minh được xây dựng bằng Flutter với giao diện đẹp và nhiều tính năng hữu ích.

## ✨ Tính năng chính

### 1. 📝 Ghi chép giao dịch
- **Nhập thông thường**: Giao diện trực quan, dễ sử dụng với các template có sẵn
- **Nhập bằng ảnh**: Scan hóa đơn tự động trích xuất thông tin (sử dụng AI)
- **Trợ lý ảo thông minh**: Chatbot hỗ trợ nhập liệu và tự động phân loại

### 2. 📊 Quản lý danh mục
- Danh mục thu chi với icons và màu sắc đẹp mắt
- Danh mục mặc định: Ăn uống, Di chuyển, Mua sắm, Giải trí, v.v.
- Thêm/sửa/xóa danh mục tùy chỉnh
- Hỗ trợ phân cấp danh mục cha/con

### 3. 📈 Phân tích tài chính
- **Báo cáo chi tiết**: Biểu đồ tròn, biểu đồ cột, đường xu hướng
- **So sánh thu chi** theo danh mục và thời gian
- **Xu hướng chi tiêu** theo tháng/quý/năm
- **Cảnh báo thông minh**: Thông báo vượt ngân sách, dự báo chi tiêu

## 🎨 Giao diện

App được thiết kế với:
- Màu sắc hiện đại và thân thiện
- Animations mượt mà
- Dark/Light mode support (sẽ có trong tương lai)
- Responsive trên nhiều kích thước màn hình

## 🏗️ Cấu trúc dự án

```
lib/
├── constants/          # Định nghĩa màu sắc, strings
├── models/            # Data models (Transaction, Category)
├── screens/           # Các màn hình chính
├── widgets/           # Widget tái sử dụng
├── services/          # API services, database
├── utils/             # Utility functions
└── main.dart          # Entry point
```

## 🚀 Cài đặt và chạy

### Yêu cầu
- Flutter SDK >= 3.6.1
- Dart >= 3.6.1
- Android Studio / VS Code
- Android/iOS simulator hoặc device

### Bước cài đặt

1. **Cài đặt dependencies**
```bash
flutter pub get
```

1. **Chạy app**
```bash
flutter run
```

## 📦 Dependencies chính

- **UI & Charts**: `pie_chart`, `fl_chart`, `lottie`
- **Camera & Image**: `image_picker`, `camera`
- **Database**: `sqflite`, `shared_preferences`
- **HTTP**: `dio`, `http`
- **State Management**: `provider`
- **Utils**: `intl`, `uuid`, `path`

## 🔮 Tính năng sắp tới

- [ ] **Backend Integration**: API server với Firebase
- [ ] **Sync đa thiết bị**: Đồng bộ dữ liệu qua cloud
- [ ] **Báo cáo nâng cao**: Xuất PDF, Excel
- [ ] **Mục tiêu tiết kiệm**: Lập kế hoạch và theo dõi mục tiêu
- [ ] **Nhắc nhở thông minh**: Push notifications
- [ ] **Phân tích xu hướng AI**: Machine learning insights
- [ ] **Multi-currency**: Hỗ trợ nhiều loại tiền tệ
- [ ] **Family sharing**: Chia sẻ tài khoản gia đình

## 🛠️ Phát triển

### Thêm màn hình mới
1. Tạo file trong `lib/screens/`
2. Thêm route vào `main.dart`
3. Cập nhật navigation

### Thêm model mới
1. Tạo class trong `lib/models/`
2. Implement `toMap()` và `fromMap()`
3. Thêm database migration nếu cần

### Thêm API service
1. Tạo service trong `lib/services/`
2. Sử dụng `dio` để call API
3. Handle error và loading states

## 🎯 Best Practices

- **State Management**: Sử dụng Provider pattern
- **Code Organization**: Feature-based folder structure
- **Error Handling**: Try-catch và user-friendly messages
- **Performance**: Lazy loading và caching
- **Testing**: Unit tests cho business logic

## 📄 License

Dự án này được phát hành dưới license MIT. Xem file `LICENSE` để biết thêm chi tiết.

## 👥 Team

- **Developer**: [Tên của bạn]
- **Designer**: [Tên designer]
- **Product Manager**: [Tên PM]

## 📞 Liên hệ

- **Email**: contact@moni-app.com
- **Website**: https://moni-app.com
- **Facebook**: fb.com/moniapp
- **Twitter**: @moniapp

---

Made with ❤️ in Vietnam

## 📝 Changelog

### v1.0.0 (Current)
- ✅ Giao diện cơ bản
- ✅ Nhập giao dịch manual
- ✅ Danh mục mặc định
- ✅ Biểu đồ phân tích cơ bản
- ✅ Mock data và UI components

### v1.1.0 (Planned)
- 🔄 Backend integration
- 🔄 Real database
- 🔄 User authentication
- 🔄 Advanced analytics

// Widget để hiển thị biểu đồ tròn
class TransactionPieChart extends StatelessWidget {
  const TransactionPieChart({super.key});

  // Dữ liệu giả cho biểu đồ
  final Map<String, double> dataMap = const {
    "Ăn uống": 500000,
    "Mua sắm": 300000,
    "Di chuyển": 150000,
    "Giải trí": 200000,
    "Hóa đơn": 250000,
  };

  // Danh sách màu sắc tương ứng với các thuộc tính
  final List<Color> colorList = const [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PieChart(
        dataMap: dataMap,
        animationDuration: const Duration(milliseconds: 800),
        chartLegendSpacing: 48,
        chartRadius:
            MediaQuery.of(context).size.width / 2.2, // Kích thước biểu đồ
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring, // Kiểu biểu đồ (ring hoặc pie)
        ringStrokeWidth: 40, // Độ dày của vòng tròn
        centerText: "CHI TIÊU",
        legendOptions: const LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        chartValuesOptions: const ChartValuesOptions(
          showChartValueBackground: true,
          showChartValues: true,
          showChartValuesInPercentage: true, // Hiển thị theo phần trăm
          showChartValuesOutside: false,
          decimalPlaces: 1,
        ),
      ),
    );
  }
}
