@echo off
REM ============================================
REM 用药提醒 App 打包脚本 v1.0
REM 构建前自动执行：静态分析 + 单元测试
REM ============================================

echo [1/4] 静态分析 flutter analyze...
flutter analyze
if %ERRORLEVEL% neq 0 (
    echo [FAIL] 静态分析未通过，修复后重试
    exit /b 1
)
echo [OK] 静态分析通过

echo [2/4] 运行测试 flutter test...
flutter test
if %ERRORLEVEL% neq 0 (
    echo [FAIL] 测试未通过，修复后重试
    exit /b 1
)
echo [OK] 测试通过

echo [3/4] 构建 APK...
flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo [FAIL] APK 构建失败
    exit /b 1
)

echo [4/4] APK 路径:
echo build\app\outputs\flutter-apk\app-release.apk

echo.
echo [DONE] 构建完成！