### Kế hoạch cải thiện Backend/AI (Checklist)

Tài liệu checklist các hạng mục đề xuất để tối ưu workflow Quản lý giao dịch, Quản lý danh mục, và các module AI/OCR. Nhóm theo mức ưu tiên, có tham chiếu file để thực thi nhanh.

### Ưu tiên cao
- [x] Firestore indexing & truy vấn server-side cho giao dịch (`lib/services/transaction_service.dart`)
  - [x] Tạo composite index (script tự động) cho các truy vấn phổ biến:
    - [x] `transactions`: `date desc/asc` (single field, hỗ trợ range queries)
    - [x] `categories`: `is_deleted + name` (cho category lookups)
    - [x] `spending_limits`: `category_id + period_type`
    - [x] `category_usage`: `category_id + last_used desc`
  - [x] Cập nhật `getTransactions(...)` để hỗ trợ kết hợp nhiều filter + `orderBy('date', descending: true)` thay vì fallback lọc client
  - [x] Cập nhật các hàm tổng hợp `getTotalIncome/getTotalExpense` dùng index + `orderBy` phù hợp
  - [x] Tạo scripts tự động triển khai: `firebase_index_manager.bat`, `firestore_troubleshoot.bat`

- [x] Hoàn thiện JSON parsing từ AI (`lib/services/ai_processor_service.dart`)
  - [x] Parse JSON thật trong `_parseAIAnalysisResponse(...)` (sử dụng `dart:convert`) thay vì dữ liệu mẫu
  - [x] Chuẩn hóa output keys: `verified_amount`, `description`, `category_suggestion`, `transaction_type`, `confidence_score`, `notes`
  - [x] Đảm bảo tương thích với `_applyScanResults(...)` tại `lib/screens/transaction/add_transaction_screen.dart`

- [x] Recent transactions cho validations (duplicate/limit/advanced) (`lib/screens/transaction/add_transaction_screen.dart`)
  - [x] Implement `_getRecentTransactions()` dùng `TransactionService.getTransactions(startDate: now-30d, endDate: now, limit: N)`
  - [x] Truyền dữ liệu này vào `DuplicateDetectionService`, `SpendingLimitService`, `AdvancedValidationService`

- [x] Đồng bộ hóa Limits/Usage sang Firestore (thay vì SharedPreferences)
  - [x] Thiết kế sưu tập:
    - [x] `users/{uid}/limits/{id}`: `{categoryId, categoryName, amount, type(daily|weekly|monthly), allowOverride, createdAt, updatedAt}`
    - [x] `users/{uid}/category_usage/{categoryId_type}`: `{count, totalAmount, lastUsed, hourlyUsage{ "8": 3, ... }}`
  - [x] Refactor `SpendingLimitService` (`lib/services/spending_limit_service.dart`) và `CategoryUsageTracker` (`lib/services/category_usage_tracker.dart`) để đọc/ghi Firestore, vẫn giữ cache local tùy chọn

### Ưu tiên trung bình
- [ ] Assistant tab: Chuẩn hoá UI và tái sử dụng giữa các mini module (Analytics/Budget/Reports/Chatbot)
  - [ ] Tạo `lib/screens/assistant/widgets/assistant_tab_scaffold.dart`
    - [ ] Scaffold chung gồm: Container header + TabBar (config màu) + TabBarView (children)
    - [ ] Props: `controller`, `tabs: List<AssistantTabItem(icon, text)>`, `color`, `labelStyle`, `unselectedLabelStyle`
  - [ ] Tạo `AssistantTabBar` (nếu muốn tách riêng TabBar) để dùng lại trong 4 module
  - [ ] Thay thế code TabBar trùng lặp ở:
    - [ ] `lib/screens/assistant/modules/analytics/analytics_screen.dart`
    - [ ] `lib/screens/assistant/modules/budget/budget_screen.dart`
    - [ ] `lib/screens/assistant/modules/reports/reports_screen.dart`
    - [ ] `lib/screens/assistant/modules/chatbot/chatbot_screen.dart`
  - [ ] Chuẩn hoá màu theo module thông qua constants (ví dụ: Analytics=blue, Budget=green, Reports=purple, Chatbot=teal)
  - [ ] Tạo `AssistantStatusView` (wrapper): nhận `isLoading`, `hasError`, `errorMessage`, `onRetry`, `child` → dùng `AssistantLoadingCard`/`AssistantErrorCard` để giảm lặp
  - [ ] Cân nhắc hợp nhất điều hướng: dùng `AssistantNavigationBar` trong `AssistantScreen` hoặc gom logic custom vào một component dùng chung

- [ ] Pagination & lazy load cho lịch sử giao dịch
  - [x] Thêm `startAfterDocument/limit` trong `TransactionService.getTransactions`
  - [ ] Cập nhật UI `TransactionHistoryScreen` để nạp theo trang

- [ ] Báo cáo dữ liệu thật (thay preview/sample)
  - [x] Xây `ReportService` (đã có): tổng hợp thu/chi theo kỳ, phân bố theo danh mục, trend theo tháng
  - [ ] Kết nối `lib/screens/assistant/modules/reports/reports_screen.dart` để lấy dữ liệu thật thay vì sample ở `widgets/report_preview_container.dart`

- [ ] Nâng cấp gợi ý danh mục bằng AI + quy tắc người dùng
  - [ ] Bảng từ khóa danh mục tùy chỉnh per-user (Firestore) + cache kết quả gợi ý trong `AIProcessorService`
  - [ ] (Tuỳ chọn) Embeddings nhẹ, hoặc heuristic đa ngôn ngữ cho accuracy cao hơn

- [ ] Củng cố offline-first & reconcile
  - [ ] Xác định chiến lược hòa giải xung đột trong `OfflineSyncService` (last-write-wins theo `updated_at` hoặc merge theo trường)
  - [ ] Nhật ký hàng đợi sync để debug sự cố

### Ưu tiên thấp
- [ ] Cloud Functions
  - [ ] Endpoint tổng hợp báo cáo (server-side aggregation), scheduled job cảnh báo vượt hạn mức

- [ ] Bảo mật & quan sát
  - [ ] Bổ sung Firestore Security Rules ràng buộc `user_id`
  - [ ] Logging/metrics (số giao dịch, latency, lỗi index)

- [ ] Chatbot Assistant
  - [ ] Hoàn thiện `assistant_chat_service.dart` để kết nối AI thực tế cho nghiệp vụ

### Kiểm thử & chất lượng
- [ ] Unit test
  - [ ] `ai_processor_service.dart`: `_parseAIAnalysisResponse`, `_parseAmount`, combine OCR+AI
  - [ ] `duplicate_detection_service.dart`: biên độ thời gian/số tiền/note
  - [ ] `advanced_validation_service.dart`: z-score, tần suất, weekday pattern, recurring
  - [ ] `spending_limit_service.dart`: các ngưỡng cảnh báo và block logic
  - [ ] `transaction_service.dart`: truy vấn với index và fallback

- [ ] Tải & hiệu năng
  - [ ] Đo băng thông/latency trước–sau khi dùng index server-side
  - [ ] Kiểm thử dataset lớn cho lịch sử & tổng hợp

### Lộ trình triển khai tham khảo
- [x] B1: Tạo index + cập nhật truy vấn `TransactionService` (đã cập nhật service; cần tạo index trên console)
- [x] B2: Implement recent transactions + chuyển Limits/Usage sang Firestore (kèm migration nhẹ khi online)
- [ ] B3: `ReportService` dữ liệu thật, thay thế sample trong Reports
- [x] B4: Parse JSON AI thật (đã làm); (chưa thêm retry/backoff/circuit breaker)
- [ ] B5: Pagination lịch sử + tối ưu UI filter/search

### Tham chiếu file chính
- `lib/services/transaction_service.dart`
- `lib/services/ai_processor_service.dart`
- `lib/services/spending_limit_service.dart`
- `lib/services/category_usage_tracker.dart`
- `lib/screens/transaction/add_transaction_screen.dart`
- `lib/screens/history/transaction_history_screen.dart`
- `lib/screens/assistant/modules/reports/reports_screen.dart`
- `lib/screens/assistant/modules/reports/widgets/report_preview_container.dart`

Ghi chú: Giữ chuẩn màu từ `AppColors` và dùng `utils/formatting/currency_formatter.dart` cho hiển thị số tiền. Các thay đổi UI không ảnh hưởng `lib/widgets/menubar.dart`.


