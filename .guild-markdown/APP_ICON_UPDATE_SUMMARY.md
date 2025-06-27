# Cập Nhật Icon Ứng Dụng Moni

## Tóm Tắt

Đã thay thế toàn bộ icon của ứng dụng Moni với logo mới từ thư mục `moni-logo/`. Icon mới đã được áp dụng cho tất cả platform: Android, iOS và Web.

## Platform Được Cập Nhật

### 🤖 Android
**Thư mục:** `android/app/src/main/res/`

✅ **Các file đã copy:**
- `mipmap-anydpi-v26/ic_launcher.xml` - Adaptive icon configuration
- `mipmap-hdpi/` - Icon 72x72px (HDPI)
- `mipmap-mdpi/` - Icon 48x48px (MDPI)  
- `mipmap-xhdpi/` - Icon 96x96px (XHDPI)
- `mipmap-xxhdpi/` - Icon 144x144px (XXHDPI)
- `mipmap-xxxhdpi/` - Icon 192x192px (XXXHDPI)
- `play_store_512.png` - Play Store icon 512x512px

**Mỗi thư mục mipmap chứa:**
- `ic_launcher.png` - Icon chính
- `ic_launcher_background.png` - Background layer (adaptive icon)
- `ic_launcher_foreground.png` - Foreground layer (adaptive icon)
- `ic_launcher_monochrome.png` - Monochrome version (Android 13+)

### 🍎 iOS
**Thư mục:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

✅ **Các file đã copy:**
- `AppIcon-20@2x.png` - 40x40px (iPhone)
- `AppIcon-20@3x.png` - 60x60px (iPhone)
- `AppIcon-29@2x.png` - 58x58px (Settings)
- `AppIcon-29@3x.png` - 87x87px (Settings)
- `AppIcon-40@2x.png` - 80x80px (Spotlight)
- `AppIcon-40@3x.png` - 120x120px (Spotlight)
- `AppIcon@2x.png` - 120x120px (App Icon)
- `AppIcon@3x.png` - 180x180px (App Icon)
- `AppIcon~ios-marketing.png` - 1024x1024px (App Store)
- `Contents.json` - Metadata file

**iPad variants:**
- `AppIcon-20~ipad.png` - 20x20px
- `AppIcon-20@2x~ipad.png` - 40x40px
- `AppIcon-29~ipad.png` - 29x29px
- `AppIcon-29@2x~ipad.png` - 58x58px
- `AppIcon-40~ipad.png` - 40x40px
- `AppIcon-40@2x~ipad.png` - 80x80px
- `AppIcon@2x~ipad.png` - 152x152px
- `AppIcon~ipad.png` - 76x76px
- `AppIcon-83.5@2x~ipad.png` - 167x167px

**CarPlay variants:**
- `AppIcon-60@2x~car.png` - 120x120px
- `AppIcon-60@3x~car.png` - 180x180px

### 🌐 Web
**Thư mục:** `web/`

✅ **Các file đã copy:**
- `favicon.ico` - Browser favicon
- `apple-touch-icon.png` - Apple touch icon 180x180px
- `icon-192.png` - PWA icon 192x192px
- `icon-512.png` - PWA icon 512x512px
- `icon-192-maskable.png` - Maskable icon 192x192px
- `icon-512-maskable.png` - Maskable icon 512x512px

## Files Được Cập Nhật

### web/index.html
```html
<!-- Favicon -->
<link rel="icon" type="image/x-icon" href="favicon.ico">
<link rel="icon" type="image/png" sizes="192x192" href="icon-192.png">
<link rel="icon" type="image/png" sizes="512x512" href="icon-512.png">

<!-- Apple touch icon -->
<link rel="apple-touch-icon" href="apple-touch-icon.png">
```

### web/manifest.json
```json
{
    "name": "Moni - Quản lý tài chính cá nhân",
    "short_name": "Moni",
    "description": "Ứng dụng quản lý tài chính cá nhân thông minh và dễ sử dụng",
    "background_color": "#1E40AF",
    "theme_color": "#1E40AF",
    "icons": [
        {
            "src": "icon-192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "icon-512.png", 
            "sizes": "512x512",
            "type": "image/png"
        },
        {
            "src": "icon-192-maskable.png",
            "sizes": "192x192", 
            "type": "image/png",
            "purpose": "maskable"
        },
        {
            "src": "icon-512-maskable.png",
            "sizes": "512x512",
            "type": "image/png", 
            "purpose": "maskable"
        }
    ]
}
```

## Các Cải Tiến

1. **Adaptive Icons**: Android sử dụng adaptive icon với separate background/foreground layers
2. **Monochrome Support**: Android 13+ themed icons
3. **PWA Ready**: Web app có đầy đủ icon sizes cho Progressive Web App
4. **High Resolution**: Support tất cả pixel densities và screen sizes
5. **Modern Standards**: Tuân thủ design guidelines của từng platform

## Next Steps

1. **Test trên thiết bị thực**: Build và test icon trên Android/iOS devices
2. **Play Store/App Store**: Sử dụng `play_store_512.png` và `AppIcon~ios-marketing.png` cho store listings
3. **Branding consistency**: Đảm bảo icon phù hợp với brand identity của Moni

## Backup

Icon cũ vẫn được giữ trong:
- `web/icons/` (legacy icons)
- Có thể xóa sau khi confirm icon mới hoạt động tốt

---

**Hoàn thành:** ✅ Tất cả platform đã được cập nhật với icon mới
**Trạng thái:** 🟢 Ready for testing và deployment 