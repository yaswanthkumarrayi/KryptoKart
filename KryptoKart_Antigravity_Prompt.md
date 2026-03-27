# KryptoKart — Antigravity Master Prompt
## Production-Level Flutter Fintech + POS Application

---

## 🎯 PROJECT OVERVIEW

Build **KryptoKart** — a production-ready unified fintech + POS Flutter mobile application.

**Core Philosophy:** `Scan anything → Pay anything → Track everything`

This is a real-world app combining **PhonePe + Binance + POS system** in a single platform. Every screen must be pixel-perfect, real-time, and fully connected.

---

## 🛠️ TECH STACK (MANDATORY — DO NOT DEVIATE)

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Material 3, Dark Theme) |
| State Management | flutter_bloc ^8.x |
| Local DB | hive + hive_flutter |
| HTTP Client | dio ^5.x |
| Navigation | go_router ^13.x |
| Payments (UPI) | razorpay_flutter |
| Crypto Payments | walletconnect_flutter_v2 |
| Crypto Prices | CoinGecko REST API (free tier) |
| Charts | fl_chart ^0.68.x |
| QR Scanner | mobile_scanner ^5.x |
| Fonts | google_fonts (Poppins) |
| Animations | flutter_animate ^4.x |
| Service Locator | get_it ^7.x |
| Env Config | flutter_dotenv |
| Image Cache | cached_network_image |
| Connectivity | connectivity_plus |

---

## 🎨 DESIGN SYSTEM (STRICT — PIXEL-PERFECT)

```dart
// COLORS
const Color kBackground   = Color(0xFF00040F);  // Deep navy black
const Color kSurface      = Color(0xFF0D1117);  // Card background
const Color kSurface2     = Color(0xFF161B22);  // Elevated surface
const Color kAccent       = Color(0xFF00F6FF);  // Cyan accent
const Color kAccentGlow   = Color(0x3300F6FF);  // Accent glow overlay
const Color kGreen        = Color(0xFF00D26A);  // Profit / success
const Color kRed          = Color(0xFFFF4B4B);  // Loss / error
const Color kTextPrimary  = Color(0xFFFFFFFF);
const Color kTextSecondary= Color(0xFF8B98A5);
const Color kBorder       = Color(0xFF21262D);

// TYPOGRAPHY (Poppins)
// Display: Poppins 28sp Bold
// Title: Poppins 20sp SemiBold
// Body: Poppins 14sp Regular
// Caption: Poppins 11sp Regular
// Numbers (amounts): Poppins 36sp Bold

// SHAPE
// Card border radius: 20px
// Button border radius: 16px
// Input border radius: 14px
// Chip border radius: 50px (pill)

// GLASSMORPHISM CARD
BoxDecoration glassmorphism = BoxDecoration(
  color: Color(0xFF0D1117).withOpacity(0.85),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: Color(0xFF21262D), width: 1),
  boxShadow: [
    BoxShadow(color: Color(0x1A00F6FF), blurRadius: 20, spreadRadius: 0),
  ],
);

// ACCENT BUTTON
// Background: Linear gradient #00F6FF → #0080FF
// Height: 56px, BorderRadius: 16px
// Text: Poppins 16sp SemiBold, Color: #00040F (dark)

// BOTTOM NAV
// Background: #0D1117 with top border #21262D
// Active icon: #00F6FF with glow
// Inactive icon: #8B98A5
// Center FAB (Scan): 64px circle, gradient #00F6FF → #0080FF, elevated 8px
```

---

## 📁 PROJECT STRUCTURE (MANDATORY — EXACTLY AS DEFINED)

```
lib/
├── main.dart
├── config/
│   └── routes/
│       └── app_routes.dart
├── core/
│   ├── data/
│   │   ├── hive_boxes.dart
│   │   └── local_storage.dart
│   ├── error/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   ├── qr_classifier.dart
│   │   ├── date_formatter.dart
│   │   └── validators.dart
│   ├── widgets/
│   │   ├── glass_card.dart
│   │   ├── kk_button.dart
│   │   ├── kk_text_field.dart
│   │   ├── loading_overlay.dart
│   │   ├── error_widget.dart
│   │   └── shimmer_loader.dart
│   └── service_locator.dart
├── shared/
│   ├── models/
│   │   ├── transaction_model.dart
│   │   ├── coin_model.dart
│   │   ├── product_model.dart
│   │   ├── cart_item_model.dart
│   │   └── user_model.dart
│   ├── services/
│   │   ├── coingecko_service.dart
│   │   ├── razorpay_service.dart
│   │   ├── walletconnect_service.dart
│   │   ├── hive_service.dart
│   │   └── connectivity_service.dart
│   ├── widgets/
│   │   ├── bottom_nav_bar.dart
│   │   ├── crypto_mini_card.dart
│   │   ├── transaction_tile.dart
│   │   └── coin_list_tile.dart
│   └── constants/
│       ├── api_constants.dart
│       └── app_constants.dart
└── features/
    ├── splash/
    │   ├── bloc/splash_bloc.dart
    │   └── presentation/splash_screen.dart
    ├── auth/
    │   ├── bloc/auth_bloc.dart
    │   ├── bloc/auth_event.dart
    │   ├── bloc/auth_state.dart
    │   └── presentation/
    │       ├── login_screen.dart
    │       └── register_screen.dart
    ├── onboarding/
    │   └── presentation/kyc_screen.dart
    ├── dashboard/
    │   ├── bloc/dashboard_bloc.dart
    │   ├── bloc/dashboard_event.dart
    │   ├── bloc/dashboard_state.dart
    │   └── presentation/
    │       ├── dashboard_screen.dart
    │       └── widgets/
    │           ├── portfolio_card.dart
    │           ├── quick_actions_row.dart
    │           ├── analytics_chart.dart
    │           └── top_assets_list.dart
    ├── scanner/
    │   ├── bloc/scanner_bloc.dart
    │   └── presentation/scanner_screen.dart
    ├── payments/
    │   ├── bloc/payment_bloc.dart
    │   ├── bloc/payment_event.dart
    │   ├── bloc/payment_state.dart
    │   └── presentation/
    │       ├── payment_screen.dart
    │       └── receipt_screen.dart
    ├── markets/
    │   ├── bloc/markets_bloc.dart
    │   ├── bloc/markets_event.dart
    │   ├── bloc/markets_state.dart
    │   └── presentation/
    │       ├── markets_screen.dart
    │       ├── coin_detail_screen.dart
    │       └── widgets/
    │           ├── featured_asset_card.dart
    │           ├── market_volume_card.dart
    │           ├── portfolio_banner.dart
    │           ├── market_filter_tabs.dart
    │           └── coin_row_tile.dart
    ├── shop/
    │   ├── bloc/shop_bloc.dart
    │   └── presentation/
    │       ├── shop_screen.dart
    │       └── cart_screen.dart
    ├── billing/
    │   └── presentation/checkout_screen.dart
    ├── transactions/
    │   ├── bloc/transactions_bloc.dart
    │   └── presentation/
    │       ├── transactions_screen.dart
    │       └── transaction_detail_screen.dart
    ├── profile/
    │   └── presentation/profile_screen.dart
    └── settings/
        └── presentation/settings_screen.dart
```

---

## 🌐 COINGECKO API INTEGRATION (REAL-TIME DATA)

### API Constants (`lib/shared/constants/api_constants.dart`)
```dart
class ApiConstants {
  static const String coinGeckoBase = 'https://api.coingecko.com/api/v3';

  // Markets list (BTC, ETH, SOL, BNB, XRP)
  // GET /coins/markets
  // Params: vs_currency=usd, order=market_cap_desc, per_page=10, page=1, sparkline=true, price_change_percentage=24h
  static String marketsEndpoint({String currency = 'usd'}) =>
      '$coinGeckoBase/coins/markets?vs_currency=$currency&order=market_cap_desc&per_page=10&page=1&sparkline=true&price_change_percentage=24h';

  // Price chart for a specific coin (7-day history)
  // GET /coins/{id}/market_chart
  // Params: vs_currency=usd, days=7
  static String marketChartEndpoint(String coinId, {int days = 7}) =>
      '$coinGeckoBase/coins/$coinId/market_chart?vs_currency=usd&days=$days';

  // Simple price for live conversion (INR + USD)
  // GET /simple/price
  // Params: ids=ethereum,bitcoin,solana, vs_currencies=inr,usd
  static String simplePriceEndpoint(List<String> coinIds) =>
      '$coinGeckoBase/simple/price?ids=${coinIds.join(',')}&vs_currencies=inr,usd&include_24hr_change=true';
}
```

### CoinGecko Service (`lib/shared/services/coingecko_service.dart`)
```dart
// Implement these methods using Dio:

// 1. fetchMarkets() → List<CoinModel>
//    Fetches BTC, ETH, SOL, BNB, XRP with: image, name, symbol,
//    current_price, price_change_percentage_24h, market_cap, sparkline_in_7d.price

// 2. fetchMarketChart(String coinId, {int days = 7}) → List<FlSpot>
//    Returns chart data as FlSpot list for fl_chart
//    Timestamps from prices[i][0] (ms), values from prices[i][1]
//    Format timestamps using DateFormat('HH:mm', 'en_US') for x-axis labels

// 3. fetchSimplePrice(List<String> coinIds) → Map<String, dynamic>
//    Used for live INR conversion in payment screen
//    Updates every 30 seconds using Timer.periodic

// 4. convertInrToCrypto(double inrAmount, String coinId) → double
//    Uses current inr price from simplePriceEndpoint
//    Returns crypto equivalent with 6 decimal places

// Error handling: Dio interceptors for timeout (10s), retry (2x), 429 rate limit backoff
// Cache: responses cached in Hive for 60s to avoid rate limiting
```

---

## 🗺️ NAVIGATION — GoRouter (`lib/config/routes/app_routes.dart`)

```dart
// Routes:
// /              → SplashScreen
// /login         → LoginScreen
// /register      → RegisterScreen
// /kyc           → KycScreen
// /home          → Shell (BottomNav) → DashboardScreen
// /home/scan     → Shell → ScannerScreen (FAB center)
// /home/markets  → Shell → MarketsScreen
// /home/activity → Shell → TransactionsScreen
// /home/profile  → Shell → ProfileScreen
// /payment       → PaymentScreen (extra: {recipientName, recipientUpi, recipientWallet, amount})
// /receipt       → ReceiptScreen (extra: TransactionModel)
// /coin/:id      → CoinDetailScreen (param: coinId)
// /shop          → ShopScreen
// /cart          → CartScreen
// /checkout      → CheckoutScreen
// /transaction/:id → TransactionDetailScreen
// /settings      → SettingsScreen

// Shell route wraps the 5 bottom nav tabs
// GoRouter uses ShellRoute for persistent bottom nav
// Deep link support: /coin/bitcoin, /transaction/TXN123
// Redirect logic: unauthenticated → /login, first launch → /kyc
```

---

## 📱 SCREEN SPECIFICATIONS (ALL 16 SCREENS)

---

### 1. SPLASH SCREEN (`/`)

**UI:**
- Full screen background: `#00040F`
- Center: KryptoKart logo (shield icon with heart, cyan gradient `#00F6FF → #0080FF`, 120px)
- App name: "KryptoKart" in Poppins Bold 32sp, white
- Tagline: "Scan. Pay. Track." in Poppins 14sp, `#8B98A5`
- Bottom: animated progress indicator (cyan color)
- Animated pulsing glow behind logo (scale 1.0 → 1.15, repeat)

**Logic:**
- Duration: 2.5s
- Check Hive for auth token
- If token exists → `/home`, else → `/login`
- Preload: CoinGecko simple prices, Hive boxes initialization

---

### 2. LOGIN SCREEN (`/login`)

**UI:**
- Background: `#00040F`
- Logo + "KryptoKart" header (centered)
- Subtitle: "Your unified fintech ecosystem"
- Glass card container with:
  - Phone Number field (with `+91` country code prefix dropdown)
  - Password field (with show/hide toggle)
- "Forgot PIN?" link (right-aligned, cyan)
- Primary CTA: "Login" button (full-width gradient)
- Divider: "OR"
- Secondary: "Create Account" outlined button
- Bottom: biometric icon if device supports it

**Bloc Events:** `LoginWithPhonePassword`, `LoginWithBiometric`
**Bloc States:** `LoginInitial`, `LoginLoading`, `LoginSuccess`, `LoginFailure(message)`
**On Success:** navigate to `/home`

---

### 3. REGISTER SCREEN (`/register`)

**UI (matches screenshot exactly):**
- Back arrow `←` + "Create Account" header
- Shield heart icon (80px) in dark rounded square card
- Title: "Join the Revolution" (Poppins Bold 28sp, white)
- Subtitle: "Secure your digital assets with KryptoKart's next-gen ecosystem."
- Form fields (glass-style inputs):
  - FULL NAME → "Enter your full name"
  - PHONE NUMBER → Country code `+91` dropdown + mobile input
  - UPI ID → "example@upi"
- Glass card: "Connect Wallet" with "OPTIONAL" pill badge
  - 3 wallet icons row: MetaMask, WalletConnect, Phantom (circular dark buttons, 48px each)
  - "Connect Crypto Wallet" outlined button (cyan border, wallet icon)
- Checkbox: "I agree to the Terms of Service and Privacy Policy"
- Primary CTA: "Create My Account" (full-width gradient, 56px height)
- Bottom: "Already have an account? Login" (cyan link)

**Bloc Events:** `RegisterSubmitted(name, phone, upiId)`, `ConnectWallet(type)`
**Validation:** All fields required except wallet, phone 10 digits, UPI format validation

---

### 4. KYC SCREEN (`/kyc`)

**UI:**
- Step indicator (3 steps): Personal → Bank → Verify
- Step 1 (Personal): Name, DOB, PAN number, Aadhaar number
- Step 2 (Bank): Bank name, Account number, IFSC, Account holder name
- Step 3 (Verify): Upload Aadhaar front/back, selfie
- Each step: glass card, labeled inputs, "Next" button
- Progress bar (cyan fill)
- Skip button (top-right, text only)

---

### 5. DASHBOARD SCREEN (`/home`)

**UI (matches screenshot exactly):**

**AppBar:**
- Left: circular avatar (user photo) + "KryptoKart" in Poppins Bold 20sp cyan
- Right: bell icon (notification badge if unread)

**Portfolio Card (Glass, full width, rounded 20px):**
- Label: "TOTAL PORTFOLIO VALUE" (caption, `#8B98A5`)
- Amount: "₹8,42,500" (Poppins Bold 36sp, white)
- Change badge: "+12.4%" (green pill with `↑`)
- Subtitle: "🛡 Assets secured in cold storage" (small, secondary)
- Background: subtle teal blob/gradient overlay (top-right)

**Quick Actions Row (3 equal cards):**
- SCAN: cyan QR icon on dark rounded square
- SEND: arrow icon
- SHOP: bag icon
- Each: label below in caption size

**Live Market Rates Section:**
- Header: "Live Market Rates" + "LIVE UPDATES" badge (cyan, pulsing dot)
- 2 horizontal cards (glass):
  - BTC/INR: ₹54.23L | BTC symbol icon | "+2.45%" green
  - ETH/INR: ₹3.42L | ETH symbol icon | "-0.82%" red
- Cards update every 30s from CoinGecko simple/price endpoint

**Portfolio Analytics Card:**
- Header: "Portfolio Analytics" + "MONTHLY" chip (toggle: weekly/monthly)
- Subtitle: "Past 30 days growth"
- `fl_chart` LineChart:
  - Line color: `#00F6FF`, gradient fill below
  - No grid lines, curved bezier line
  - Smooth animation on load
- Stats row: PROFIT ₹45,200 (cyan) | HIGH ₹8,90,000 | LOW ₹7,12,000

**Top Assets Section:**
- Header: "Top Assets" + "VIEW ALL →" (cyan link)
- List tiles (glass cards):
  - Bitcoin: BTC icon | "Bitcoin" | "BTC" | ₹54,23,102 | "+2.45%" green
  - Ethereum: ETH icon | "Ethereum" | "ETH" | ₹3,42,890 | "-0.82%" red

**Bloc:**
- `DashboardBloc` listens to: portfolio value, live prices, analytics data
- `DashboardEvent.LoadDashboard` on init
- `DashboardEvent.RefreshPrices` every 30s (Timer.periodic)
- `DashboardState`: loading → loaded(portfolio, prices, chart data) / error

---

### 6. SCANNER SCREEN (`/home/scan`)

**UI:**
- Full-screen camera preview (mobile_scanner)
- Semi-transparent dark overlay with:
  - Animated scanning frame (cyan corners, 260x260px)
  - Corners animate: scale pulse + glow
  - Horizontal scan line animating top → bottom (cyan, glowing)
- Top bar (semi-transparent): back arrow + "Scan QR / Barcode"
- Below frame:
  - 3 mode chips: "UPI Pay" | "Crypto" | "Product"
  - Auto-detected chip highlights in cyan when QR scanned
- Bottom panel (glass card slides up):
  - "Torch 🔦" toggle
  - "Upload QR 📷" from gallery
  - Status: "Point camera at QR code"

**QR Classification Logic (`lib/core/utils/qr_classifier.dart`):**
```dart
enum QrType { upi, cryptoWallet, productBarcode, unknown }

QrType classify(String rawValue) {
  if (rawValue.startsWith('upi://'))         return QrType.upi;
  if (rawValue.startsWith('0x') && rawValue.length == 42) return QrType.cryptoWallet;
  if (rawValue.startsWith('ethereum:'))      return QrType.cryptoWallet;
  if (RegExp(r'^[0-9]{8,14}$').hasMatch(rawValue)) return QrType.productBarcode;
  return QrType.unknown;
}

// On detection:
// QrType.upi → navigate to /payment with upiString parsed
//   (extract pa=, pn=, am= from UPI string)
// QrType.cryptoWallet → navigate to /payment with walletAddress
// QrType.productBarcode → navigate to /shop, add product to cart
```

---

### 7. PAYMENT SCREEN (`/payment`)

**UI (matches screenshot exactly):**

**AppBar:** back arrow + "Send Payment"

**Recipient Card (glass):**
- Circular avatar (48px) with green verified checkmark badge
- Name: "Alex Miller" (Poppins SemiBold 18sp)
- Subtitle: "alexm.eth • upi: alex@kryptokart" (`#8B98A5`)

**Payment Method Toggle:**
- Pill-style toggle: "Crypto" (active, cyan fill) | "UPI" (inactive, dark)
- Animated slide transition between modes

**Amount Display (center):**
- Rupee symbol "₹" (secondary) + large amount (Poppins Bold 48sp, white)
- Number pad input or keyboard
- Conversion row: "↕ 0.052 ETH • 450.2 MATIC" (`#8B98A5`, small)
- Updates LIVE as user types using CoinGecko simple/price INR rate

**Asset + Balance Row (2 columns, glass card):**
- Left: "₿ ASSET" label | "+2.4%" green badge | "Ethereum" Bold | "₹2,42,102.50" secondary
- Right: "💳 BALANCE" label | "0.842 ETH" Bold | "Available" secondary

**Pay Now Button:**
- Full-width gradient (cyan → blue), "Pay Now →" SemiBold 18sp dark text
- On tap: UPI mode → Razorpay SDK, Crypto mode → WalletConnect transaction

**Security Badge:**
- Glass card bottom: "🛡 END-TO-END ENCRYPTED SECURE TRANSFER" (small caps, secondary)

**Live Conversion Logic:**
```dart
// On amount change:
// 1. Fetch INR price from simplePriceEndpoint (cached 30s)
// 2. ETH equivalent = amountInr / ethInrPrice
// 3. Display formatted to 6 decimal places
// 4. Update conversion row in real-time
```

**Bloc:**
- `PaymentBloc` events: `InitPayment`, `ChangeMethod`, `UpdateAmount`, `SubmitPayment`
- `PaymentState`: `idle → processing → success(txnId) → failure(error)`
- On success: save TransactionModel to Hive → navigate to `/receipt`

---

### 8. RECEIPT SCREEN (`/receipt`)

**UI:**
- Full screen background `#00040F`
- Center: animated checkmark circle (cyan, scale in + bounce)
- "Payment Successful!" (Bold 24sp, white)
- Amount large: "₹12,500" (Bold 36sp, cyan)
- Glass receipt card:
  - Transaction ID: TXN-XXXX-XXXX (monospace)
  - Recipient: Alex Miller
  - Method: Crypto (ETH) / UPI
  - Date & Time: 27 Mar 2026, 14:32 IST
  - Network fee: 0.0001 ETH (if crypto)
- Action buttons row:
  - "Share Receipt" (outlined)
  - "Print" (outlined, Bluetooth print)
  - "Done" (filled gradient)
- Confetti animation on appear (optional: flutter_confetti)

---

### 9. MARKETS SCREEN (`/home/markets`)

**UI (matches screenshot exactly):**

**AppBar:** avatar + "KryptoKart" + bell icon

**Search Bar:**
- Full width, white/light glass, "Search markets..." placeholder
- Rounded pill (50px radius)
- On type: filter coins list in real-time

**Featured Asset Card (glass, dark gradient):**
- Top row: "FEATURED ASSET" label (caption cyan) + "$64,281.90" (Bold 24sp white)
- "Bitcoin" (Bold 28sp white) + "BTC / USD" (secondary)
- Green pill: "↑ +4.2%"
- `fl_chart` LineChart (7-day history):
  - Line: `#00F6FF`, gradient fill
  - X-axis: "08:00 AM | 12:00 PM | 04:00 PM | 08:00 PM | CURRENT"
  - No grid lines, smooth bezier
  - Chart data from: `GET /coins/bitcoin/market_chart?vs_currency=usd&days=7`
  - Timestamps formatted: `DateFormat('hh:mm a')`

**Market Volume Card (glass):**
- "Market Volume" label
- "$32.4B" Bold 22sp
- Full-width progress bar (cyan fill, 85% width)

**Portfolio Banner (cyan gradient, rounded 16px):**
- Left: "PORTFOLIO" caption + "$12,450.00" Bold 20sp
- Right: "→" arrow icon
- Tap → navigate to dashboard

**Market Overview Section:**
- Header: "Market Overview" + filter tabs: "All | DeFi | Layer 1"
- Active tab: underline cyan, tap to filter coins list

**Coin Row Tiles (List, real-time data):**
For each coin (BTC, ETH, SOL, BNB, XRP):
- Coin logo (32px circle, cached_network_image)
- Symbol Bold + Name secondary (left)
- Price Bold + 24h change% (colored) (right)
- Star icon (watchlist toggle, yellow if watchlisted)

**Real-Time Data:**
- Fetch on init: `GET /coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=true`
- Refresh every 60 seconds (Timer.periodic in Bloc)
- Show shimmer loading tiles on first load
- CoinModel fields used: `image, name, symbol, current_price, price_change_percentage_24h, market_cap, sparkline_in_7d`

**Bloc:**
- `MarketsBloc` events: `LoadMarkets`, `RefreshMarkets`, `SearchCoins(query)`, `ToggleWatchlist(coinId)`, `FilterMarkets(filter)`
- Watchlist IDs stored in Hive box `'watchlist'`

---

### 10. COIN DETAIL SCREEN (`/coin/:id`)

**UI:**
- AppBar: Coin logo + "Bitcoin (BTC)" + bell icon
- Price hero: "$64,281.90" (Bold 40sp) + "+4.2%" green pill
- Time filter chips: 1D | 7D | 1M | 3M | 1Y (tap changes chart range → re-fetch)
- Full-width `fl_chart` LineChart:
  - Gradient fill, cyan line
  - Touch to show price tooltip (crosshair)
  - Animated on data change (duration 400ms)
  - Data from: `GET /coins/{id}/market_chart?vs_currency=usd&days={days}`
- Stats grid (2x2 glass cards):
  - Market Cap | 24h Volume | All-Time High | Circulating Supply
- "Add to Watchlist" button (star, outlined/filled toggle)
- "Buy / Pay with {coin}" CTA button

---

### 11. SHOP SCREEN (`/shop`)

**UI:**
- AppBar: "Shop & Go" + cart icon (badge count)
- Camera preview (top 40% of screen): mobile_scanner active
  - Scan frame overlay (smaller, 160px)
  - "Scan product barcode" label
- Product grid (bottom 60%):
  - Manual add: search bar
  - Scanned products appear as cards with:
    - Product image (placeholder if no image)
    - Product name, barcode
    - Price (INR)
    - Quantity +/- controls
- Floating cart summary pill (bottom):
  - "🛒 3 items • ₹1,250" + "View Cart →"

**Logic:**
- On barcode scan → lookup product in Hive products box
- If not found → show "Add Product" bottom sheet (name, price, image)
- Add to CartBloc state
- Cart persisted in Hive

---

### 12. CART SCREEN (`/cart`)

**UI:**
- AppBar: "My Cart" + edit icon
- Cart items list (glass cards):
  - Product name, image, price
  - Quantity stepper (+/-)
  - Remove (swipe or trash icon)
- Order summary glass card (bottom):
  - Subtotal, Tax (5%), Discount (if any), Total Bold
- "Proceed to Checkout →" CTA button (full width gradient)

---

### 13. CHECKOUT SCREEN (`/checkout`)

**UI:**
- AppBar: "Checkout"
- Order summary (expandable glass card)
- Payment method selector:
  - UPI toggle card
  - Crypto toggle card
  - Cash toggle card
- Amount + live crypto equivalent
- "Confirm & Pay ₹1,312" gradient button
- On pay: same Razorpay / WalletConnect flow as payment screen
- On success: clear cart, save transaction, → `/receipt`

---

### 14. TRANSACTIONS SCREEN (`/home/activity`)

**UI:**
- AppBar: "Activity" + filter icon
- Filter chips row (scrollable): All | UPI | Crypto | Shopping
- Date group headers: "Today", "Yesterday", "Mar 26"
- Transaction tiles (glass cards):
  - Left: category icon circle (colored)
    - UPI: blue arrow, Crypto: purple chain, Shopping: green bag
  - Center: recipient/merchant name + date time
  - Right: amount Bold (green for credit, red for debit) + method label
- Empty state: illustration + "No transactions yet"
- Pull-to-refresh: reload from Hive

**Data Source:** Hive box `'transactions'` (List<TransactionModel>)
**Filter Logic:** filter by type field in TransactionModel

---

### 15. TRANSACTION DETAIL SCREEN (`/transaction/:id`)

**UI:**
- AppBar: "Transaction Details" + share icon
- Status badge: "SUCCESS" / "FAILED" / "PENDING" (colored pill)
- Amount center: large, colored
- Receipt-style glass card (dashed border top):
  - Transaction ID (monospace, copyable)
  - Type (UPI / Crypto / Shopping)
  - Recipient / Merchant
  - Date & Time
  - Method details (UPI ID / Wallet address / Items count)
  - Network fee (if crypto)
- "Download Receipt" outlined button
- "Report Issue" text button (bottom)

---

### 16. PROFILE SCREEN (`/home/profile`)

**UI:**
- AppBar: "Profile"
- Top card (glass):
  - Avatar (80px circle)
  - Name Bold, phone secondary
  - UPI ID label (cyan)
  - Verification badge (KYC status)
- Sections (list tiles with glass cards):
  - "My Bank Accounts" → linked bank list
  - "UPI Details" → show/copy UPI ID
  - "Connected Wallets" → MetaMask/WalletConnect status
  - "KYC Status" → step indicator (Pending/Verified)
- Quick stats row: Total Sent | Total Received | Transactions count

---

### 17. SETTINGS SCREEN (`/settings`)

**UI:**
- AppBar: "Settings"
- Sections (glass cards, list tiles):
  - **Appearance:** Theme switch (Dark/Light), Accent color picker
  - **Security:** Change PIN, Biometric toggle, Auto-lock timer
  - **Printer:** Bluetooth printer setup, Test print
  - **Notifications:** Payment alerts, Price alerts toggle
  - **About:** App version, Terms, Privacy, Logout (red text)

---

## 🗃️ HIVE DATA MODELS

```dart
// TransactionModel (HiveType id: 0)
@HiveType(typeId: 0)
class TransactionModel {
  @HiveField(0) String id;          // TXN-UUID
  @HiveField(1) String type;        // 'upi' | 'crypto' | 'shopping'
  @HiveField(2) double amountInr;
  @HiveField(3) String? cryptoCoin; // 'ethereum', 'bitcoin'
  @HiveField(4) double? cryptoAmount;
  @HiveField(5) String recipientName;
  @HiveField(6) String recipientAddress; // UPI ID or wallet
  @HiveField(7) DateTime timestamp;
  @HiveField(8) String status;      // 'success' | 'failed' | 'pending'
  @HiveField(9) String? txnHash;    // Blockchain hash if crypto
  @HiveField(10) List<String>? itemIds; // For shopping
}

// ProductModel (HiveType id: 1)
@HiveType(typeId: 1)
class ProductModel {
  @HiveField(0) String barcode;
  @HiveField(1) String name;
  @HiveField(2) double priceInr;
  @HiveField(3) String? imageUrl;
  @HiveField(4) String category;
}

// CoinModel (HiveType id: 2) — for watchlist cache
@HiveType(typeId: 2)
class CoinModel {
  @HiveField(0) String id;          // 'bitcoin'
  @HiveField(1) String symbol;      // 'BTC'
  @HiveField(2) String name;
  @HiveField(3) String imageUrl;
  @HiveField(4) double currentPriceUsd;
  @HiveField(5) double currentPriceInr;
  @HiveField(6) double priceChange24h;
  @HiveField(7) double marketCap;
  @HiveField(8) List<double> sparkline7d;
  @HiveField(9) DateTime lastUpdated;
}

// UserModel (HiveType id: 3)
@HiveType(typeId: 3)
class UserModel {
  @HiveField(0) String name;
  @HiveField(1) String phone;
  @HiveField(2) String upiId;
  @HiveField(3) String? walletAddress;
  @HiveField(4) String kycStatus; // 'pending' | 'verified'
  @HiveField(5) String? authToken;
}

// Hive Boxes:
// 'transactions' → Box<TransactionModel>
// 'products'     → Box<ProductModel>
// 'watchlist'    → Box<String> (coin IDs)
// 'user'         → Box<UserModel>
// 'settings'     → Box<dynamic>
// 'price_cache'  → Box<dynamic> (CoinGecko cache, TTL 60s)
```

---

## 🔌 SERVICE LOCATOR (`lib/core/service_locator.dart`)

```dart
// Using get_it
final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(CoinModelAdapter());
  Hive.registerAdapter(UserModelAdapter());

  // Services (singletons)
  sl.registerLazySingleton<Dio>(() => _createDio());
  sl.registerLazySingleton<CoinGeckoService>(() => CoinGeckoService(sl<Dio>()));
  sl.registerLazySingleton<HiveService>(() => HiveService());
  sl.registerLazySingleton<RazorpayService>(() => RazorpayService());
  sl.registerLazySingleton<WalletConnectService>(() => WalletConnectService());

  // Blocs (factories — new instance per route)
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(sl<CoinGeckoService>(), sl<HiveService>()));
  sl.registerFactory<MarketsBloc>(() => MarketsBloc(sl<CoinGeckoService>(), sl<HiveService>()));
  sl.registerFactory<PaymentBloc>(() => PaymentBloc(sl<RazorpayService>(), sl<WalletConnectService>(), sl<CoinGeckoService>(), sl<HiveService>()));
  sl.registerFactory<ScannerBloc>(() => ScannerBloc());
  sl.registerFactory<ShopBloc>(() => ShopBloc(sl<HiveService>()));
  sl.registerFactory<TransactionsBloc>(() => TransactionsBloc(sl<HiveService>()));
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<HiveService>()));
}

Dio _createDio() {
  final dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ));
  dio.interceptors.add(LogInterceptor());
  // Add cache interceptor for CoinGecko (60s TTL)
  return dio;
}
```

---

## 💳 PAYMENT INTEGRATION

### Razorpay (UPI)
```dart
// lib/shared/services/razorpay_service.dart
class RazorpayService {
  final _razorpay = Razorpay();

  void initPayment({
    required double amountInPaise,  // amount * 100
    required String name,
    required String upiId,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) {
    final options = {
      'key': 'rzp_test_XXXXXXXXXX', // from flutter_dotenv
      'amount': amountInPaise.toInt(),
      'name': 'KryptoKart',
      'description': 'Payment to $name',
      'prefill': {'contact': '', 'email': ''},
      'external': {'wallets': ['paytm']},
      'method': {'upi': true, 'card': false, 'netbanking': false},
    };
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.open(options);
  }

  void dispose() => _razorpay.clear();
}
```

### WalletConnect (Crypto)
```dart
// lib/shared/services/walletconnect_service.dart
// Implement WalletConnect v2 session management
// sendTransaction(to, amountInWei, chainId: 1 for ETH mainnet)
// Listen to session events, handle approve/reject
// Display QR for desktop pairing if needed
// Store session in Hive for reconnection
```

---

## 📊 CHART IMPLEMENTATION (fl_chart)

### Dashboard Analytics Chart
```dart
// Portfolio line chart — 30 day dummy/local data
LineChartData dashboardChart({required List<FlSpot> spots}) => LineChartData(
  gridData: FlGridData(show: false),
  borderData: FlBorderData(show: false),
  titlesData: FlTitlesData(show: false),
  lineBarsData: [
    LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Color(0xFF00F6FF),
      barWidth: 2.5,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x5500F6FF), Color(0x0000F6FF)],
        ),
      ),
      dotData: FlDotData(show: false),
    ),
  ],
);
```

### Markets Feature Chart (7-day from CoinGecko)
```dart
// Convert API response prices[][1] → List<FlSpot>
// x = index (0..n), y = price in USD
// X-axis labels: format timestamps prices[][0] → "HH:mm"
// Show 6 labels: 08:00 AM, 12:00 PM, 04:00 PM, 08:00 PM, CURRENT
// On time range change (1D/7D/1M): re-fetch with days param
// Animate chart on data update: animationDuration: 400ms
```

---

## ⚡ REAL-TIME UPDATE STRATEGY

```dart
// In each Bloc that needs live data:

// 1. DashboardBloc — prices refresh
Timer? _priceTimer;

void _startPriceRefresh(Emitter emit) {
  _priceTimer = Timer.periodic(Duration(seconds: 30), (_) {
    add(DashboardEvent.RefreshPrices());
  });
}

@override
Future<void> close() {
  _priceTimer?.cancel();
  return super.close();
}

// 2. MarketsBloc — full markets refresh
// Timer: 60 seconds (CoinGecko free tier: 50 calls/min)

// 3. PaymentBloc — live conversion on amount change
// Debounce: 500ms after last keypress
// Use latest cached INR price from Hive price_cache

// 4. Connectivity handling:
// connectivity_plus: listen to ConnectivityResult
// Show offline banner if no internet
// Use cached Hive data when offline
// Queue transactions for retry when back online
```

---

## 🏗️ BLOC ARCHITECTURE PATTERN (CONSISTENT ACROSS ALL)

```dart
// PATTERN: Every feature follows this exact structure

// EVENTS
abstract class FeatureEvent extends Equatable {}

// STATES
abstract class FeatureState extends Equatable {}
class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState { final Data data; }
class FeatureError extends FeatureState { final String message; }

// BLOC
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final Service service;
  FeatureBloc(this.service) : super(FeatureInitial()) {
    on<LoadFeature>(_onLoad, transformer: droppable());
    on<RefreshFeature>(_onRefresh, transformer: restartable());
  }

  Future<void> _onLoad(LoadFeature event, Emitter<FeatureState> emit) async {
    emit(FeatureLoading());
    try {
      final data = await service.fetchData();
      emit(FeatureLoaded(data));
    } catch (e) {
      emit(FeatureError(e.toString()));
    }
  }
}

// BlocProvider in routes:
// Every screen wrapped with BlocProvider<FeatureBloc>(
//   create: (_) => sl<FeatureBloc>()..add(LoadFeature()),
//   child: FeatureScreen(),
// )
```

---

## 🔄 CONNECTIVITY & OFFLINE SUPPORT

```dart
// lib/shared/services/connectivity_service.dart
class ConnectivityService {
  final _connectivity = Connectivity();

  Stream<bool> get isConnectedStream =>
      _connectivity.onConnectivityChanged.map(
        (result) => result != ConnectivityResult.none,
      );

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

// Offline behavior:
// - Markets: show cached CoinModel from Hive (show stale badge)
// - Dashboard: show cached portfolio from Hive
// - Transactions: always available (local Hive)
// - Payment: block with "No internet" dialog
// - Banner: AnimatedContainer slides down when offline
```

---

## 🌟 CORE REUSABLE WIDGETS

```dart
// lib/core/widgets/glass_card.dart
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  // Uses glassmorphism BoxDecoration defined above
}

// lib/core/widgets/kk_button.dart
class KkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  // Gradient background, 56px height, loading spinner state
}

// lib/core/widgets/kk_text_field.dart
class KkTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  // Glass style, cyan focus border, label above input
}

// lib/core/widgets/shimmer_loader.dart
// Shimmer effect for list/card loading states
// Use shimmer package or custom implementation

// lib/shared/widgets/bottom_nav_bar.dart
// Custom bottom nav with center FAB (Scan)
// 5 items: Home | Shop | [Scan FAB] | Activity | Profile
// Active state: icon color #00F6FF + glow shadow
// FAB: 64px circle, gradient, elevated
```

---

## 📦 pubspec.yaml

```yaml
name: kryptokart
description: Unified Fintech + POS System
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.4
  equatable: ^2.0.5
  go_router: ^13.2.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  dio: ^5.4.0
  get_it: ^7.6.7
  fl_chart: ^0.68.0
  mobile_scanner: ^5.0.0
  razorpay_flutter: ^1.3.6
  walletconnect_flutter_v2: ^2.1.6
  google_fonts: ^6.2.1
  cached_network_image: ^3.3.1
  flutter_animate: ^4.5.0
  connectivity_plus: ^6.0.3
  flutter_dotenv: ^5.1.0
  intl: ^0.19.0
  uuid: ^4.3.3
  path_provider: ^2.1.2
  image_picker: ^1.0.7
  permission_handler: ^11.3.0
  shimmer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/images/
    - assets/icons/
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
        - asset: assets/fonts/Poppins-Medium.ttf  weight: 500
        - asset: assets/fonts/Poppins-SemiBold.ttf weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf weight: 700
```

---

## 🔐 `.env` FILE

```
RAZORPAY_KEY_ID=rzp_test_XXXXXXXXXX
COINGECKO_API_KEY=
WALLETCONNECT_PROJECT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

---

## 🚀 `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await HiveService.init();
  await setupServiceLocator();
  runApp(const KryptoKartApp());
}

class KryptoKartApp extends StatelessWidget {
  const KryptoKartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KryptoKart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRoutes.router,
    );
  }
}
```

---

## 🎨 THEME (`lib/core/theme/app_theme.dart`)

```dart
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF00040F),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00F6FF),
      secondary: Color(0xFF0080FF),
      surface: Color(0xFF0D1117),
      error: Color(0xFFFF4B4B),
    ),
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF00040F),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    // inputDecorationTheme, elevatedButtonTheme, etc.
  );
}
```

---

## ✅ CRITICAL REQUIREMENTS (MUST FOLLOW)

1. **Every screen** must use BlocBuilder/BlocListener — NO setState in main screens
2. **All API calls** through Dio in services only — NO direct http in widgets/blocs
3. **All local storage** through HiveService methods only — NO direct Box.get in UI
4. **GoRouter** for ALL navigation — NO Navigator.push directly
5. **Error handling**: every Bloc catch block must emit ErrorState with user-friendly message
6. **Loading states**: every screen shows shimmer/skeleton while loading (NOT blank screen)
7. **Empty states**: every list screen has illustration + message for empty data
8. **Offline mode**: show cached data + offline banner when no connectivity
9. **Real-time prices**: Dashboard (30s), Markets (60s), Payment conversion (live on input)
10. **CoinGecko rate limit**: max 50 req/min free tier — implement 60s cache in Hive price_cache box
11. **Transactions** always saved to Hive immediately after payment (before receipt screen)
12. **QR Scanner** must handle UPI, crypto wallet, and product barcode — route accordingly
13. **Payment screen** shows live INR→crypto conversion as user types amount
14. **Bottom nav** persists across all 5 main tabs (ShellRoute in GoRouter)
15. **Poppins font** used throughout — no system fonts
16. **Glassmorphism** on all cards: dark background + subtle cyan glow border
17. **Animations**: use flutter_animate for page transitions, button press, chart load
18. **No external app redirects** — all payments in-app

---

## 📋 DUMMY DATA (FOR DEMO MODE)

```dart
// lib/shared/constants/dummy_data.dart

final dummyTransactions = [
  TransactionModel(id: 'TXN-001', type: 'upi', amountInr: 1250.0, recipientName: 'Coffee Shop', ...),
  TransactionModel(id: 'TXN-002', type: 'crypto', amountInr: 12500.0, cryptoCoin: 'ethereum', cryptoAmount: 0.052, recipientName: 'Alex Miller', ...),
  TransactionModel(id: 'TXN-003', type: 'shopping', amountInr: 3400.0, recipientName: 'KryptoMart', ...),
];

final dummyPortfolio = {
  'totalInr': 842500.0,
  'changePercent': 12.4,
  'upiBalance': 45000.0,
  'cryptoBalanceInr': 797500.0,
};

// Seed Hive with dummy data on first launch (check 'isFirstLaunch' flag in settings box)
```

---

## 🏁 DELIVERABLE CHECKLIST

Generate ALL of the following files, fully implemented:

- [ ] `pubspec.yaml`
- [ ] `.env`
- [ ] `lib/main.dart`
- [ ] `lib/config/routes/app_routes.dart`
- [ ] `lib/core/theme/` (3 files)
- [ ] `lib/core/utils/` (4 files including qr_classifier.dart)
- [ ] `lib/core/widgets/` (5 files)
- [ ] `lib/core/service_locator.dart`
- [ ] `lib/shared/models/` (5 model files + Hive adapters)
- [ ] `lib/shared/services/` (5 service files)
- [ ] `lib/shared/widgets/` (4 shared widget files)
- [ ] `lib/shared/constants/` (api_constants.dart, dummy_data.dart)
- [ ] All 13 feature folders with Bloc (event/state/bloc) + presentation screens
- [ ] All 16 screens fully implemented
- [ ] All reusable widget implementations

**Total target: ~80+ Dart files, production-ready.**

---

*Build KryptoKart — the app that makes PhonePe + Binance + Shopify feel like one.*
