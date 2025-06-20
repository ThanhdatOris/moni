# Moni Backend - Ứng dụng Quản lý Tài chính Cá nhân

## Tổng quan

Backend của ứng dụng Moni được thiết kế dựa trên Flutter với Firebase làm backend service và tích hợp AI thông qua Gemini API. Hệ thống cung cấp đầy đủ các chức năng quản lý tài chính cá nhân với khả năng AI hỗ trợ.

## Kiến trúc

### Models
- **UserModel**: Quản lý thông tin người dùng
- **TransactionModel**: Quản lý giao dịch tài chính (thu/chi)
- **CategoryModel**: Quản lý danh mục giao dịch (có hỗ trợ cấu trúc phân cấp)
- **BudgetAlertModel**: Quản lý cảnh báo ngân sách
- **ReportModel**: Quản lý báo cáo tài chính
- **ChatLogModel**: Lưu trữ lịch sử tương tác với AI chatbot

### Services
- **AuthService**: Xác thực người dùng với Firebase Auth
- **TransactionService**: CRUD giao dịch với Firestore
- **CategoryService**: Quản lý danh mục và tạo danh mục mặc định
- **BudgetAlertService**: Quản lý cảnh báo ngân sách và thông báo
- **ReportService**: Tạo báo cáo theo thời gian và danh mục
- **ChatLogService**: Lưu trữ và quản lý lịch sử chat
- **AIProcessorService**: Tích hợp Gemini API cho các tính năng AI
- **FirebaseService**: Khởi tạo và cấu hình Firebase

## Cơ sở dữ liệu Firestore

### Cấu trúc Collections

```
users/{userId}
├── subcollections:
│   ├── transactions/{transactionId}
│   ├── categories/{categoryId}
│   ├── budget_alerts/{alertId}
│   ├── reports/{reportId}
│   └── chat_logs/{interactionId}
```

### Security Rules

Firestore được cấu hình với security rules đảm bảo:
- Người dùng chỉ có thể truy cập dữ liệu của chính họ
- Validation dữ liệu phù hợp với schema
- Soft delete cho transactions thay vì xóa vĩnh viễn

## Tính năng AI

### Gemini API Integration
- **Trích xuất thông tin từ hình ảnh**: Nhận diện hóa đơn, tin nhắn ngân hàng
- **Gợi ý danh mục**: Tự động phân loại giao dịch
- **Chatbot tài chính**: Tư vấn và trả lời câu hỏi về tài chính
- **Phân tích thói quen chi tiêu**: Đưa ra lời khuyên cá nhân hóa

## Cài đặt và Chạy

### Yêu cầu
- Flutter SDK >= 3.6.1
- Firebase project đã được cấu hình
- Gemini API key

### Bước 1: Cài đặt dependencies
```bash
flutter pub get
```

### Bước 2: Cấu hình Firebase
1. Tạo Firebase project mới
2. Thêm các platform (Android, iOS, Web)
3. Tải về và cấu hình file config:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Cập nhật `lib/firebase_options.dart` với thông tin project

### Bước 3: Cấu hình Gemini API
1. Lấy API key từ Google AI Studio
2. Cập nhật API key trong `lib/services/ai_processor_service.dart`

### Bước 4: Cấu hình Firestore
1. Tạo Firestore database
2. Cấu hình Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Bước 5: Chạy ứng dụng
```bash
flutter run
```

## Cấu trúc thư mục

```
lib/
├── models/           # Data models
│   ├── user_model.dart
│   ├── transaction_model.dart
│   ├── category_model.dart
│   ├── budget_alert_model.dart
│   ├── report_model.dart
│   ├── chat_log_model.dart
│   └── models.dart   # Export file
├── services/         # Business logic services
│   ├── auth_service.dart
│   ├── transaction_service.dart
│   ├── category_service.dart
│   ├── budget_alert_service.dart
│   ├── report_service.dart
│   ├── chat_log_service.dart
│   ├── ai_processor_service.dart
│   ├── firebase_service.dart
│   ├── service_locator.dart
│   └── services.dart # Export file
├── firebase_options.dart
└── main.dart
```

## Sử dụng Services

### Khởi tạo trong main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await FirebaseService.initialize();
  
  // Khởi tạo Service Locator
  setupServiceLocator();
  
  runApp(MyApp());
}
```

### Sử dụng trong Widget

```dart
// Lấy service từ service locator
final authService = serviceLocator<AuthService>();
final transactionService = serviceLocator<TransactionService>();

// Sử dụng service
await authService.login(email: email, password: password);
final transactions = transactionService.getTransactions();
```

## API Reference

### AuthService
- `register()`: Đăng ký người dùng mới
- `login()`: Đăng nhập
- `logout()`: Đăng xuất
- `updateProfile()`: Cập nhật thông tin profile

### TransactionService
- `createTransaction()`: Tạo giao dịch mới
- `updateTransaction()`: Cập nhật giao dịch
- `deleteTransaction()`: Xóa giao dịch (soft delete)
- `getTransactions()`: Lấy danh sách giao dịch với filter
- `getTotalIncome()`: Tính tổng thu nhập
- `getTotalExpense()`: Tính tổng chi tiêu

### CategoryService
- `createCategory()`: Tạo danh mục mới
- `updateCategory()`: Cập nhật danh mục
- `deleteCategory()`: Xóa danh mục
- `getCategories()`: Lấy danh sách danh mục
- `createDefaultCategories()`: Tạo danh mục mặc định cho user mới

### AIProcessorService
- `extractImageInfo()`: Trích xuất thông tin từ hình ảnh
- `processChatInput()`: Xử lý input chat
- `suggestCategory()`: Gợi ý danh mục
- `answerQuestion()`: Trả lời câu hỏi tài chính

## Bảo mật

### Firebase Auth
- Xác thực email/password
- Tự động refresh token
- Logout an toàn

### Firestore Security
- Rules kiểm tra authentication
- Data validation
- Rate limiting

### API Key Security
- Gemini API key nên được lưu trữ an toàn
- Sử dụng environment variables trong production

## Monitoring và Logging

- Sử dụng Logger package để log events
- Firebase Analytics cho tracking user behavior
- Crashlytics cho crash reporting

## Phát triển tiếp

### Tính năng có thể mở rộng
1. Sync dữ liệu offline
2. Thông báo push notifications
3. Backup/restore dữ liệu
4. Multi-currency support
5. Advanced reporting với charts
6. Social features (chia sẻ báo cáo)
7. Integration với ngân hàng
8. Investment tracking

### Performance Optimization
1. Pagination cho large datasets
2. Image compression cho receipts
3. Caching strategies
4. Background sync

## Liên hệ và Hỗ trợ

Nếu có vấn đề hoặc cần hỗ trợ, vui lòng tạo issue trên repository hoặc liên hệ team phát triển. 