@echo off
echo ==========================================
echo KryptoKart - Run on Physical Device
echo ==========================================

cd /d "%~dp0"

REM =============================================
REM RAZORPAY CONFIGURATION
REM =============================================
set RAZORPAY_KEY_ID=rzp_test_S01qKJJ0ovAUGa

REM IMPORTANT: Replace with YOUR machine's local IP address
REM Find your IP: Open CMD and run "ipconfig"
REM Look for "IPv4 Address" under your active network adapter
set MACHINE_IP=192.168.1.100
set PAYMENT_BACKEND_URL=http://%MACHINE_IP%:4000

echo.
echo Configuration:
echo   RAZORPAY_KEY_ID: %RAZORPAY_KEY_ID%
echo   PAYMENT_BACKEND_URL: %PAYMENT_BACKEND_URL%
echo.
echo IMPORTANT: Update MACHINE_IP in this script to your actual IP!
echo.

call flutter pub get
call flutter run --dart-define=RAZORPAY_KEY_ID=%RAZORPAY_KEY_ID% --dart-define=PAYMENT_BACKEND_URL=%PAYMENT_BACKEND_URL%

pause
