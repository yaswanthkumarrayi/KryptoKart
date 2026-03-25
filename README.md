# KryptoKart - Universal Billing & Payment App

A Flutter-based point-of-sale and payment application that combines barcode-driven shopping with UPI and cryptocurrency payments. Scan any QR code -- product barcode, UPI payment, or ETH wallet -- and the app handles it internally without launching external apps.

## Features

- **Universal QR Scanner** -- Single scanner detects UPI QR, crypto wallets, and product barcodes
- **Shop & Go Mode** -- Live camera scanning adds products to cart in real time
- **UPI Payments** -- In-app payment via Razorpay SDK (no external app redirect)
- **Crypto Payments** -- ETH/MATIC via WalletConnect with live CoinGecko price oracle
- **Product Management** -- Full CRUD with barcode association, Hive-backed
- **Bluetooth Receipt Printing** -- ESC/POS thermal printer support
- **Transaction History** -- Persisted in Hive with receipt view and print
- **Dark Theme** -- Consistent Material 3 dark UI throughout

## Architecture

```
lib/
├── main.dart                          # App entry, Bloc providers, router
├── config/
│   └── routes/
│       └── app_routes.dart            # GoRouter route definitions
├── core/
│   ├── data/
│   │   └── hive_database.dart         # Hive init, box accessors
│   ├── error/
│   │   └── failure.dart               # Failure types (ServerFailure, NetworkFailure)
│   ├── theme/
│   │   └── app_theme.dart             # Dark/light theme, colors, typography
│   ├── usecase/
│   │   └── usecase.dart               # Generic UseCase<Type, Params> interface
│   ├── utils/
│   │   ├── app_validators.dart        # Form validators
│   │   └── printer_helper.dart        # ESC/POS Bluetooth printer wrapper
│   ├── widgets/
│   │   ├── input_label.dart           # Reusable form label
│   │   └── primary_button.dart        # Reusable bottom action button
│   └── service_locator.dart           # GetIt dependency injection setup
│
└── features/
    ├── billing/                       # POS / Shopping cart
    │   ├── domain/entities/
    │   │   └── cart_item.dart
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── billing_bloc.dart   # Cart management, barcode scan, print
    │       │   ├── billing_event.dart
    │       │   └── billing_state.dart
    │       └── pages/
    │           ├── home_page.dart      # Shop & Go scanner + cart panel
    │           ├── scanner_page.dart   # Standalone barcode scanner (returns value)
    │           └── checkout_page.dart  # Cart review, print receipt, pay
    │
    ├── payments/                       # Unified payment system
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── transaction_model.dart      # Hive model (typeId: 2)
    │   │   │   └── transaction_model.g.dart    # Generated adapter
    │   │   └── services/
    │   │       ├── upi_payment_service.dart     # Razorpay SDK integration
    │   │       ├── crypto_payment_service.dart  # WalletConnect + price oracle
    │   │       ├── wallet_service.dart          # WalletConnect v2 session mgmt
    │   │       └── price_oracle_service.dart    # CoinGecko ETH/MATIC prices
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── payment_result.dart  # PaymentResult value object
    │   │   │   └── merchant.dart        # Merchant entity
    │   │   └── usecases/
    │   │       ├── process_upi_payment.dart     # UPI use case
    │   │       ├── process_crypto_payment.dart  # Crypto use case
    │   │       └── get_live_crypto_price.dart   # Price fetch use case
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── payment_bloc.dart    # QR classification, payment processing
    │       │   ├── payment_event.dart
    │       │   └── payment_state.dart
    │       ├── pages/
    │       │   ├── intelligent_qr_scan_page.dart  # Universal QR scanner
    │       │   └── unified_payment_page.dart      # Payment screen (UPI + ETH)
    │       └── screens/
    │           ├── upi_checkout_screen.dart
    │           ├── crypto_checkout_screen.dart
    │           ├── receipt_screen.dart           # Post-payment receipt + print
    │           ├── payment_mode_picker_screen.dart
    │           └── home_screen.dart              # Payment hub / dashboard
    │
    ├── product/                        # Product catalog
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── product_model.dart           # Hive model (typeId: 0)
    │   │   │   └── product_model.g.dart
    │   │   └── repositories/
    │   │       └── product_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── product.dart         # Product entity (id, name, barcode, price)
    │   │   ├── repositories/
    │   │   │   └── product_repository.dart
    │   │   └── usecases/
    │   │       └── product_usecases.dart # CRUD + GetByBarcode
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── product_bloc.dart
    │       │   ├── product_event.dart
    │       │   └── product_state.dart
    │       └── pages/
    │           ├── product_list_page.dart
    │           ├── add_product_page.dart
    │           └── edit_product_page.dart
    │
    ├── shop/                           # Shop/store profile
    │   ├── data/models/
    │   │   ├── shop_model.dart          # Hive model (typeId: 1)
    │   │   └── shop_model.g.dart
    │   ├── data/repositories/
    │   │   └── shop_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/shop.dart
    │   │   ├── repositories/shop_repository.dart
    │   │   └── usecases/shop_usecases.dart
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── shop_bloc.dart
    │       │   ├── shop_event.dart
    │       │   └── shop_state.dart
    │       └── pages/
    │           └── shop_details_page.dart
    │
    ├── settings/                       # Bluetooth printer management
    │   ├── data/repositories/
    │   │   └── printer_repository_impl.dart
    │   ├── domain/repositories/
    │   │   └── printer_repository.dart
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── printer_bloc.dart
    │       │   ├── printer_event.dart
    │       │   └── printer_state.dart
    │       └── pages/
    │           └── settings_page.dart
    │
    ├── transactions/                   # Transaction history UI
    │   └── presentation/
    │       ├── pages/
    │       │   └── transaction_page.dart
    │       └── store/
    │           └── transaction_store.dart  # In-memory ValueNotifier store
    │
    ├── contacts/                       # UPI contacts list
    │   └── presentation/pages/
    │       └── contacts_page.dart
    │
    ├── dashboard/                      # Main hub
    │   └── presentation/pages/
    │       └── home_dashboard.dart
    │
    ├── store/                          # Store selection
    │   └── presentation/pages/
    │       └── store_selection_page.dart
    │
    └── upi/                            # Legacy UPI flow (kept for reference)
        └── presentation/
            ├── bloc/
            │   ├── upi_bloc.dart
            │   ├── upi_event.dart
            │   └── upi_state.dart
            └── pages/
                ├── scan_pay_page.dart
                ├── payment_page.dart
                └── success_page.dart
```

**Total: 78 Dart files across 10 feature modules.**

## Application Flow

```
┌─────────────────────────────────────────────────────────┐
│                    APP LAUNCH                            │
│  main.dart → HiveDatabase.init() → ServiceLocator.init()│
│  → MultiBlocProvider → GoRouter(initialLocation: '/')   │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│                 HOME DASHBOARD (/)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │ Scan &   │  │ Shopping │  │ Products │  │Settings│  │
│  │ Pay      │  │ Mode     │  │ Manage   │  │        │  │
│  │ /scan    │  │ /shopping│  │ /products│  │/settings│ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┘  │
└───────┼─────────────┼─────────────┼─────────────────────┘
        │             │             │
        ▼             ▼             ▼
   ┌─────────┐  ┌──────────┐  ┌──────────────┐
   │Universal│  │Shop & Go │  │Product CRUD  │
   │QR Scan  │  │Scanner + │  │List/Add/Edit │
   │         │  │Cart Panel│  │with Barcode  │
   └────┬────┘  └────┬─────┘  └──────────────┘
        │             │
        ▼             ▼
   ┌─────────────────────────────────────┐
   │         QR CLASSIFICATION           │
   │                                     │
   │  "upi://..."  → UPI Payment Flow   │
   │  "0x..."      → Crypto Payment Flow│
   │  other        → Add to Cart (POS)  │
   └──────────┬──────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │     UNIFIED PAYMENT PAGE            │
   │     /payment?type=...               │
   │                                     │
   │  ┌─────────────┐ ┌───────────────┐  │
   │  │ Receiver    │ │ Amount Input  │  │
   │  │ Details     │ │               │  │
   │  └─────────────┘ └───────────────┘  │
   │                                     │
   │  ┌──────────┐    ┌──────────────┐   │
   │  │Pay with  │    │Pay with ETH  │   │
   │  │UPI       │    │              │   │
   │  └────┬─────┘    └──────┬───────┘   │
   └───────┼─────────────────┼───────────┘
           │                 │
           ▼                 ▼
   ┌──────────────┐  ┌───────────────────┐
   │ PaymentBloc  │  │ PaymentBloc       │
   │ → Razorpay   │  │ → PriceOracle     │
   │   SDK        │  │ → WalletConnect   │
   │              │  │ → CryptoService   │
   └──────┬───────┘  └────────┬──────────┘
          │                   │
          ▼                   ▼
   ┌─────────────────────────────────────┐
   │         ON SUCCESS                  │
   │  1. Save TransactionModel → Hive   │
   │  2. Save KkTransaction → Store     │
   │  3. Navigate → /payment/receipt     │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │         RECEIPT SCREEN              │
   │  • Payment details & TX ID         │
   │  • Print via Bluetooth             │
   │  • Done → back to Dashboard        │
   └─────────────────────────────────────┘
```

## State Management

| Bloc / Store | Scope | Purpose |
|---|---|---|
| `BillingBloc` | Global | Shopping cart, barcode scan, receipt print |
| `PaymentBloc` | Global | QR classification, UPI/crypto payment processing |
| `ProductBloc` | Global | Product CRUD, search |
| `ShopBloc` | Global | Shop profile (name, address, footer) |
| `PrinterBloc` | Global | Bluetooth printer discovery and connection |
| `UpiBloc` | Global | UPI payee state (legacy, used by contacts page) |
| `TransactionStore` | Static | In-memory `ValueNotifier<List>` for transaction tab |

## Data Persistence (Hive)

| Box Name | Type | TypeId | Purpose |
|---|---|---|---|
| `products` | `Box<ProductModel>` | 0 | Product catalog |
| `shop` | `Box<ShopModel>` | 1 | Shop profile |
| `transactions` | `Box<TransactionModel>` | 2 | Payment history |
| `settings` | `Box` (dynamic) | -- | Printer MAC, preferences |

## Route Map

| Path | Page | Description |
|---|---|---|
| `/` | `HomeDashboard` | Main hub with navigation cards |
| `/scan` | `IntelligentQrScanPage` | Universal QR scanner |
| `/shopping` | `HomePage` | Shop & Go mode (camera + cart) |
| `/checkout` | `CheckoutPage` | Cart review and print |
| `/payment` | `UnifiedPaymentPage` | Payment with UPI/ETH buttons |
| `/payment/upi` | `UpiCheckoutScreen` | Direct UPI checkout |
| `/payment/crypto` | `CryptoCheckoutScreen` | Direct crypto checkout |
| `/payment/receipt` | `ReceiptScreen` | Post-payment receipt |
| `/payment/picker` | `PaymentModePickerScreen` | Payment method selection |
| `/products` | `ProductListPage` | Product catalog management |
| `/products/add` | `AddProductPage` | Add new product |
| `/products/edit/:id` | `EditProductPage` | Edit existing product |
| `/shop` | `ShopDetailsPage` | Edit shop profile |
| `/settings` | `SettingsPage` | Printer and app settings |
| `/store` | `StoreSelectionPage` | Store selection |
| `/scanner` | `ScannerPage` | Simple barcode scanner (returns value) |

## Dependencies

### Core
| Package | Purpose |
|---|---|
| `flutter_bloc` / `bloc` | State management |
| `get_it` | Dependency injection |
| `equatable` | Value equality for Bloc states/events |
| `fpdart` | `Either<Failure, T>` for error handling |
| `go_router` | Declarative routing |

### Storage
| Package | Purpose |
|---|---|
| `hive` / `hive_flutter` | Local NoSQL database |
| `flutter_secure_storage` | Encrypted storage for WalletConnect sessions |

### UI
| Package | Purpose |
|---|---|
| `google_fonts` | IBM Plex Sans typography |
| `vibration` | Haptic feedback on scan |
| `intl` | Date formatting |

### Hardware
| Package | Purpose |
|---|---|
| `mobile_scanner` | Camera-based QR/barcode scanning |
| `print_bluetooth_thermal` | ESC/POS Bluetooth thermal printer |
| `permission_handler` | Camera and Bluetooth permissions |

### Payments
| Package | Purpose |
|---|---|
| `razorpay_flutter` | UPI payment processing |
| `walletconnect_flutter_v2` | Crypto wallet connection (MetaMask, etc.) |
| `dio` | HTTP client for CoinGecko price API |

### Utilities
| Package | Purpose |
|---|---|
| `uuid` | Generate unique product IDs |
| `url_launcher` | Deep link to wallet apps |
| `app_settings` | Open device settings for permissions |
| `json_annotation` | Serialization annotations |

## Build & APK Size Optimization

The release build is optimized with:

1. **R8 minification** (`isMinifyEnabled = true`) -- Dead code elimination
2. **Resource shrinking** (`isShrinkResources = true`) -- Remove unused Android resources
3. **ProGuard rules** -- Keep Razorpay, WalletConnect, and Flutter classes
4. **ABI filtering** -- Only `armeabi-v7a` and `arm64-v8a` (drops x86/x86_64 emulator libs)
5. **Removed unused packages** -- `pretty_qr_code`, `web3dart` (direct), `http` (direct)

### Build Commands

```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# Release App Bundle (recommended for Play Store)
flutter build appbundle --release

# Split APK per ABI (smallest individual APKs)
flutter build apk --release --split-per-abi
```

> **Tip:** Use `--split-per-abi` for the smallest APK per device. The fat APK
> includes native libraries for both ARM architectures.

## Setup

1. **Clone and install dependencies:**
   ```bash
   git clone <repo-url>
   cd billing_fixed
   flutter pub get
   ```

2. **Configure Razorpay** (for UPI payments):
   Edit `lib/features/payments/data/services/upi_payment_service.dart`:
   ```dart
   'key': 'rzp_test_YOUR_KEY_HERE',  // Replace with your Razorpay key
   ```

3. **Configure WalletConnect** (for crypto payments):
   Edit `lib/features/payments/data/services/wallet_service.dart`:
   ```dart
   const _kProjectId = 'YOUR_WALLETCONNECT_PROJECT_ID';
   ```
   Get a project ID from [cloud.walletconnect.com](https://cloud.walletconnect.com/).

4. **Run the app:**
   ```bash
   flutter run
   ```

5. **Generate Hive adapters** (if models change):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## Minimum Requirements

- Flutter SDK: 3.8.1+
- Dart SDK: 3.8.1+
- Android: minSdk 21 (Android 5.0)
- iOS: 12.0+

## License

Private project. Not for redistribution.
