@echo off
echo ==========================================
echo KryptoKart - Payment Backend Server
echo ==========================================
echo.
echo This server MUST be running before using
echo Razorpay payments in the Flutter app!
echo.

cd /d "%~dp0backend"

REM Check if node_modules exists
if not exist "node_modules\" (
    echo Installing dependencies...
    call npm install
    echo.
)

echo ==========================================
echo Starting Razorpay Payment Backend
echo ==========================================
echo.
echo Server URL: http://localhost:4000
echo.
echo For Android Emulator: Use http://10.0.2.2:4000
echo For Physical Device:  Use http://YOUR_PC_IP:4000
echo.
echo Press Ctrl+C to stop the server
echo ==========================================
echo.

call npm run dev
