# KryptoKart Frontend - Complete Documentation

Comprehensive documentation for the Flutter mobile application.

---

## 📋 **Table of Contents**
1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Architecture](#architecture)
4. [Feature Documentation](#feature-documentation)
5. [UI/UX Design System](#uiux-design-system)
6. [State Management](#state-management)
7. [Local Storage](#local-storage)
8. [API Integration](#api-integration)
9. [Development Guide](#development-guide)

---

## 📖 **Overview**

KryptoKart is a full-featured fintech and POS application built with Flutter, providing a seamless experience for:
- **Merchants**: Point-of-sale system with inventory management
- **Users**: Unified payment experience (UPI + Crypto)
- **Trading**: Real-time market data and crypto holdings management

The app emphasizes **offline-first** architecture with local caching and sync capabilities.

---

## 🛠️ **Tech Stack**

### **UI/Framework**
```yaml
flutter: ^3.8.1
flutter_bloc: ^8.1.5        # State Management
go_router: ^14.0.0          # Navigation
material design 3            # UI System
```

### **Storage & Database**
```yaml
hive: ^2.2.3                # Local NoSQL database
hive_flutter: ^1.1.0        # Hive bindings
flutter_secure_storage: ^9.2.2  # Encrypted storage
shared_preferences: ^2.2.2  # Key-value storage
```

### **Networking**
```yaml
dio: ^5.4.0                 # HTTP client
connectivity_plus: ^6.0.3   # Network status
```

### **Payments**
```yaml
razorpay_flutter: ^1.3.7            # UPI payments
walletconnect_flutter_v2: ^2.3.1    # Crypto payments
```

### **Camera & Input**
```yaml
mobile_scanner: ^5.1.0      # Barcode scanning
image_picker: ^1.0.7        # Camera/gallery
permission_handler: ^11.3.1 # Runtime permissions
local_auth: ^2.3.0          # Biometric auth
```

### **UI Components**
```yaml
google_fonts: ^6.1.0        # Typography
flutter_animate: ^4.5.0     # Animations
cached_network_image: ^3.3.1    # Image loading
fl_chart: ^0.68.0           # Charts
shimmer: ^3.0.0             # Skeleton loaders
intl: ^0.19.0               # Internationalization
```

### **Utilities**
```yaml
get_it: ^7.6.7              # Service locator
equatable: ^2.0.5           # Equality comparison
uuid: ^4.5.2                # UUID generation
url_launcher: ^6.2.5        # Deep linking
vibration: ^2.0.0           # Haptic feedback
```

---

## 🏗️ **Architecture**

### **Clean Architecture Pattern**

```
feature/
├── presentation/        # UI Layer (BLoC, pages, widgets)
│   ├── bloc/           # State management
│   ├── pages/          # Full-screen pages
│   ├── screens/        # Page components
│   └── widgets/        # Reusable UI components
│
├── domain/             # Business Logic Layer
│   ├── entities/       # Core business objects
│   ├── repositories/   # Abstract contracts
│   └── usecases/       # Business logic rules
│
└── data/               # Data Access Layer
    ├── models/         # API/Hive DTOs
    ├── repositories/   # Implementations
    └── services/       # External APIs
```

### **Dependency Injection (GetIt)**

```dart
// Registers in core/service_locator.dart
sl<AuthBloc>()
sl<PaymentBloc>()
sl<ApiService>()
sl<HiveService>()
```

### **Router Configuration (GoRouter)**

```dart
// Routes defined in config/routes/app_routes.dart
'/': HomePage,
'/auth/login': LoginPage,
'/auth/register': RegisterPage,
'/billing': BillingPage,
'/payments/unified-scan': UnifiedPaymentPage,
'/dashboard': DashboardPage,
'/transactions': TransactionHistoryPage,
'/profile': ProfilePage,
'/settings': SettingsPage,
```

---

## ✨ **Feature Documentation**

### **1. Authentication Module** (`features/auth`)

#### **Responsibility**
- User registration and login
- JWT token management
- KYC verification workflow
- Session persistence

#### **Key Files**
```
auth/
├── bloc/
│   ├── auth_bloc.dart       # Auth event processor
│   ├── auth_event.dart      # Events: Login, Register, Logout, KYC, RefreshToken
│   └── auth_state.dart      # States: Initial, Loading, Authenticated, Unauthenticated, Error, KYCPending, KYCVerified
├── data/
│   ├── models/
│   │   ├── user_response_model.dart  # API response DTO
│   │   └── login_request_model.dart  # Request DTO
│   └── repositories/
│       └── auth_repository_impl.dart # HTTP calls to backend
├── domain/
│   ├── entities/
│   │   └── user.dart        # Core user entity
│   ├── repositories/
│   │   └── auth_repository.dart  # Abstract contract
│   └── usecases/
│       ├── login_usecase.dart        # UseCase pattern
│       ├── register_usecase.dart
│       ├── logout_usecase.dart
│       ├── kyc_submit_usecase.dart
│       └── check_auth_status_usecase.dart
└── presentation/
    └── pages/
        ├── login_page.dart          # Phone + password
        ├── register_page.dart       # Registration form
        ├── kyc_page.dart            # PAN, Aadhaar, bank details
        └── splash_screen.dart       # Check auth on app launch
```

#### **Workflows**
```
Registration Flow:
  Input Phone & Password
  → BlocEvent: AuthRegisterEvent
  → Bloc processes via RegisterUseCase
  → API: POST /api/auth/register
  → Save JWT token securely
  → Navigate to Dashboard

Login Flow:
  Input Phone & Password
  → BlocEvent: AuthLoginEvent
  → API: POST /api/auth/login
  → Save token + refresh token
  → Check KYC status
  → If kycStatus != 'verified': Show KYC page
  → Navigate to Dashboard

KYC Submission:
  Fill PAN, Aadhaar, bank details
  → BlocEvent: AuthKYCSubmitEvent
  → API: POST /api/user/kyc
  → kycStatus changes: pending → in_progress → verified
  → Unlock full app features
```

---

### **2. Billing/POS Module** (`features/billing`)

#### **Responsibility**
- Product scanning and cart management
- Real-time price calculation
- Checkout workflow
- Receipt generation and printing

#### **Key Files**
```
billing/
├── bloc/
│   ├── billing_bloc.dart        # Cart CRUD, barcode scan
│   ├── billing_event.dart       # Events: ScanBarcode, AddToCart, RemoveFromCart, UpdateQuantity, Checkout
│   └── billing_state.dart       # States: CartLoading, CartLoaded, ScannedProduct, CheckoutReady, Error
├── data/models/
│   ├── cart_item_model.dart     # Hive model
│   └── product_model.dart       # Product from API
├── domain/
│   ├── entities/
│   │   └── cart_item.dart       # Business entity
│   └── usecases/
│       ├── scan_barcode_usecase.dart
│       ├── add_to_cart_usecase.dart
│       ├── calculate_total_usecase.dart
│       └── checkout_usecase.dart
└── presentation/
    ├── pages/
    │   ├── home_page.dart           # Shop & Go interface
    │   ├── cart_page.dart           # Cart review
    │   └── scanner_page.dart        # Standalone QR scanner
    └── widgets/
        ├── live_scanner.dart        # Real-time camera feed
        ├── cart_item_tile.dart      # Cart item display
        ├── price_display.dart       # Total calculation
        └── cart_actions.dart        # Cart buttons
```

#### **Workflow: Shop & Go**
```
Enter Billing Home
  → Initialize live camera with mobile_scanner
  → Real-time barcode detection
  
User Scans Barcode
  → BlocEvent: BillingScannedBarcodeEvent
  → Lookup: Local Hive OR API GET /api/products/barcode/:barcode
  → If found: Auto-add to cart with quantity=1
  → Show toast confirmation
  → Auto-increment quantity if scanned again
  
Cart Total Auto-calculates
  → Sum all items × quantity × price
  → Apply taxes (if applicable)
  → Display running total

User Taps Checkout
  → BlocEvent: BillingCheckoutEvent
  → Aggregate cart items
  → Navigate to PaymentPage with cart data

Print Receipt (Optional)
  → After payment success
  → Call printer_helper.dart with ESC/POS commands
  → Thermal printer prints receipt

Clear Cart
  → Delete from Hive
  → Reset BLoC state
  → Ready for next transaction
```

#### **Barcode Scanning**
- Uses `mobile_scanner` package
- Supports UPC-A, EAN-13, QR codes
- Offline barcode storage in Hive
- Fuzzy search if exact match not found

---

### **3. Payments Module** (`features/payments`)

#### **Responsibility**
- Unified payment interface
- QR classification (barcode vs. UPI vs. wallet)
- UPI payment via Razorpay
- Crypto payment via WalletConnect
- Transaction recording

#### **Key Files**
```
payments/
├── bloc/
│   ├── payment_bloc.dart        # Payment orchestration
│   ├── payment_event.dart       # Events: ScanPaymentQR, ProcessUPI, ProcessCrypto, VerifyPayment
│   └── payment_state.dart       # States: QRScanned, PaymentProcessing, PaymentSuccess, PaymentFailed
├── data/
│   ├── models/
│   │   ├── transaction_model.dart       # Hive model
│   │   ├── payment_request_model.dart   # Request to API
│   │   └── payment_response_model.dart  # API response
│   ├── services/
│   │   ├── upi_payment_service.dart              # Razorpay wrapper
│   │   ├── crypto_payment_service.dart           # WalletConnect wrapper
│   │   ├── wallet_service.dart                   # WalletConnect session mgmt
│   │   ├── price_oracle_service.dart             # CoinGecko price API
│   │   └── payment_verification_service.dart     # Signature verification
│   └── repositories/
│       └── payment_repository_impl.dart  # Payment repository
├── domain/
│   ├── entities/
│   │   ├── payment_result.dart          # Payment outcome
│   │   ├── payment_method.dart          # UPI | Crypto enum
│   │   └── merchant.dart                # Merchant entity
│   └── usecases/
│       ├── process_upi_payment.dart
│       ├── process_crypto_payment.dart
│       ├── verify_payment.dart
│       ├── get_crypto_price.dart
│       └── classify_qr_usecase.dart
└── presentation/
    ├── pages/
    │   ├── intelligent_qr_scan_page.dart     # Universal QR scanner & classifier
    │   └── unified_payment_page.dart         # Payment method selection
    ├── screens/
    │   ├── upi_checkout_screen.dart
    │   ├── crypto_checkout_screen.dart
    │   ├── payment_confirmation_screen.dart
    │   ├── receipt_screen.dart
    │   ├── payment_failed_screen.dart
    │   └── payment_processing_screen.dart
    └── widgets/
        ├── payment_method_card.dart
        ├── amount_display.dart
        ├── price_conversion.dart        # INR ↔ Crypto
        └── payment_confirmation_dialog.dart
```

#### **Workflow: UPI Payment**
```
Checkout Page
  → Show amount breakdown (subtotal, tax, total)
  → User taps "Pay with UPI"
  → BlocEvent: PaymentProcessUPIEvent
  
Create Razorpay Order
  → Call API: POST /api/payments/create-order
  → Response: { orderId, amount, razorpayKey }
  → Initialize Razorpay SDK with order details
  
Razorpay Modal Shows
  → User selects UPI app
  → Enters UPI PIN
  → Payment processed
  
Payment Webhook
  → Razorpay sends webhook to backend
  → Backend records transaction
  → Frontend polls or waits for callback
  
Verification
  → Call API: POST /api/payments/verify
  → Send: payment_id, order_id, signature
  → Backend validates signature
  → Response: { success, transactionId }
  
Receipt Screen
  → Display transaction details
  → Show QR code for receipt
  → Allow print via Bluetooth printer
  
Save Transaction
  → Record in local Hive database
  → Sync to MongoDB (background sync)
```

#### **Workflow: Crypto Payment**
```
Checkout Page
  → User taps "Pay with Crypto"
  → Select: ETH or MATIC
  
Fetch Live Price
  → Call CoinGecko API
  → Get current ETH/MATIC → INR rate
  → Calculate required crypto amount
  → Display: "Approx. 0.25 ETH"
  
Show WalletConnect QR
  → Generate WalletConnect session
  → Display QR code for user to scan
  
User's Mobile Wallet
  → Scans QR with wallet app (MetaMask, etc.)
  → Session established via WalletConnect bridge
  → Shows transaction details in wallet
  → User confirms transaction
  
Blockchain Execution
  → Wallet sends tx to blockchain
  → Ethereum/Polygon records transaction
  → User gets tx hash (0x123...)
  
Backend Verification
  → Call blockchain RPC (Infura)
  → Parse transaction from tx hash
  → Verify amount, from, to addresses
  → Record in MongoDB transactions collection
  
Receipt & Confirmation
  → Show success screen with tx hash
  → Display blockchain explorer link
  → Allow copy hash / share
  
Local Storage
  → Hive stores transaction with tx hash
  → Sync to cloud when online
```

#### **QR Classification**
```dart
// In qr_classifier_usecase.dart
String classifyQR(String qrData) {
  if (isUPIFormat(qrData))        // upi://pay?pa=...
    return 'UPI';
  if (isProductBarcode(qrData))   // 13-digit EAN
    return 'PRODUCT';
  if (isWalletAddress(qrData))    // 0x... or wc:...
    return 'WALLET';
  if (isWalletConnectURI(qrData)) // wc:...
    return 'WALLETCONNECT';
  return 'UNKNOWN';
}
```

---

### **4. Dashboard Module** (`features/dashboard`)

#### **Responsibility**
- Portfolio overview
- Balance display (UPI + Crypto)
- Transaction summary
- Quick actions

#### **Key Features**
```
Dashboard Screen:
  ┌─────────────────┐
  │ Portfolio Value │  ← Total (UPI + Crypto in INR)
  │  ₹ 842,500      │
  ├─────────────────┤
  │ UPI Balance     │  ₹ 45,000
  │ Crypto Balance  │  ₹ 797,500
  ├─────────────────┤
  │ Holdings:       │
  │ • ETH 0.25      │  ≈ ₹597,500
  │ • MATIC 500     │  ≈ ₹200,000
  ├─────────────────┤
  │ Quick Actions:  │
  │ [Send] [Scan]   │
  │ [History]       │
  └─────────────────┘
```

#### **Data Sources**
```
CoinGecko API
  ↓
Fetch ETH/MATIC prices (every 30 seconds)
  ↓
Calculate portfolio value in INR
  ↓
BLoC updates UI
  ↓
Display with animations
```

---

### **5. Markets Module** (`features/markets`)

#### **Responsibility**
- Real-time crypto market data
- Price charts (ETH, MATIC)
- Market trends and indicators

#### **Features**
```
Markets Page:
  ┌──────────────┐
  │ ETH/INR      │
  │ ₹ 2,390,000  │
  │ ▲ +5.2%      │
  │ [24h Chart]  │
  ├──────────────┤
  │ MATIC/INR    │
  │ ₹ 400        │
  │ ▼ -2.1%      │
  │ [24h Chart]  │
  └──────────────┘
```

#### **Implementation**
- **fl_chart** for line/candlestick charts
- CoinGecko API for market data
- 30-second polling for real-time updates
- Local caching of price history

---

### **6. Transactions Module** (`features/transactions`)

#### **Responsibility**
- Transaction history with filtering
- Analytics and statistics
- Receipt viewing and printing

#### **Features**
```
Transactions Page:
  Filters:
  [All] [UPI] [Crypto] [Date Range]
  
  Transaction List:
  2026-03-28 | ₹199,998 | ✅ Completed | UPI
  2026-03-27 | 0.1 ETH | ✅ Completed | Crypto
  2026-03-25 | ₹50,000 | ✅ Completed | UPI
  
  Stats:
  Daily: ₹250k | Weekly: ₹1.2M | Monthly: ₹5.8M
```

#### **Filtering Logic**
```dart
List<Transaction> filtered = transactions
  .where((t) => t.date.isAfter(startDate))
  .where((t) => t.date.isBefore(endDate))
  .where((t) => t.type == selectedType)
  .where((t) => t.status == 'completed')
  .toList();
```

---

### **7. Scanner Module** (`features/scanner`)

#### **Responsibility**
- Unified QR/barcode scanning
- QR classification
- Barcode-to-product lookup

#### **Features**
```
Scanner Modes:
  1. Product Barcode  → Auto-add to cart
  2. UPI QR           → Payment flow
  3. Wallet Address   → Crypto payment
  4. WalletConnect    → Crypto session
```

---

### **8. Profile Module** (`features/profile`)

#### **Responsibility**
- User profile management
- KYC status display
- Account settings
- Wallet address management

#### **Features**
```
Profile Page:
  [Avatar Image]
  Name: John Doe
  Phone: +91-9876543210
  Email: john@example.com
  
  KYC Status: ✅ Verified
  
  Payment Methods:
  UPI ID: john@okhbank
  Wallet: 0x742d...
  
  [Edit Profile] [Update KYC]
```

---

### **9. Settings Module** (`features/settings`)

#### **Responsibility**
- App preferences
- Security settings
- Notifications
- About & Help

#### **Features**
```
Settings Page:
  [Appearance]
    Dark Mode: ON
    Font Size: Normal
  
  [Security]
    Biometric Lock: ON
    Auto-logout: 15 min
  
  [Notifications]
    Transactions: ON
    Promotions: OFF
  
  [About]
    Version: 1.0.0
    Support: support@kryptokart.app
```

---

## 🎨 **UI/UX Design System**

### **Color Palette**
```dart
// Dark Theme (Material 3)
const Color kBackground    = Color(0xFF00040F);  // Deep navy
const Color kSurface       = Color(0xFF0D1117);  // Card BG
const Color kSurfaceElevated = Color(0xFF161B22);
const Color kAccent        = Color(0xFF00F6FF);  // Cyan
const Color kAccentGlow    = Color(0x3300F6FF);  // Glow
const Color kGreen         = Color(0xFF00D26A);  // Success
const Color kRed           = Color(0xFFFF4B4B);  // Error
const Color kGrey          = Color(0xFF8B98A5);  // Text secondary
const Color kBorder        = Color(0xFF21262D);  // Dividers
```

### **Typography (Poppins)**
```dart
// Display
TextStyle displayLarge = GoogleFonts.poppins(
  fontSize: 28,
  fontWeight: FontWeight.bold,  // 700
);

// Title
TextStyle titleLarge = GoogleFonts.poppins(
  fontSize: 20,
  fontWeight: FontWeight.w600,  // SemiBold
);

// Body
TextStyle bodyMedium = GoogleFonts.poppins(
  fontSize: 14,
  fontWeight: FontWeight.w400,  // Regular
);

// Caption
TextStyle labelSmall = GoogleFonts.poppins(
  fontSize: 11,
  fontWeight: FontWeight.w400,
);

// Amount / Numbers
TextStyle amountLarge = GoogleFonts.poppins(
  fontSize: 36,
  fontWeight: FontWeight.bold,
  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
);
```

### **Components**

#### **Glass Card (Glassmorphism)**
```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFF0D1117).withOpacity(0.85),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Color(0xFF21262D), width: 1),
    boxShadow: [
      BoxShadow(
        color: Color(0x1A00F6FF),  // Cyan glow
        blurRadius: 20,
        spreadRadius: 0,
      ),
    ],
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: child,
  ),
);
```

#### **Primary Button (CTA)**
```dart
Container(
  height: 56,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF00F6FF), Color(0xFF0080FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Center(
        child: Text(
          'Confirm Payment',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00040F),  // Dark text on bright button
          ),
        ),
      ),
    ),
  ),
);
```

#### **Input Field**
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Enter amount',
    filled: true,
    fillColor: Color(0xFF161B22),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Color(0xFF21262D), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Color(0xFF00F6FF), width: 2),
    ),
    hintStyle: TextStyle(color: Color(0xFF8B98A5)),
  ),
);
```

#### **Bottom Navigation**
```
┌── Dark Background (#0D1117) ──┐
│ [Home] [Markets] [⊙ Scan] ... │
│                   ▲            │
│             Center FAB         │
│             64px circle        │
│             Gradient           │
│             Elevated +8dp      │
└──────────────────────────────┘
```

---

## 🔄 **State Management with BLoC**

### **BLoC Pattern Structure**
```dart
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(PaymentInitial()) {
    // Event handlers
    on<PaymentProcessUPIEvent>(_onProcessUPI);
    on<PaymentProcessCryptoEvent>(_onProcessCrypto);
    on<PaymentVerifyEvent>(_onVerifyPayment);
  }

  Future<void> _onProcessUPI(
    PaymentProcessUPIEvent event,
    Emitter<PaymentState> emit,
  ) async {
    // 1. Emit loading state
    emit(PaymentProcessing());

    try {
      // 2. Execute business logic
      final result = await paymentUseCase(amount: event.amount);

      // 3. Emit success state
      emit(PaymentSuccess(transactionId: result.id));
    } catch (e) {
      // 4. Emit error state
      emit(PaymentError(message: e.toString()));
    }
  }
}
```

### **Event-Driven Architecture**
```
User Action
  ↓
BLoC Event (e.g., BillingScannedBarcodeEvent)
  ↓
BLoC Event Handler
  ↓
UseCase (business logic)
  ↓
Repository (data access)
  ↓
API / Local Database
  ↓
Result
  ↓
BLoC State (e.g., CartLoaded)
  ↓
UI Rebuild (via BlocBuilder)
```

---

## 💾 **Local Storage (Hive)**

### **Hive Models with TypeIds**
```dart
// TypeId mapping (CRITICAL: Don't reuse!)
Product       → TypeId: 0
Transaction   → TypeId: 1
CartItem      → TypeId: 2
CoinModel     → TypeId: 3
UserModel     → TypeId: 4
PaymentModel  → TypeId: 5

// In main.dart initialization
initializeHive() async {
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  // ...
}
```

### **Offline-First Sync**
```
User Action (online)
  ↓
Write to Local Hive
  ↓
Write to API
  ↓
Mark as synced

User Action (offline)
  ↓
Write to Local Hive
  ↓
Queue for sync
  ↓
When online:
  ↓
Sync queued items
  ↓
Mark as synced
```

### **Usage Example**
```dart
// Save transaction locally
final box = Hive.box<TransactionModel>('transactions');
await box.add(TransactionModel(
  id: transaction.id,
  amount: transaction.amount,
  timestamp: DateTime.now(),
));

// Fetch offline
final transactions = box.values.toList();
```

---

## 🌐 **API Integration**

### **Dio HTTP Client Configuration**
```dart
// In shared/services/api_service.dart
class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.backendBase,
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = GetIt.I<SecureStorageService>().getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired → refresh
            _refreshToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<T> get<T>(String path) async {
    final response = await _dio.get(path);
    return response.data as T;
  }

  Future<T> post<T>(String path, {required Map<String, dynamic> data}) async {
    final response = await _dio.post(path, data: data);
    return response.data as T;
  }
}
```

### **Error Handling**
```dart
// Custom failure types
class ServerFailure extends Failure {
  final String message;
  ServerFailure(this.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(): super('No internet connection');
}

class CacheFailure extends Failure {
  CacheFailure(): super('Local cache error');
}
```

---

## 🚀 **Development Guide**

### **Project Setup**
```bash
# 1. Clone repository
git clone https://github.com/kryptokart/billing_fixed.git
cd billing_fixed

# 2. Install Flutter dependencies
flutter pub get

# 3. Generate Hive adapters
flutter pub run build_runner build

# 4. Update backend URL
# Edit: lib/shared/constants/api_constants.dart
static const String backendBase = 'http://192.168.x.x:4000';

# 5. Run app
flutter run
```

### **Code Generation**
```bash
# Hive adapters
flutter pub run build_runner build

# Freezed models
flutter pub run build_runner build

# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build
```

### **Common Development Tasks**

#### **Adding a New Feature**
```bash
# 1. Create feature directory structure
mkdir -p lib/features/my_feature/{presentation,domain,data}

# 2. Create BLoC files
touch lib/features/my_feature/presentation/bloc/my_feature_bloc.dart
touch lib/features/my_feature/presentation/bloc/my_feature_event.dart
touch lib/features/my_feature/presentation/bloc/my_feature_state.dart

# 3. Create data models
touch lib/features/my_feature/data/models/my_model.dart

# 4. Create domain entities
touch lib/features/my_feature/domain/entities/my_entity.dart

# 5. Create repository (abstract + impl)
# ... and so on
```

#### **Adding a New API Endpoint**
```dart
// 1. Add to ApiConstants
static const String myEndpoint = '$backendBase/api/my/endpoint';

// 2. Create repository method
Future<MyData> fetchMyData() async {
  final response = await _apiService.get<Map>(ApiConstants.myEndpoint);
  return MyModel.fromJson(response).toEntity();
}

// 3. Create usecase
class MyUseCase implements UseCase<MyEntity, NoParams> {
  @override
  Future<Either<Failure, MyEntity>> call(NoParams params) async {
    try {
      return Right(await repository.fetchMyData());
    } catch (e) {
      return Left(ServerFailure('$e'));
    }
  }
}

// 4. Integrate with BLoC
```

#### **Debugging**
```bash
# View logs
flutter logs

# Hot reload
r

# Hot restart
R

# Stop app
q

# Device list
flutter devices

# Run on specific device
flutter run -d <device_id>
```

---

## 📊 **Performance Optimization**

### **Image Caching**
```dart
// Use cached_network_image
CachedNetworkImage(
  imageUrl: productImageUrl,
  placeholder: (context, url) => ShimmerLoader(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  cacheManager: CacheManager.instance,
);
```

### **List Optimization**
```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: transactions.length,
  itemBuilder: (context, index) {
    return TransactionTile(transactions[index]);
  },
);
```

### **Lazy Loading**
```dart
// Pagination for API calls
Future<List<Product>> getProducts(int page, int limit) async {
  return await api.get(
    '/products?page=$page&limit=$limit'
  );
}
```

---

## 🧪 **Testing**

### **Unit Tests**
```dart
test('Cart total calculation', () {
  final cart = CartItem(quantity: 2, price: 50000);
  expect(cart.total, equals(100000));
});
```

### **Widget Tests**
```dart
testWidgets('Login button shows loading', (WidgetTester tester) async {
  await tester.pumpWidget(LoginPage());
  await tester.tap(find.byType(PrimaryButton));
  expect(find.byType(CircularProgressIndicator), findsWidgets);
});
```

### **Integration Tests**
```dart
// Full app flow testing
test E2E: User registration → KYC → Product scan → Payment → Receipt
```

---

## 📚 **Additional Resources**

- [Flutter Documentation](https://flutter.dev)
- [BLoC Library](https://bloclibrary.dev)
- [Hive Database](https://docs.hivedb.dev)
- [Razorpay Docs](https://razorpay.com/docs)
- [WalletConnect](https://docs.walletconnect.com)

---

**Last Updated:** March 28, 2026  
**Status:** Production Ready ✅