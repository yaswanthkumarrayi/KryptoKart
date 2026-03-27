@echo off
echo ==========================================
echo KryptoKart - COMPLETE STARTUP GUIDE
echo ==========================================
echo.
echo This will help you run the complete payment flow.
echo.
echo STEP 1: Start the Payment Backend
echo ----------------------------------
echo Open a NEW terminal and run:
echo   cd %~dp0
echo   run_backend.bat
echo.
echo Wait until you see "Razorpay backend running on port 4000"
echo.
echo STEP 2: Start the Flutter App  
echo -----------------------------
echo In ANOTHER terminal, run:
echo   cd %~dp0
echo   run_flutter.bat
echo.
echo ==========================================
echo TROUBLESHOOTING
echo ==========================================
echo.
echo ERROR: "Order creation failed"
echo   - Make sure backend is running (run_backend.bat)
echo   - Check if port 4000 is not blocked
echo.
echo ERROR: "Cannot connect to payment server"
echo   - Backend must be running FIRST
echo   - For Android Emulator: URL should be http://10.0.2.2:4000
echo   - For Physical Device: Use your PC's IP address
echo.
echo ERROR: "Razorpay key is missing"
echo   - Use run_flutter.bat (not plain flutter run)
echo   - Or manually add: --dart-define=RAZORPAY_KEY_ID=rzp_test_S01qKJJ0ovAUGa
echo.
echo ==========================================
echo TEST CARD DETAILS (for Razorpay test mode)
echo ==========================================
echo   Card Number: 4111 1111 1111 1111
echo   Expiry:      Any future date (e.g., 12/25)
echo   CVV:         Any 3 digits (e.g., 123)
echo   OTP:         1234
echo.
echo ==========================================
echo.
pause
