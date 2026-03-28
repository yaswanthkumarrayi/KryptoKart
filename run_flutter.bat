@echo off
echo ==========================================
echo KryptoKart - Flutter App Runner
echo ==========================================
echo.
echo IMPORTANT: Before running, ensure:
echo   1. Backend is running (run_backend.bat)
echo   2. Android emulator/device is connected
echo.

cd /d "%~dp0"

REM =============================================
REM RAZORPAY CONFIGURATION (Test Keys)
REM =============================================
set RAZORPAY_KEY_ID=rzp_test_S01qKJJ0ovAUGa
set PAYMENT_BACKEND_URL=http://10.0.2.2:4000

echo Configuration:
echo   RAZORPAY_KEY_ID:     %RAZORPAY_KEY_ID%
echo   PAYMENT_BACKEND_URL: %PAYMENT_BACKEND_URL%
echo.

echo Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo.
    echo ERROR: flutter pub get failed!
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Starting Flutter App...
echo ==========================================
echo.
call flutter run --dart-define=RAZORPAY_KEY_ID=%RAZORPAY_KEY_ID% --dart-define=PAYMENT_BACKEND_URL=%PAYMENT_BACKEND_URL%

pause
