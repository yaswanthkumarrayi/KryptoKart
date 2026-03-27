@echo off
echo ======================================
echo KryptoKart Build Fix Script
echo ======================================

echo.
echo Step 1: Cleaning Flutter project...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo Step 2: Cleaning Gradle cache...
cd android
call gradlew.bat clean
cd ..

echo.
echo Step 3: Removing old build artifacts...
if exist "build" rmdir /s /q "build" 2>nul
if exist "android\.gradle" rmdir /s /q "android\.gradle" 2>nul
if exist "android\app\build" rmdir /s /q "android\app\build" 2>nul

echo.
echo Step 4: Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo Step 5: Running Flutter on Android...
call flutter run -v
if errorlevel 1 (
    echo ERROR: Flutter run failed
    pause
    exit /b 1
)

echo.
echo ======================================
echo Build completed successfully!
echo ======================================
pause

