# Billing Fixed - POS Billing App

A Flutter-based Point of Sale (POS) billing application designed for small retail shops. Features barcode scanning, cart management, UPI QR code payment, and Bluetooth thermal receipt printing — all powered by local Hive storage with no internet required.

---

## Table of Contents

- [Features](#features)
- [Screenshots & Screens](#screenshots--screens)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Data Flow](#data-flow)
- [Screens in Detail](#screens-in-detail)
- [Data Models](#data-models)
- [State Management (BLoC)](#state-management-bloc)
- [Routing](#routing)
- [Dependency Injection](#dependency-injection)
- [Database (Hive)](#database-hive)
- [Thermal Printing](#thermal-printing)
- [Getting Started](#getting-started)
- [Build & Run](#build--run)

---

## Features

- **Barcode Scanning POS** — Scan product barcodes with the device camera to instantly add items to the cart
- **Cart Management** — Increase/decrease quantity, remove items, view running totals
- **Product Catalog (CRUD)** — Add, edit, delete, and search products with barcode support
- **Shop Profile** — Configure shop name, address, phone, UPI ID, and receipt footer text
- **UPI QR Code Payment** — Auto-generates a UPI QR code on the checkout screen for the order total
- **Bluetooth Thermal Printing** — Print formatted receipts on any ESC/POS compatible Bluetooth thermal printer
- **Offline-First** — All data stored locally via Hive; no internet or backend server needed
- **Clean Architecture** — Feature-first modular design with domain/data/presentation layers

---

## Screenshots & Screens

The app has **8 screens** organized across 4 feature modules:

| Screen | Route | Description |
|--------|-------|-------------|
| **Home (POS Scanner)** | `/` | Main billing screen with live camera scanner and cart overlay |
| **Barcode Scanner** | `/scanner` | Standalone single-scan screen (used for product add/search) |
| **Checkout** | `/checkout` | Order summary table, UPI QR code, and print receipt button |
| **Product List** | `/products` | Searchable product catalog with edit/delete actions |
| **Add Product** | `/products/add` | Form to add a new product (barcode, name, price) |
| **Edit Product** | `/products/edit/:id` | Edit an existing product's name and price |
| **Shop Details** | `/shop` | Form to view and update shop profile information |
| **Settings** | `/settings` | Hub for shop profile, product catalog, and printer management |

---

## Architecture

The project follows **Clean Architecture** with a **feature-first** folder organization:

```
Feature/
├── domain/          (Business logic - pure Dart, no Flutter dependencies)
│   ├── entities/    (Core business objects)
│   ├── repositories/(Abstract repository contracts)
│   └── usecases/   (Application-specific business rules)
├── data/            (Data layer - implements domain contracts)
│   ├── models/      (Hive-annotated data models extending entities)
│   └── repositories/(Concrete repository implementations)
└── presentation/    (UI layer)
    ├── bloc/        (BLoC state management)
    └── pages/       (Flutter widgets / screens)
```

**Key principles:**
- Domain layer has zero dependencies on data or presentation
- Data layer implements domain repository interfaces using Hive
- Presentation layer uses BLoC pattern to manage UI state
- Dependency inversion via GetIt service locator
- Functional error handling with `fpdart` (`Either<Failure, Result>`)

---

## Project Structure

```
lib/
├── main.dart                              # App entry point, BLoC providers
├── config/
│   └── routes/
│       └── app_routes.dart                # GoRouter route definitions
├── core/
│   ├── service_locator.dart               # GetIt dependency injection setup
│   ├── data/
│   │   └── hive_database.dart             # Hive initialization & box access
│   ├── error/
│   │   └── failure.dart                   # Failure classes for Either returns
│   ├── theme/
│   │   └── app_theme.dart                 # Material theme with Google Fonts
│   ├── usecase/
│   │   └── usecase.dart                   # Generic UseCase<Result, Params> base
│   ├── utils/
│   │   ├── app_validators.dart            # Form field validators
│   │   └── printer_helper.dart            # Bluetooth printer ESC/POS helper
│   └── widgets/
│       ├── input_label.dart               # Reusable labeled text field
│       └── primary_button.dart            # Reusable styled action button
│
└── features/
    ├── billing/
    │   ├── domain/entities/
    │   │   └── cart_item.dart             # CartItem (Product + quantity)
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── billing_bloc.dart       # Cart operations & receipt printing
    │       │   ├── billing_event.dart
    │       │   └── billing_state.dart
    │       └── pages/
    │           ├── home_page.dart          # Main POS screen with scanner
    │           ├── scanner_page.dart       # Standalone barcode scanner
    │           └── checkout_page.dart      # Order summary & payment
    │
    ├── product/
    │   ├── domain/
    │   │   ├── entities/product.dart       # Product entity
    │   │   ├── repositories/product_repository.dart
    │   │   └── usecases/product_usecases.dart
    │   ├── data/
    │   │   ├── models/product_model.dart   # Hive model (typeId: 0)
    │   │   ├── models/product_model.g.dart # Generated adapter
    │   │   └── repositories/product_repository_impl.dart
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── product_bloc.dart       # Product CRUD operations
    │       │   ├── product_event.dart
    │       │   └── product_state.dart
    │       └── pages/
    │           ├── product_list_page.dart  # Catalog with search
    │           ├── add_product_page.dart   # New product form
    │           └── edit_product_page.dart  # Edit product form
    │
    ├── shop/
    │   ├── domain/
    │   │   ├── entities/shop.dart          # Shop entity
    │   │   ├── repositories/shop_repository.dart
    │   │   └── usecases/shop_usecases.dart
    │   ├── data/
    │   │   ├── models/shop_model.dart      # Hive model (typeId: 1)
    │   │   ├── models/shop_model.g.dart    # Generated adapter
    │   │   └── repositories/shop_repository_impl.dart
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── shop_bloc.dart          # Load/update shop profile
    │       │   ├── shop_event.dart
    │       │   └── shop_state.dart
    │       └── pages/
    │           └── shop_details_page.dart  # Shop profile form
    │
    └── settings/
        ├── domain/repositories/
        │   └── printer_repository.dart
        ├── data/repositories/
        │   └── printer_repository_impl.dart
        └── presentation/
            ├── bloc/
            │   ├── printer_bloc.dart       # Printer scan/connect/disconnect
            │   ├── printer_event.dart
            │   └── printer_state.dart
            └── pages/
                └── settings_page.dart      # Settings hub
```

---

## Tech Stack

| Category | Package | Purpose |
|----------|---------|---------|
| **State Management** | `flutter_bloc` / `bloc` | BLoC pattern for all features |
| **Dependency Injection** | `get_it` | Service locator for repos, use cases, blocs |
| **Navigation** | `go_router` | Declarative routing with nested routes |
| **Database** | `hive` / `hive_flutter` | Local NoSQL storage (products, shop, settings) |
| **Code Generation** | `hive_generator` / `build_runner` | Hive type adapters |
| **Functional Programming** | `fpdart` | `Either<Failure, Result>` for error handling |
| **Barcode Scanning** | `mobile_scanner` | Camera-based barcode/QR scanning |
| **QR Code** | `pretty_qr_code` | UPI payment QR code generation |
| **Thermal Printing** | `print_bluetooth_thermal` | Bluetooth ESC/POS printer communication |
| **UI** | `google_fonts` | Typography (Poppins font family) |
| **Utilities** | `uuid`, `intl`, `vibration`, `equatable` | ID generation, date formatting, haptic feedback, value equality |
| **Permissions** | `permission_handler` | Bluetooth & camera runtime permissions |
| **System** | `app_settings` | Open device Bluetooth settings |

---

## Data Flow

### Billing Flow (Main Use Case)

```
Camera Scanner (HomePage)
    │
    ▼
ScanBarcodeEvent ──► BillingBloc
    │
    ▼
GetProductByBarcodeUseCase ──► ProductRepository ──► Hive (products box)
    │
    ▼
Product found? ──► AddProductToCartEvent ──► Cart updated in BillingState
    │
    ▼
"Review Order" button ──► CheckoutPage
    │
    ├──► UPI QR Code displayed (from ShopBloc → shop.upiId + total)
    │
    └──► PrintReceiptEvent ──► PrinterHelper
              │
              ├── Auto-reconnect using saved printer MAC (Hive settings box)
              └── ESC/POS formatted receipt → Bluetooth thermal printer
```

### Product Management Flow

```
ProductListPage ──► ProductBloc (LoadProducts) ──► GetAllProductsUseCase
    │                                                      │
    │                                                      ▼
    │                                              ProductRepository
    │                                                      │
    │                                                      ▼
    │                                                 Hive (products box)
    │
    ├── Add ──► AddProductPage ──► AddProduct event ──► AddProductUseCase
    ├── Edit ──► EditProductPage ──► UpdateProduct event ──► UpdateProductUseCase
    └── Delete ──► DeleteProduct event ──► DeleteProductUseCase
```

### Shop Profile Flow

```
ShopDetailsPage ──► ShopBloc (LoadShopEvent) ──► GetShopUseCase
    │                                                   │
    │                                                   ▼
    │                                            ShopRepository
    │                                                   │
    │                                                   ▼
    │                                            Hive (shop box)
    │                                   (returns defaults if empty)
    │
    └── Save ──► UpdateShopEvent ──► UpdateShopUseCase ──► Hive
```

---

## Screens in Detail

### 1. Home Page (POS Scanner) — `/`

The primary billing interface. The top portion (~40%) is a live camera feed using `MobileScanner`. When a barcode is detected:
- A 2-second cooldown prevents duplicate scans
- Device vibrates for haptic feedback
- The barcode is looked up in the product database
- If found, the product is added to the in-memory cart

The bottom portion shows the cart as a scrollable list with:
- Product name, price, and quantity controls (+/-)
- Running total at the bottom
- "Review Order" button navigates to checkout

The app bar provides quick access to settings, torch toggle, and camera flip.

### 2. Scanner Page — `/scanner`

A standalone barcode scanner used by the product management screens. Scans a single barcode and returns the result via `context.pop(barcode)`. Uses `DetectionSpeed.noDuplicates` to avoid multiple reads.

### 3. Checkout Page — `/checkout`

Displays:
- Itemized order table (name, qty, price, total per item)
- Grand total
- UPI QR code (if shop has a UPI ID configured) encoding `upi://pay?pa=<upiId>&pn=<shopName>&am=<total>`
- "Print Receipt" button that sends a formatted receipt to the connected Bluetooth printer
- Back navigation clears the cart and returns to home

### 4. Product List Page — `/products`

A searchable catalog of all products stored in Hive. Features:
- Real-time search filtering by product name
- Scan button to find a product by barcode
- Tap to edit, long-press or icon to delete (with confirmation dialog)
- FAB to add a new product

### 5. Add Product Page — `/products/add`

Form with fields for:
- **Barcode** — manual entry or scan via camera (navigates to `/scanner`)
- **Product Name** — required text field
- **Price** — validated as a positive number
- Checks for duplicate barcodes before saving
- Generates a UUID for the product ID

### 6. Edit Product Page — `/products/edit/:id`

Pre-populated form showing the selected product. Barcode is read-only. Allows editing name and price.

### 7. Shop Details Page — `/shop`

Form to manage the shop profile used in receipt headers and UPI QR codes:
- Shop Name
- Address Line 1 & 2
- Phone Number
- UPI ID
- Receipt Footer Text

Loads existing data (or hardcoded defaults) on init. Saves to Hive on submit.

### 8. Settings Page — `/settings`

Central hub with:
- Shop profile summary header (name, address, phone from `ShopBloc`)
- Navigation links to Product Catalog and Shop Details
- Printer management section:
  - Connected printer name and status
  - Refresh button (scans bonded Bluetooth devices, auto-connects)
  - Open Bluetooth settings shortcut
- Printer auto-connect attempts each bonded device until one responds

---

## Data Models

### Product

| Field | Type | Hive Field | Description |
|-------|------|------------|-------------|
| `id` | `String` | 0 | UUID, unique identifier |
| `name` | `String` | 1 | Product display name |
| `barcode` | `String` | 2 | Scannable barcode value |
| `price` | `double` | 3 | Unit price |
| `stock` | `int` | 4 | Stock count (default 0, reserved for future use) |

**Hive TypeId:** `0`

### Shop

| Field | Type | Hive Field | Description |
|-------|------|------------|-------------|
| `name` | `String` | 0 | Shop/business name |
| `addressLine1` | `String` | 1 | Primary address |
| `addressLine2` | `String` | 2 | Secondary address (city, state) |
| `phoneNumber` | `String` | 3 | Contact phone |
| `upiId` | `String` | 4 | UPI payment ID for QR generation |
| `footerText` | `String` | 5 | Custom receipt footer message |

**Hive TypeId:** `1`

### CartItem (In-Memory Only)

| Field | Type | Description |
|-------|------|-------------|
| `product` | `Product` | Reference to the scanned product |
| `quantity` | `int` | Number of units in cart |
| `total` | `double` | Computed: `product.price * quantity` |

---

## State Management (BLoC)

### BillingBloc

Manages the in-memory shopping cart. Not persisted across app restarts.

| Event | Description |
|-------|-------------|
| `ScanBarcodeEvent(barcode)` | Looks up product by barcode, adds to cart if found |
| `AddProductToCartEvent(product)` | Adds a product or increments quantity |
| `RemoveProductFromCartEvent(product)` | Decrements quantity or removes if qty = 1 |
| `ClearCartEvent` | Empties the entire cart |
| `PrintReceiptEvent(shopName, address, phone, footer)` | Formats and sends receipt to Bluetooth printer |

| State | Description |
|-------|-------------|
| `BillingInitial` | Empty cart |
| `BillingLoaded(items, total)` | Cart with items and computed grand total |
| `BillingError(message)` | Error state (product not found, print failure) |

### ProductBloc

Manages CRUD operations for the product catalog.

| Event | Description |
|-------|-------------|
| `LoadProducts` | Fetches all products from Hive |
| `AddProduct(product)` | Saves a new product |
| `UpdateProduct(product)` | Updates an existing product |
| `DeleteProduct(id)` | Removes a product by ID |

| State | Description |
|-------|-------------|
| `ProductInitial` | Not loaded |
| `ProductLoading` | Fetching data |
| `ProductLoaded(products)` | List of all products |
| `ProductError(message)` | Error state |

### ShopBloc

Manages the single shop profile record.

| Event | Description |
|-------|-------------|
| `LoadShopEvent` | Loads shop from Hive (or defaults) |
| `UpdateShopEvent(shop)` | Saves updated shop profile |

| State | Description |
|-------|-------------|
| `ShopInitial` | Not loaded |
| `ShopLoading` | Fetching data |
| `ShopLoaded(shop)` | Shop profile loaded |
| `ShopError(message)` | Error state |

### PrinterBloc

Manages Bluetooth thermal printer connectivity.

| Event | Description |
|-------|-------------|
| `InitPrinterEvent` | Initialize printer subsystem |
| `RefreshPrinterEvent` | Scan bonded devices, auto-connect |
| `ScanPrintersEvent` | List available Bluetooth devices |
| `ConnectPrinterEvent(mac, name)` | Connect to a specific printer |
| `DisconnectPrinterEvent` | Disconnect current printer |
| `TestPrintEvent` | Send a test print |

| State | Description |
|-------|-------------|
| `PrinterInitial` | Not initialized |
| `PrinterConnecting` | Connection in progress |
| `PrinterConnected(name)` | Successfully connected |
| `PrinterDisconnected` | No printer connected |
| `PrinterError(message)` | Error state |

---

## Routing

Defined in `lib/config/routes/app_routes.dart` using `go_router`:

```
/                       → HomePage (POS Scanner + Cart)
├── /scanner            → ScannerPage (standalone barcode scan)
└── /checkout           → CheckoutPage (order summary + payment)

/settings               → SettingsPage (hub)

/products               → ProductListPage (catalog)
├── /products/add       → AddProductPage
└── /products/edit/:id  → EditProductPage

/shop                   → ShopDetailsPage (profile form)
```

---

## Dependency Injection

Configured in `lib/core/service_locator.dart` using `get_it`:

```
Repositories (Lazy Singletons):
  ProductRepository → ProductRepositoryImpl
  ShopRepository    → ShopRepositoryImpl
  PrinterRepository → PrinterRepositoryImpl

Use Cases (Lazy Singletons):
  GetAllProductsUseCase
  AddProductUseCase
  UpdateProductUseCase
  DeleteProductUseCase
  GetProductByBarcodeUseCase
  GetShopUseCase
  UpdateShopUseCase

BLoCs (Factories — new instance each time):
  ProductBloc
  ShopBloc
  PrinterBloc

Note: BillingBloc is created directly in main.dart, not via GetIt.
```

---

## Database (Hive)

All data is stored locally using Hive NoSQL boxes:

| Box Name | Type | Key Strategy | Contents |
|----------|------|-------------|----------|
| `products` | `Box<ProductModel>` | Product UUID as key | All products in the catalog |
| `shop` | `Box<ShopModel>` | Fixed key `shop_details` | Single shop profile record |
| `settings` | `Box` (dynamic) | String keys | `printer_mac`, `printer_name` |

Initialization happens in `HiveDatabase.init()` called from `main()` before the app starts:
1. `Hive.initFlutter()` — sets up Hive with the app's documents directory
2. Registers `ProductModelAdapter` and `ShopModelAdapter`
3. Opens all three boxes

---

## Thermal Printing

Receipt printing uses `PrinterHelper` — a singleton utility that communicates with Bluetooth ESC/POS thermal printers via `print_bluetooth_thermal`.

### Receipt Format

```
================================
        SHOP NAME
   Address Line 1
   Address Line 2
   Phone: 1234567890
================================
Date: 24/03/2026    Time: 14:30
--------------------------------
Item         Qty  Price   Total
--------------------------------
Product A      2  10.00   20.00
Product B      1  25.00   25.00
--------------------------------
GRAND TOTAL:            ₹45.00
================================
      Footer Text Here
    Thank You! Visit Again!
================================
```

### Printer Workflow

1. **Settings Page** → Refresh scans bonded Bluetooth devices and auto-connects
2. Connected printer's MAC address and name are saved to Hive `settings` box
3. During checkout → Print dispatches `PrintReceiptEvent`
4. `BillingBloc` reads saved MAC from Hive, reconnects if needed, then sends ESC/POS commands
5. Manual ESC/POS byte sequences handle text alignment, bold, and paper cutting

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.8.1`
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code with Flutter extensions
- An Android device/emulator (for barcode scanning and Bluetooth)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd billing_fixed

# Install dependencies
flutter pub get

# Generate Hive adapters (if .g.dart files are missing)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

---

## Build & Run

```bash
# Debug mode
flutter run

# Release APK
flutter build apk --release

# Release App Bundle
flutter build appbundle --release
```

### Permissions Required

- **Camera** — for barcode scanning
- **Bluetooth** — for thermal printer connectivity
- **Bluetooth Connect/Scan** — for discovering and pairing printers (Android 12+)

---

## License

This project is private and not published to pub.dev.
