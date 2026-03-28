# KryptoKart - Universal Billing & Payment App

A production-ready Flutter-based point-of-sale and unified payment application that combines barcode-driven shopping with UPI and cryptocurrency payments. Scan any QR code—product barcode, UPI payment, or ETH wallet—and the app handles it seamlessly with a single integrated interface.

## 🎯 Core Philosophy

**Scan Anything → Pay Anything → Track Everything**

KryptoKart unifies traditional POS systems with modern fintech, enabling merchants and users to:
- Scan products, QR codes, and wallet addresses with a single camera interface
- Accept UPI and cryptocurrency (ETH/MATIC) payments in real-time
- Manage inventory, transactions, and crypto holdings from one platform
- Print receipts via Bluetooth thermal printers (ESC/POS)

---

## ✨ Key Features

### 🛍️ **Universal QR Scanner**
- Single camera interface detects product barcodes, UPI QR codes, and crypto wallet addresses
- Real-time classification without launching external apps
- Barcode lookup with instant product add-to-cart

### 💳 **Shop & Go Mode**
- Live camera scanning adds products to cart in real-time
- Instant price calculation and inventory updates
- Dynamic cart management with quantity adjustments

### 💰 **Unified Payment System**
- **UPI Payments**: In-app Razorpay SDK integration (no external redirects)
- **Crypto Payments**: ETH/MATIC via WalletConnect v2 with live market prices
- **Real-time Price Oracle**: CoinGecko API for accurate crypto conversion rates

### 📦 **Product Management**
- Full CRUD operations with barcode association
- Local Hive database for offline inventory management
- Instant barcode lookup and product search

### 🧾 **Transaction Management**
- Complete transaction history with filtering and export
- Receipt generation and printing via Bluetooth thermal printers (ESC/POS)
- Transaction analytics and reporting

### 👤 **User Management**
- JWT-based authentication and session management
- KYC verification workflow (PAN, Aadhaar, Bank Details)
- Wallet address management for crypto transactions

### 📊 **Dashboard & Analytics**
- Real-time portfolio analysis (UPI + Crypto holdings)
- Transaction statistics and trends
- Market data visualization with FL Charts

### 🌙 **Design & UX**
- Material 3 Dark Theme with consistent branding
- Glassmorphism UI components with accent glows
- Smooth animations and transitions with Flutter Animate

---

## 🛠️ **Tech Stack**

### **Frontend (Flutter)**

| Layer | Technology | Purpose |
|---|---|---|
| **UI Framework** | Flutter 3.8+, Material 3 | Cross-platform mobile UI |
| **State Management** | Flutter BLoC 8.x | Business logic and state handling |
| **Navigation** | GoRouter 14.x | App routing and deep linking |
| **Local Database** | Hive 2.x | Fast, offline data persistence |
| **HTTP Client** | Dio 5.4+ | Network requests with interceptors |
| **QR/Barcode Scanner** | mobile_scanner 5.1+ | Camera-based barcode detection |
| **Payment - UPI** | razorpay_flutter 1.3.7 | Razorpay SDK integration |
| **Payment - Crypto** | walletconnect_flutter_v2 2.3.1 | WalletConnect v2 session management |
| **Database Storage** | shared_preferences, flutter_secure_storage | Secure credential and preference storage |
| **Crypto Price API** | CoinGecko (REST) | Real-time ETH/MATIC price feeds |
| **Charts** | fl_chart 0.68+ | Transaction and wallet analytics visualization |
| **Animations** | flutter_animate 4.5+ | Smooth UI transitions |
| **Typography** | google_fonts + Poppins | Material 3 compliant typography |
| **Image Caching** | cached_network_image 3.3+ | Network image lazy loading |
| **Connectivity** | connectivity_plus 6.0+ | Network status monitoring |
| **Image Picker** | image_picker 1.0.7+ | Camera and gallery integration |
| **Local Auth** | local_auth 2.3.0+ | Biometric authentication |
| **Permissions** | permission_handler 11.3+ | Runtime permission management |
| **Utilities** | uuid, intl, url_launcher, vibration | Helper libraries |
| **Service Locator** | get_it 7.6+ | Dependency injection container |

### **Backend (Node.js)**

| Component | Technology | Version | Purpose |
|---|---|---|---|
| **Runtime** | Node.js | 18+ | JavaScript runtime |
| **Framework** | Express.js | 4.19+ | REST API framework |
| **Database** | MongoDB | 6.0+ | NoSQL document database |
| **ODM** | Mongoose | 8.2.0 | MongoDB schema and validation |
| **Authentication** | JWT (jsonwebtoken) | 9.0.2 | Token-based auth |
| **Password Hashing** | bcryptjs | 2.4.3 | Secure password storage |
| **Payment Gateway** | Razorpay | 2.9.4 | UPI payment processing |
| **CORS** | cors | 2.8.5 | Cross-origin request handling |
| **Logging** | morgan | 1.10.0 | HTTP request logging |
| **Validation** | validator | 13.11.0 | Input validation utilities |
| **Environment Config** | dotenv | 16.4.5 | Environment variable management |

---

## 📁 **Detailed Project Structure**

### **Frontend (lib/) Structure**
```
lib/
├── main.dart                                    # App entry point, service locator init
├── config/
│   └── routes/
│       └── app_routes.dart                      # GoRouter configuration & deep linking
│
├── core/
│   ├── data/
│   │   ├── hive_boxes.dart                      # Hive box initialization
│   │   └── local_storage.dart                   # Local storage abstractions
│   ├── error/
│   │   ├── failures.dart                        # Custom failure types
│   │   └── exceptions.dart                      # Custom exception classes
│   ├── theme/
│   │   ├── app_theme.dart                       # Material 3 dark theme
│   │   ├── app_colors.dart                      # Color constants
│   │   └── app_text_styles.dart                 # Typography styles
│   ├── utils/
│   │   ├── app_validators.dart                  # Form validators
│   │   ├── currency_formatter.dart              # Amount formatting
│   │   ├── qr_classifier.dart                   # QR type detection
│   │   ├── date_formatter.dart                  # Date formatting
│   │   └── printer_helper.dart                  # ESC/POS thermal printer
│   ├── widgets/
│   │   ├── glass_card.dart                      # Glassmorphism card
│   │   ├── kk_button.dart                       # Primary button (gradient)
│   │   ├── kk_text_field.dart                   # Form input field
│   │   ├── loading_overlay.dart                 # Loading indicator
│   │   ├── error_widget.dart                    # Error display
│   │   └── shimmer_loader.dart                  # Loading skeleton
│   └── service_locator.dart                     # GetIt DI configuration
│
├── shared/
│   ├── constants/
│   │   ├── api_constants.dart                   # Backend API endpoints
│   │   └── app_constants.dart                   # App-wide constants
│   ├── models/                                  # Hive models
│   │   ├── product_model.dart                   # TypeId: 0
│   │   ├── transaction_model.dart               # TypeId: 1
│   │   ├── cart_item_model.dart                 # TypeId: 2
│   │   ├── coin_model.dart                      # TypeId: 3
│   │   ├── user_model.dart                      # TypeId: 4
│   │   └── payment_model.dart                   # TypeId: 5
│   ├── services/
│   │   ├── api_service.dart                     # Dio HTTP client
│   │   ├── coingecko_service.dart               # CoinGecko API
│   │   ├── razorpay_service.dart                # Razorpay integration
│   │   ├── walletconnect_service.dart           # WalletConnect v2
│   │   ├── hive_service.dart                    # Local storage
│   │   ├── connectivity_service.dart            # Network status
│   │   └── biometric_service.dart               # Biometric auth
│   └── widgets/
│       ├── bottom_nav_bar.dart                  # Global navigation
│       ├── crypto_mini_card.dart                # Asset card
│       ├── transaction_tile.dart                # Transaction item
│       └── coin_list_tile.dart                  # Market coin item
│
└── features/
    ├── splash/
    │   ├── bloc/splash_bloc.dart
    │   └── presentation/splash_screen.dart
    │
    ├── auth/
    │   ├── bloc/
    │   │   ├── auth_bloc.dart
    │   │   ├── auth_event.dart
    │   │   └── auth_state.dart
    │   ├── data/
    │   │   ├── models/user_response_model.dart
    │   │   └── repositories/auth_repo_impl.dart
    │   ├── domain/
    │   │   ├── entities/user.dart
    │   │   ├── repositories/auth_repo.dart
    │   │   └── usecases/
    │   │       ├── login_usecase.dart
    │   │       ├── register_usecase.dart
    │   │       └── logout_usecase.dart
    │   └── presentation/
    │       ├── pages/login_page.dart
    │       ├── pages/register_page.dart
    │       └── pages/kyc_page.dart
    │
    ├── billing/
    │   ├── bloc/
    │   │   ├── billing_bloc.dart
    │   │   ├── billing_event.dart
    │   │   └── billing_state.dart
    │   ├── data/
    │   │   └── models/cart_item_model.dart
    │   ├── domain/
    │   │   ├── entities/cart_item.dart
    │   │   └── usecases/
    │   │       ├── add_to_cart_usecase.dart
    │   │       ├── update_cart_usecase.dart
    │   │       └── fetch_product_usecase.dart
    │   └── presentation/
    │       ├── pages/home_page.dart
    │       ├── pages/cart_page.dart
    │       ├── pages/scanner_page.dart
    │       └── widgets/cart_item_tile.dart
    │
    ├── payments/
    │   ├── bloc/
    │   │   ├── payment_bloc.dart
    │   │   ├── payment_event.dart
    │   │   └── payment_state.dart
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── transaction_model.dart
    │   │   │   ├── payment_request_model.dart
    │   │   │   └── payment_response_model.dart
    │   │   ├── services/
    │   │   │   ├── upi_payment_service.dart
    │   │   │   ├── crypto_payment_service.dart
    │   │   │   ├── wallet_service.dart
    │   │   │   └── price_oracle_service.dart
    │   │   └── repositories/payment_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── payment_result.dart
    │   │   │   ├── payment_method.dart
    │   │   │   └── merchant.dart
    │   │   ├── repositories/payment_repository.dart
    │   │   └── usecases/
    │   │       ├── process_upi_payment.dart
    │   │       ├── process_crypto_payment.dart
    │   │       ├── verify_payment.dart
    │   │       └── get_crypto_price.dart
    │   └── presentation/
    │       ├── pages/
    │       │   ├── intelligent_qr_scan_page.dart
    │       │   └── unified_payment_page.dart
    │       ├── screens/
    │       │   ├── upi_checkout_screen.dart
    │       │   ├── crypto_checkout_screen.dart
    │       │   ├── receipt_screen.dart
    │       │   └── payment_confirmation_screen.dart
    │       └── widgets/payment_method_card.dart
    │
    ├── dashboard/
    │   ├── bloc/dashboard_bloc.dart
    │   ├── data/repositories/dashboard_repo_impl.dart
    │   ├── domain/usecases/get_portfolio.dart
    │   └── presentation/
    │       ├── pages/dashboard_page.dart
    │       └── widgets/
    │           ├── balance_card.dart
    │           ├── holdings_card.dart
    │           └── quick_actions.dart
    │
    ├── markets/
    │   ├── bloc/markets_bloc.dart
    │   ├── data/
    │   │   ├── models/coin_model.dart
    │   │   └── repositories/market_repo_impl.dart
    │   ├── domain/usecases/get_market_data.dart
    │   └── presentation/
    │       ├── pages/markets_page.dart
    │       └── widgets/coin_chart.dart
    │
    ├── transactions/
    │   ├── bloc/transaction_bloc.dart
    │   ├── data/repositories/transaction_repo_impl.dart
    │   ├── domain/usecases/get_transactions.dart
    │   └── presentation/
    │       ├── pages/transaction_history_page.dart
    │       └── widgets/transaction_filter.dart
    │
    ├── scanner/
    │   ├── bloc/scanner_bloc.dart
    │   ├── domain/usecases/classify_qr.dart
    │   └── presentation/scanner_overlay.dart
    │
    ├── shop/
    │   ├── bloc/shop_bloc.dart
    │   ├── domain/usecases/get_products.dart
    │   └── presentation/pages/shop_page.dart
    │
    ├── onboarding/
    │   ├── bloc/onboarding_bloc.dart
    │   └── presentation/onboarding_screen.dart
    │
    ├── profile/
    │   ├── bloc/profile_bloc.dart
    │   ├── domain/usecases/get_user_profile.dart
    │   └── presentation/pages/profile_page.dart
    │
    └── settings/
        ├── bloc/settings_bloc.dart
        └── presentation/pages/settings_page.dart
```

### **Backend (backend/) Structure**
```
backend/
├── server.js                          # Express app initialization
├── package.json                       # Dependencies & scripts
│
├── config/
│   ├── db.js                          # MongoDB connection
│   └── environment.js                 # Config management
│
├── middleware/
│   ├── auth.js                        # JWT verification
│   ├── errorHandler.js                # Global error handling
│   └── validator.js                   # Request validation
│
├── models/
│   ├── User.js                        # User schema (auth, KYC, balances)
│   ├── Product.js                     # Product schema (name, barcode, price)
│   ├── Cart.js                        # Shopping cart schema
│   ├── Transaction.js                 # Payment transaction records
│   ├── Settings.js                    # App configuration
│   └── Watchlist.js                   # Favorite products/coins
│
├── routes/
│   ├── auth.js                        # /api/auth
│   ├── user.js                        # /api/user
│   ├── products.js                    # /api/products
│   ├── cart.js                        # /api/cart
│   ├── payments.js                    # /api/payments
│   ├── transactions.js                # /api/transactions
│   ├── watchlist.js                   # /api/watchlist
│   ├── wallet.js                      # /api/wallet
│   └── settings.js                    # /api/settings
│
├── controllers/
│   ├── authController.js              # Auth logic
│   ├── productController.js           # Product operations
│   ├── paymentController.js           # Payment processing
│   └── userController.js              # User profile operations
│
└── utils/
    ├── razorpay.js                    # Razorpay integration
    ├── validators.js                  # Input validation
    └── logger.js                      # Request/error logging
```

---

## 🔗 **REST API Endpoints**

**Base URL:** `http://{backend-ip}:4000/api`

### **Authentication Routes** (`/api/auth`)
| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| POST | `/register` | `{ phone, password, name }` | `{ token, user }` | ❌ |
| POST | `/login` | `{ phone, password }` | `{ token, user }` | ❌ |
| POST | `/refresh` | `{ token }` | `{ newToken }` | ✅ |
| POST | `/logout` | - | `{ ok }` | ✅ |

### **User Management** (`/api/user`)
| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| GET | `/profile` | - | `{ user }` | ✅ |
| PUT | `/profile` | `{ name, avatarUrl, ... }` | `{ user }` | ✅ |
| POST | `/kyc` | `{ pan, aadhaar, dob, bankName, accountNumber, ifsc }` | `{ kycStatus }` | ✅ |
| GET | `/balance` | - | `{ upiBalance, cryptoBalanceInr }` | ✅ |
| PUT | `/kyc-update` | `{ kycStatus }` | `{ updated }` | ✅ |

### **Products** (`/api/products`)
| Method | Endpoint | Body | Query Params | Auth |
|--------|----------|------|--------------|------|
| GET | `/` | - | `?page=1&limit=20` | ✅ |
| POST | `/` | `{ name, description, price, barcode, category }` | - | ✅ |
| GET | `/:id` | - | - | ✅ |
| GET | `/barcode/:barcode` | - | - | ✅ |
| PUT | `/:id` | `{ name, price, ... }` | - | ✅ |
| DELETE | `/:id` | - | - | ✅ |

### **Shopping Cart** (`/api/cart`)
| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| GET | `/` | - | `{ items: [], total: 0 }` | ✅ |
| POST | `/add` | `{ productId, quantity }` | `{ cart }` | ✅ |
| PUT | `/update` | `{ productId, quantity }` | `{ cart }` | ✅ |
| DELETE | `/remove` | `{ productId }` | `{ cart }` | ✅ |
| DELETE | `/clear` | - | `{ cleared: true }` | ✅ |

### **Payments** (`/api/payments`)
| Method | Endpoint | Body | Purpose | Auth |
|--------|----------|------|---------|------|
| POST | `/create-order` | `{ amount, currency, items }` | Create Razorpay order | ✅ |
| POST | `/verify` | `{ payment_id, order_id, signature }` | Verify UPI payment | ✅ |
| GET | `/methods` | - | Available payment methods | ✅ |
| POST | `/crypto` | `{ amount, walletAddress, chainId }` | Process crypto tx | ✅ |

### **Transactions** (`/api/transactions`)
| Method | Endpoint | Query Params | Response | Auth |
|--------|----------|--------------|----------|------|
| GET | `/` | `?type=upi&page=1` | `{ transactions: [] }` | ✅ |
| GET | `/stats` | `?period=month` | `{ total, count, avgAmount }` | ✅ |
| GET | `/:id` | - | `{ transaction }` | ✅ |
| DELETE | `/:id` | - | `{ deleted: true }` | ✅ |

### **Wallet Management** (`/api/wallet`)
| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| GET | `/address` | - | `{ walletAddress }` | ✅ |
| POST | `/save` | `{ walletAddress }` | `{ saved: true }` | ✅ |
| GET | `/upi-mapping/:address` | - | `{ upiId, walletAddress }` | ✅ |

### **Watchlist** (`/api/watchlist`)
| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| GET | `/` | - | `{ items: [] }` | ✅ |
| POST | `/toggle` | `{ productId }` | `{ added: boolean }` | ✅ |

### **Settings** (`/api/settings`)
| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| GET | `/` | - | `{ settings }` | ✅ |
| PUT | `/` | `{ theme, notifications, ... }` | `{ updated: true }` | ✅ |

---

## 🔄 **Application Workflows**

### **1. User Registration & Onboarding**
```
Register (Phone/Password) 
  → Login (Get JWT) 
  → Fill KYC (PAN, Aadhaar, Bank)
  → kycStatus changes: pending → in_progress → verified
  → Dashboard Access
```

**Endpoints Used:**
1. `POST /api/auth/register` — Create account
2. `POST /api/auth/login` — Authenticate
3. `POST /api/user/kyc` — Submit KYC data
4. `GET /api/user/profile` — Verify status

---

### **2. Shop & Go (POS Workflow)**
```
Open Billing Home
  → Real-time Barcode Scanning
  → Auto Add to Cart
  → Adjust Quantities
  → Review Total
  → Proceed to Checkout
  → Select Payment Method
  → Complete Transaction
  → Print Receipt
```

**Endpoints Used:**
1. `GET /api/products/barcode/:barcode` — Lookup product
2. `POST /api/cart/add` — Add to cart
3. `PUT /api/cart/update` — Change quantity
4. `GET /api/cart` — Get cart total
5. `POST /api/payments/create-order` or `/crypto` — Process payment
6. `GET /api/transactions/:id` — Fetch transaction for receipt

---

### **3. UPI Payment (Razorpay)**
```
Checkout Page
  → Select "UPI Payment"
  → Enter Amount
  → Create Razorpay Order
  → Open Razorpay Modal
  → User Pays via UPI
  → Webhook Notification
  → Verify Payment
  → Record Transaction
  → Show Receipt
```

**Flow Details:**
- User enters/confirms amount
- App calls `POST /api/payments/create-order`
- Backend returns `orderId` from Razorpay
- Frontend initializes Razorpay SDK
- User completes payment in modal
- Razorpay sends webhook to backend
- Frontend calls `POST /api/payments/verify`
- Backend validates signature and records transaction
- Receipt screen displays success

---

### **4. Crypto Payment (WalletConnect)**
```
Checkout Page
  → Select "Crypto Payment"
  → Display Crypto Equivalent
  → Fetch Live Price (CoinGecko)
  → Show WalletConnect QR
  → User Scans with Wallet
  → Confirm in Wallet App
  → Blockchain Transaction
  → Verify On-Chain
  → Record Transaction
  → Show Confirmation
```

**Flow Details:**
- User selects crypto payment
- Fetch live ETH/MATIC prices from CoinGecko
- Calculate required token amount
- Display WalletConnect QR code
- User opens wallet app and scans
- Session established, user confirms tx
- Blockchain records transaction
- Backend polls or uses webhook to verify
- Record in `transactions` collection
- Show confirmation with tx hash

---

### **5. Product Management**
```
Admin Panel
  → Add New Product
  → Set Name, Price, Category
  → Auto-generate/Import Barcode
  → Save Locally (Hive)
  → Sync to Backend
  → Update All Devices
```

**Endpoints Used:**
1. `POST /api/products` — Create product
2. `Hive insert` — Store locally
3. `PUT /api/products/:id` — Update (if needed)

---

### **6. Transaction History & Analytics**
```
Dashboard / Transactions Page
  → Fetch Transactions (with filters)
  → Display Timeline
  → Show Statistics (daily/monthly)
  → Filter by Type/Date/Amount
  → Export as PDF/CSV
  → View Receipt & Print
```

**Endpoints Used:**
1. `GET /api/transactions?type=upi&date=2026-03` — Filtered list
2. `GET /api/transactions/stats?period=month` — Analytics
3. `GET /api/transactions/:id` — Transaction details

---

## 🚀 **Getting Started**

### **Prerequisites**
- Flutter 3.8+ SDK
- Node.js 18+ with npm
- MongoDB 6.0+ (local or Atlas)
- Android SDK (minSdk 24) or iOS 12+
- Razorpay merchant account
- WalletConnect project ID

### **Frontend Setup**

```bash
cd billing_fixed

# Install dependencies
flutter pub get

# Ensure minSdk is set to 24
# Edit: android/app/build.gradle.kts

# Run app
flutter run

# Or use provided script
./run_flutter.bat  # Windows
chmod +x run_flutter.sh && ./run_flutter.sh  # Linux/Mac
```

### **Backend Setup**

```bash
cd backend

# Install Node dependencies
npm install

# Create .env file
cat > .env << EOF
MONGODB_URI=mongodb://localhost:27017/kryptokart
PORT=4000
JWT_SECRET=your_jwt_secret_key
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_SECRET=your_razorpay_secret
WALLETCONNECT_PROJECT_ID=your_wc_project_id
COINGECKO_API_KEY=your_coingecko_key
CORS_ORIGIN=*
EOF

# Start server
npm start           # Production
npm run dev         # Development (auto-reload)

# Seed sample data
npm run seed
```

### **Configure Device Network**

Edit [lib/shared/constants/api_constants.dart](lib/shared/constants/api_constants.dart):

```dart
// For physical Android device (WiFi)
static const String backendBase = 'http://192.168.x.x:4000';

// For Android Emulator
static const String backendBase = 'http://10.0.2.2:4000';

// For iOS Simulator
static const String backendBase = 'http://localhost:4000';

// For physical iOS device
static const String backendBase = 'http://192.168.x.x:4000';

// For Web/Desktop
static const String backendBase = 'http://localhost:4000';
```

---

## 📦 **Dependencies Overview**

### **Key Frontend Dependencies**
```yaml
flutter_bloc: ^8.1.5           # State management
go_router: ^14.0.0              # Navigation
dio: ^5.4.0                      # HTTP client
hive: ^2.2.3                     # Local database
hive_flutter: ^1.1.0             # Hive for Flutter
razorpay_flutter: ^1.3.7         # UPI payments
walletconnect_flutter_v2: ^2.3.1 # Crypto payments
mobile_scanner: ^5.1.0           # Barcode scanning
fl_chart: ^0.68.0                # Data visualization
flutter_animate: ^4.5.0          # Animations
google_fonts: ^6.1.0             # Typography
cached_network_image: ^3.3.1     # Image caching
connectivity_plus: ^6.0.3        # Network status
image_picker: ^1.0.7             # Camera/gallery
local_auth: ^2.3.0               # Biometric auth
```

### **Key Backend Dependencies**
```json
{
  "express": "^4.19.2",
  "mongoose": "^8.2.0",
  "jsonwebtoken": "^9.0.2",
  "bcryptjs": "^2.4.3",
  "razorpay": "^2.9.4",
  "cors": "^2.8.5",
  "morgan": "^1.10.0",
  "dotenv": "^16.4.5",
  "validator": "^13.11.0"
}
```

---

## 🎨 **Design System**

### **Color Palette (Material 3 Dark)**
```dart
const Color kBackground   = Color(0xFF00040F);  // Deep navy
const Color kSurface      = Color(0xFF0D1117);  // Card bg
const Color kSurface2     = Color(0xFF161B22);  // Elevated
const Color kAccent       = Color(0xFF00F6FF);  // Cyan
const Color kAccentGlow   = Color(0x3300F6FF);  // Glow
const Color kGreen        = Color(0xFF00D26A);  // Success
const Color kRed          = Color(0xFFFF4B4B);  // Error
const Color kTextPrimary  = Color(0xFFFFFFFF);
const Color kTextSecondary= Color(0xFF8B98A5);
const Color kBorder       = Color(0xFF21262D);
```

### **Typography (Poppins)**
- **Display**: 28sp Bold
- **Title**: 20sp SemiBold
- **Body**: 14sp Regular
- **Caption**: 11sp Regular
- **Amount**: 36sp Bold

### **Component Specs**
- **Cards**: 20px border radius, glassmorphism
- **Buttons**: 16px border radius, cyan→blue gradient
- **Input**: 14px radius, outlined
- **FAB**: 64px circle, elevated 8px

---

## 🧪 **Testing**

```bash
# Unit & widget tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# Integration tests
flutter drive --target=integration_test/app_test.dart

# Backend tests
cd backend
npm test
```

---

## 📊 **MongoDB Schema**

### **Users Collection**
```javascript
{
  _id: ObjectId,
  name: String,
  phone: String (unique, 10 digits),
  password: String (hashed),
  upiId: String,
  walletAddress: String (ETH),
  kycStatus: 'pending' | 'in_progress' | 'verified',
  kycData: {
    pan: String,
    aadhaar: String,
    dob: Date,
    bankName: String,
    accountNumber: String,
    ifsc: String,
    accountHolderName: String
  },
  portfolioValue: Number,
  cryptoBalanceInr: Number,
  upiBalance: Number,
  avatarUrl: String,
  createdAt: Date,
  updatedAt: Date
}
```

### **Products Collection**
```javascript
{
  _id: ObjectId,
  name: String,
  description: String,
  price: Number,
  barcode: String (unique),
  category: String,
  inStock: Boolean,
  quantity: Number,
  imageUrl: String,
  createdAt: Date,
  updatedAt: Date
}
```

### **Transactions Collection**
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: Users),
  amount: Number,
  currency: 'INR' | 'ETH' | 'MATIC',
  type: 'upi' | 'crypto',
  paymentMethod: 'razorpay' | 'walletconnect',
  status: 'pending' | 'completed' | 'failed',
  razorpayOrderId: String,
  razorpayPaymentId: String,
  txHash: String (for crypto),
  items: [{
    productId: ObjectId,
    quantity: Number,
    price: Number
  }],
  receipt: String,
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🛠️ **Troubleshooting**

### **Build Error: minSdk >= 24**
```kotlin
// android/app/build.gradle.kts
android {
    compileSdk = 34
    defaultConfig {
        minSdk = 24  // ← Change from 21
    }
}
```

### **Port 4000 Already in Use**
```bash
npx kill-port 4000  # Windows
lsof -i :4000 | grep LISTEN | awk '{print $2}' | xargs kill -9  # Mac/Linux
```

### **MongoDB Connection Error**
```bash
# Start local MongoDB
mongod --dbpath ./data

# Or use MongoDB Atlas
# Update .env: MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/kryptokart
```

### **Flutter Cannot Connect to Backend**
- Check IP address: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
- Ensure devices are on same WiFi
- Verify firewall allows port 4000
- Check `api_constants.dart` for correct backend URL

---

## 📚 **Additional Documentation**

- [Razorpay Setup Guide](docs/razorpay_integration_setup.md)
- [WalletConnect Configuration](docs/walletconnect_setup.md)
- [API Reference](docs/api_reference.md)
- [Architecture Overview](docs/architecture.md)

---

## 📄 **License**

Proprietary - KryptoKart Inc. 2026

---

## 👥 **Support**

For issues, feature requests, or questions:
- 📧 Email: support@kryptokart.app
- 🐛 Report bugs in GitHub Issues
- 💬 Join our Discord community

---

**Last Updated:** March 28, 2026  
**Version:** 1.0.0  
**Status:** Production Ready ✅