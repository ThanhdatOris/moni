@echo off
echo Copying Moni app icons...

REM Thay đổi đường dẫn nguồn tại đây nếu cần
set SOURCE_DIR=D:\da3-flutter-doc\logo\moni-icon
set TARGET_DIR=%~dp0android\app\src\main\res

REM Copy icons với kích thước phù hợp
echo Copying hdpi icon (72x72)...
copy "%SOURCE_DIR%\ic_launcher_72.png" "%TARGET_DIR%\mipmap-hdpi\ic_launcher.png"

echo Copying mdpi icon (48x48)...
copy "%SOURCE_DIR%\ic_launcher_48.png" "%TARGET_DIR%\mipmap-mdpi\ic_launcher.png"

echo Copying xhdpi icon (96x96)...
copy "%SOURCE_DIR%\ic_launcher_96.png" "%TARGET_DIR%\mipmap-xhdpi\ic_launcher.png"

echo Copying xxhdpi icon (144x144)...
copy "%SOURCE_DIR%\ic_launcher_144.png" "%TARGET_DIR%\mipmap-xxhdpi\ic_launcher.png"

echo Copying xxxhdpi icon (192x192)...
copy "%SOURCE_DIR%\ic_launcher_192.png" "%TARGET_DIR%\mipmap-xxxhdpi\ic_launcher.png"

echo Done! Icons have been copied successfully.
pause
