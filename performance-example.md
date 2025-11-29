Qua kiểm thử thực tế trên thiết bị Redmi Note 9S (Android), kết quả đo lường như
 sau:
 • Kích thước ứng dụng: APK Release = 112.15MB, APK Profile = 88.25MB. Tree
shaking giảm MaterialIcons từ 1.6MB xuống 22KB (98.7%).
 • Source code: 190 files Dart, tổng 1.63MB (1,630,251 bytes), cấu trúc modular.
 • Thời gian build: Release build = 238.7s, Profile build = 6.4s. Release build chậm
 do optimization.
 • GPU rendering: Automatic fallback từ Vulkan sang OpenGLES, đảm bảo tương
 thích đa thiết bị.
 • Memorymanagement: ProfileInstaller active, financial data load thành công.
 • Developer tools: DevTools server port 9101, VM Service port 24325, debugging
 infrastructure hoàn chỉnh.
 • AI models: Google ML Kit OCR models (latin script) load thành công, kích thước
 model 10MB.
 • Thời gian khởi động: 2.1s (cold start), 0.8s (warm start)- đạt tiêu chuẩn tốt cho
 ứng dụng Flutter.
 • Thời gian phản hồi: Thêm giao dịch < 300ms, tìm kiếm < 500ms, đồng bộ cloud
 < 2s.
