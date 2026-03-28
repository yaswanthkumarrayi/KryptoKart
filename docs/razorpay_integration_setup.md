# Razorpay Integration Setup (Secure)

This project now includes:

- Flutter client flow with Razorpay checkout and backend signature verification.
- Node.js backend with `/create-order` and `/verify-payment`.

## 1) Backend setup (Node.js / Express)

1. Open terminal at `backend`.
2. Install dependencies:

```bash
npm install
```

3. Create `.env` from `.env.example` and set credentials:

```env
PORT=4000
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxx
CORS_ORIGIN=*
```

4. Start backend:

```bash
npm run dev
```

Endpoints:

- `POST /create-order`  
  Request body: `{ "amount": 50000, "currency": "INR" }`
- `POST /verify-payment`  
  Request body:
  `{ "razorpay_order_id": "...", "razorpay_payment_id": "...", "razorpay_signature": "..." }`

## 2) Flutter setup

Razorpay plugin dependency already exists in `pubspec.yaml`:

- `razorpay_flutter`
- `dio`

Run app on Android/iOS with `--dart-define` values:

```bash
flutter run -d android \
  --dart-define=RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx \
  --dart-define=PAYMENT_BACKEND_URL=http://10.0.2.2:4000
```

Notes:

- Use `10.0.2.2` for Android emulator to access local backend.
- Use your machine IP for physical device, for example `http://192.168.x.x:4000`.
- Razorpay native checkout does not run on web/Chrome.

## 3) Files added/updated

- Backend:
  - `backend/server.js`
  - `backend/package.json`
  - `backend/.env.example`
- Flutter integration:
  - `lib/features/payments/data/services/upi_payment_service.dart` (secure backend order + verification)
- Standalone demo code:
  - `lib/razorpay_demo/main.dart`
  - `lib/razorpay_demo/payment_service.dart`

## 4) Using test keys (development)

For test mode:

- Set backend `.env` with test `RAZORPAY_KEY_ID` + `RAZORPAY_KEY_SECRET`.
- Start backend from `backend` directory (`npm run dev`).
- Run Flutter with test `RAZORPAY_KEY_ID` via `--dart-define`.
- Keep `key_secret` only on backend.
- Use Razorpay test payment methods only.

## 5) Security checklist

- Never ship `key_secret` in Flutter app.
- Validate all request inputs on backend.
- Verify signature server-side before marking payment success.
- Add server logs and monitor failed verification attempts.
