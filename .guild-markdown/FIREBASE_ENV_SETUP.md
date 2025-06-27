# 🔥 Hướng dẫn thiết lập Firebase với file .env

## ⚡ Vấn đề đã được giải quyết

**Vấn đề:** Đăng nhập bị treo vì Firebase configuration sử dụng placeholder values (`your-project-id`, `your-api-key`, etc.)

**Giải pháp:** Sử dụng file `.env` để quản lý Firebase configuration một cách an toàn và linh hoạt.

## 🔧 Các thay đổi đã thực hiện:

1. **✅ Cập nhật `firebase_options.dart`:** Sử dụng `EnvironmentService` thay vì hardcode
2. **✅ Cập nhật `firebase_service.dart`:** Thêm initialization cho EnvironmentService
3. **✅ Cập nhật `auth_screen.dart`:** Thêm timeout handling và error detection
4. **✅ Tạo `env_template.txt`:** Template cho file .env
5. **✅ `EnvironmentService` đã có sẵn:** Đọc và quản lý environment variables

## 📋 Hướng dẫn thiết lập:

### Bước 1: Tạo file .env

```bash
# Copy template thành file .env
copy env_template.txt .env
```

### Bước 2: Lấy thông tin Firebase

1. **Truy cập Firebase Console:**
   ```
   https://console.firebase.google.com
   ```

2. **Chọn project của bạn hoặc tạo project mới**

3. **Vào Project Settings:**
   - Click vào icon ⚙️ (Settings) > Project Settings
   - Chọn tab **General**

4. **Tìm "Your apps" section:**
   - Nếu chưa có app, click **Add app** > **Android** (🤖)
   - Nếu đã có app, scroll xuống phần "SDK setup and configuration"

5. **Copy các thông tin sau:**
   ```javascript
   // Từ Firebase Config object:
   const firebaseConfig = {
     apiKey: "AIza...",              // ← Copy này
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",   // ← Copy này  
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789", // ← Copy này
     appId: "1:123:android:abc"      // ← Copy này
   };
   ```

### Bước 3: Cập nhật file .env

Mở file `.env` và thay thế các giá trị:

```env
# FIREBASE CONFIGURATION
FIREBASE_PROJECT_ID=your-actual-project-id
FIREBASE_API_KEY=AIzaSyABC123...your-actual-api-key
FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com  
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID=1:123456:android:abcdef

# Các config khác giữ nguyên...
APP_NAME=Moni
ENVIRONMENT=development
DEBUG_MODE=true
```

### Bước 4: Enable Authentication

1. **Trong Firebase Console:**
   - Vào **Authentication** > **Sign-in method**
   - Enable **Email/Password**
   - Enable **Anonymous** (optional)

2. **Trong Firestore Database:**
   - Vào **Firestore Database** > **Create database**
   - Chọn **Start in test mode** (cho development)

### Bước 5: Test ứng dụng

```bash
flutter clean
flutter pub get
flutter run
```

## 🚨 Các lỗi thường gặp và cách khắc phục:

### 1. "Firebase configuration chưa được thiết lập"
- **Nguyên nhân:** File `.env` chưa tồn tại hoặc chưa có giá trị đúng
- **Giải pháp:** Tạo file `.env` và cập nhật values từ Firebase Console

### 2. "Timeout: Kết nối đến Firebase bị treo"
- **Nguyên nhân:** API keys không đúng hoặc project không tồn tại
- **Giải pháp:** Kiểm tra lại Project ID và API Key

### 3. "Permission denied" trong Firestore
- **Nguyên nhân:** Security rules chặn
- **Giải pháp:** Cập nhật Firestore rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

### 4. "User not found" khi đăng nhập
- **Nguyên nhân:** Tài khoản test chưa được tạo
- **Giải pháp:** Dùng chức năng đăng ký hoặc đăng nhập anonymous

## 🔒 Bảo mật:

- ✅ File `.env` đã được thêm vào `.gitignore`
- ✅ Không commit sensitive data vào git
- ✅ Sử dụng different .env cho mỗi environment (dev, staging, prod)

## 🎯 Lợi ích của việc sử dụng .env:

1. **Bảo mật:** Không hardcode sensitive information
2. **Linh hoạt:** Dễ dàng switch giữa development/production
3. **Team work:** Mỗi developer có thể có config riêng
4. **CI/CD:** Dễ dàng deploy với different configs

## ✅ Checklist hoàn thành:

- [ ] Copy `env_template.txt` thành `.env`
- [ ] Cập nhật Firebase values trong `.env`
- [ ] Enable Authentication trong Firebase Console
- [ ] Create Firestore Database
- [ ] Test đăng nhập/đăng ký trong app
- [ ] Verify không còn timeout errors

---

🚀 **Sau khi hoàn thành setup, ứng dụng sẽ hoạt động bình thường không còn bị treo khi đăng nhập!** 