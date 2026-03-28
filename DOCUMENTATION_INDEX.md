# KryptoKart - Project Documentation Index

**Comprehensive documentation for the KryptoKart Fintech + POS System**

Last Updated: March 28, 2026 | Version: 1.0.0 | Status: Production Ready ✅

---

## 🎯 **Quick Start**

### **For Frontend Developers**
```bash
cd billing_fixed
flutter pub get
flutter run
```
👉 See: [FRONTEND_DOCUMENTATION.md](FRONTEND_DOCUMENTATION.md)

### **For Backend Developers**
```bash
cd backend
npm install
npm start
```
👉 See: [BACKEND_DOCUMENTATION.md](BACKEND_DOCUMENTATION.md)

### **For Project Overview**
👉 See: [README_COMPREHENSIVE.md](README_COMPREHENSIVE.md)

---

## 📚 **Documentation Guide**

### **1. README_COMPREHENSIVE.md** (Main Documentation)
**Best for:** Project overview, architecture, tech stack, setup instructions

Contains:
- ✅ Project overview and philosophy
- ✅ Complete tech stack with versions
- ✅ Detailed project structure (frontend & backend)
- ✅ All REST API endpoints with examples
- ✅ 7 core application workflows
- ✅ Getting started guide
- ✅ Troubleshooting guide
- ✅ Design system specifications

**When to use:**
- First introduction to the project
- Understanding overall architecture
- Finding API endpoint specifications
- Design system colors and typography

---

### **2. FRONTEND_DOCUMENTATION.md** (Flutter App)
**Best for:** Mobile app development, BLoC patterns, feature workflows

Contains:
- ✅ Complete flutter tech stack
- ✅ Clean architecture explanation
- ✅ 9 feature modules detailed:
  - Authentication (login, register, KYC)
  - Billing/POS (shopping cart, scanning)
  - Payments (UPI + Crypto workflows)
  - Dashboard (portfolio overview)
  - Markets (crypto price charts)
  - Transactions (history & analytics)
  - Scanner (barcode/QR detection)
  - Profile (user management)
  - Settings (app preferences)
- ✅ BLoC pattern and state management
- ✅ Local storage with Hive
- ✅ API integration with Dio
- ✅ UI/UX design system
- ✅ Development guide and testing

**When to use:**
- Building new Flutter features
- Understanding BLoC state management
- Feature-specific workflows
- UI component specifications
- Local data persistence

---

### **3. BACKEND_DOCUMENTATION.md** (Node.js API)
**Best for:** REST API development, database schema, payment integration

Contains:
- ✅ Complete backend tech stack
- ✅ Project structure and organization
- ✅ Installation & setup guide
- ✅ Environment configuration (.env)
- ✅ MongoDB schema definitions:
  - Users (with KYC)
  - Products
  - Cart
  - Transactions
  - Watchlist
  - Settings
- ✅ Detailed API endpoints with cURL examples
  - Authentication (3 endpoints)
  - User Management (4 endpoints)
  - Products (6 endpoints)
  - Cart (5 endpoints)
  - Payments (4 endpoints)
  - Transactions (4 endpoints)
  - Wallet (3 endpoints)
- ✅ Error handling and HTTP status codes
- ✅ Security (JWT, passwords)
- ✅ Deployment guides (Heroku, AWS)
- ✅ Troubleshooting

**When to use:**
- Setting up backend locally
- Creating/modifying API endpoints
- Understanding database schema
- Payment processing integration
- Deployment to production

---

## 🏗️ **Architecture Overview**

### **System Design**
```
┌─────────────────────────────────────┐
│     Flutter Mobile App              │
│  (Frontend - Clean Architecture)    │
│                                     │
│  Presentation ──> Domain ──> Data   │
│  (UI / BLoC)      (Logic)  (APIs)   │
└────────────┬──────────────────────┘
             │
             │ HTTP/REST
             │
┌────────────▼──────────────────────┐
│   Node.js Express Backend          │
│  (REST API - Clean Architecture)   │
│                                     │
│  Routes ──> Controllers ──> Models │
│            (Logic)        (Schema)  │
└────────────┬──────────────────────┘
             │
             │ Query Language
             │
┌────────────▼──────────────────────┐
│     MongoDB Database               │
│  (Document NoSQL)                  │
│                                    │
│  Collections:                      │
│  • Users (with KYC)                │
│  • Products                        │
│  • Transactions                    │
│  • Cart Items                      │
│  • Watchlist                       │
└────────────────────────────────────┘
```

### **Payment Processing**
```
UPI Payment Flow:
User App
  ↓
Razorpay SDK (Modal)
  ↓
UPI Payment
  ↓
Razorpay Webhook
  ↓
Backend: Verify signature
  ↓
MongoDB: Record transaction
  ↓
Receipt Screen

Crypto Payment Flow:
User App
  ↓
WalletConnect v2
  ↓
User's Wallet (MetaMask, etc.)
  ↓
Blockchain Transaction
  ↓
Backend: Verify on-chain
  ↓
MongoDB: Record transaction
  ↓
Confirmation Screen
```

---

## 📂 **File Structure Reference**

```
billing_fixed/
├── README_COMPREHENSIVE.md          ← PROJECT OVERVIEW
├── FRONTEND_DOCUMENTATION.md        ← FLUTTER APP DOCS
├── BACKEND_DOCUMENTATION.md         ← API/DATABASE DOCS
│
├── lib/                             # Frontend Code
│   ├── main.dart                    # App entry point
│   ├── core/                        # Shared code
│   ├── shared/                      # Constants, models, services
│   └── features/                    # Feature modules (12 features)
│       ├── auth/
│       ├── billing/
│       ├── payments/
│       ├── dashboard/
│       ├── markets/
│       ├── transactions/
│       ├── scanner/
│       ├── shop/
│       ├── profile/
│       ├── settings/
│       ├── splash/
│       └── onboarding/
│
├── backend/                         # Node.js Backend
│   ├── server.js                    # Express app
│   ├── package.json                 # Dependencies
│   ├── config/                      # Configuration
│   ├── models/                      # MongoDB schemas
│   ├── routes/                      # API routes (9 routes)
│   ├── controllers/                 # Business logic
│   ├── services/                    # External APIs
│   └── utils/                       # Helpers
│
├── docs/                            # Additional docs
│   ├── razorpay_integration_setup.md
│   └── api_reference.md
│
├── pubspec.yaml                     # Flutter dependencies
├── android/                         # Android config
├── ios/                             # iOS config
└── web/                             # Web config
```

---

## 🔗 **API Endpoints Quick Reference**

| Module | Endpoint | Method | Purpose |
|--------|----------|--------|---------|
| **Auth** | `/api/auth/register` | POST | User registration |
| | `/api/auth/login` | POST | User login |
| | `/api/auth/refresh` | POST | Refresh JWT |
| **User** | `/api/user/profile` | GET | Get profile |
| | `/api/user/kyc` | POST | Submit KYC |
| | `/api/user/balance` | GET | Check balance |
| **Products** | `/api/products` | GET | List products |
| | `/api/products` | POST | Create product |
| | `/api/products/{id}` | GET | Get product |
| | `/api/products/barcode/{barcode}` | GET | Search by barcode |
| | `/api/products/{id}` | PUT | Update product |
| | `/api/products/{id}` | DELETE | Delete product |
| **Cart** | `/api/cart` | GET | Get cart |
| | `/api/cart/add` | POST | Add to cart |
| | `/api/cart/update` | PUT | Update quantity |
| | `/api/cart/remove` | DELETE | Remove item |
| | `/api/cart/clear` | DELETE | Clear cart |
| **Payments** | `/api/payments/create-order` | POST | Create Razorpay order |
| | `/api/payments/verify` | POST | Verify payment |
| | `/api/payments/crypto` | POST | Process crypto payment |
| | `/api/payments/methods` | GET | Get payment methods |
| **Transactions** | `/api/transactions` | GET | List transactions |
| | `/api/transactions/stats` | GET | Get statistics |
| | `/api/transactions/{id}` | GET | Get details |
| | `/api/transactions/{id}` | DELETE | Delete (admin) |
| **Wallet** | `/api/wallet/address` | GET | Get wallet address |
| | `/api/wallet/save` | POST | Save address |
| | `/api/wallet/upi-mapping/{address}` | GET | Get mapping |
| **Watchlist** | `/api/watchlist` | GET | Get watchlist |
| | `/api/watchlist/toggle` | POST | Add/remove item |
| **Settings** | `/api/settings` | GET | Get settings |
| | `/api/settings` | PUT | Update settings |

---

## 🔐 **Security & Auth**

### **Authentication Flow**
```
Register/Login
  ↓
JWT Token (7 days)
  ↓
Store in SecureStorage
  ↓
Add to API Headers: Authorization: Bearer {token}
  ↓
Token expires
  ↓
Call /api/auth/refresh
  ↓
Get new token
```

### **Data Protection**
- ✅ Passwords hashed with bcryptjs (10 rounds)
- ✅ JWT token-based authentication
- ✅ Secure storage for sensitive data
- ✅ HTTPS for API communication
- ✅ CORS restriction to frontend origin
- ✅ Input validation on all endpoints
- ✅ Signature verification for Razorpay

---

## 📊 **Database Collections**

### **Users**
- `_id`, `name`, `phone`, `password` (hashed)
- Payment methods: `upiId`, `walletAddress`
- KYC: `kycStatus`, `kycData` (PAN, Aadhaar, bank)
- Balances: `portfolioValue`, `cryptoBalanceInr`, `upiBalance`

### **Products**
- `_id`, `name`, `description`, `price`
- Barcode: `barcode` (unique)
- Inventory: `quantity`, `inStock`, `minQuantity`
- Images: `imageUrl`

### **Transactions**
- `_id`, `userId`, `amount`, `currency`
- Type: `upi` | `crypto`
- Status: `pending` | `completed` | `failed`
- References: `razorpayOrderId`, `razorpayPaymentId`, `txHash`
- Items: Array of `{ productId, quantity, price }`

### **Carts**
- `_id`, `userId`
- `items`: Array of `{ productId, quantity }`
- `total`: Calculated total
- TTL: 7 days auto-delete

---

## 🚀 **Deployment & Scaling**

### **Frontend Deployment**
```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
flutter build windows  # Desktop
```

### **Backend Deployment**
- **Heroku**: `git push heroku main`
- **AWS EC2**: PM2 + Nginx + MongoDB Atlas
- **Docker**: Containerize with Docker Compose
- **Kubernetes**: Scale with K8s (production)

### **Infrastructure Checklist**
- ✅ **API Server**: Node.js on EC2 or Heroku
- ✅ **Database**: MongoDB Atlas (managed)
- ✅ **CDN**: CloudFront for assets
- ✅ **SSL/TLS**: AWS Certificate Manager
- ✅ **Load Balancer**: AWS Application Load Balancer
- ✅ **Monitoring**: CloudWatch / DataDog
- ✅ **Logging**: CloudWatch Logs / Kibana
- ✅ **Backups**: Daily MongoDB snapshots

---

## 🛠️ **Tech Stack Summary**

| Layer | Technology | Version |
|-------|-----------|---------|
| **Mobile** | Flutter | 3.8+ |
| **State Mgmt** | flutter_bloc | 8.1.5 |
| **HTTP** | Dio | 5.4+ |
| **Local DB** | Hive | 2.2.3 |
| **Navigation** | GoRouter | 14.0+ |
| **Backend** | Node.js | 18+ LTS |
| **Framework** | Express.js | 4.19+ |
| **Database** | MongoDB | 6.0+ |
| **ODM** | Mongoose | 8.2.0 |
| **Auth** | JWT | Latest |
| **Password** | bcryptjs | 2.4.3 |
| **Payments** | Razorpay | 2.9.4 |
| **Crypto** | WalletConnect v2 | 2.3.1 |

---

## 📖 **Common Tasks**

### **I want to add a new API endpoint**
1. Create route in `backend/routes/`
2. Create/update controller in `backend/controllers/`
3. Update MongoDB schema if needed
4. Add endpoint constant to `lib/shared/constants/api_constants.dart`
5. Create repository method in Flutter
6. Create BLoC event/state
7. Implement feature

👁️ **See:** [BACKEND_DOCUMENTATION.md](BACKEND_DOCUMENTATION.md#api-endpoints)

### **I want to add a new Flutter feature**
1. Create feature directory structure
2. Create BLoC (bloc, event, state)
3. Create domain entities and usecases
4. Create data models and repositories
5. Create presentation (pages, widgets)
6. Register BLoC in service_locator
7. Add routes to GoRouter

👁️ **See:** [FRONTEND_DOCUMENTATION.md](FRONTEND_DOCUMENTATION.md#development-guide)

### **I want to modify the payment flow**
1. Update Razorpay/WalletConnect service
2. Update payment usecase
3. Update payment BLoC
4. Update payment screens
5. Test with sandbox credentials
6. Deploy backend changes first

👁️ **See:** [README_COMPREHENSIVE.md](README_COMPREHENSIVE.md#-application-workflows)

### **I want to improve performance**
1. Use cached_network_image for assets
2. Implement ListView.builder for lists
3. Add pagination to API requests
4. Optimize Hive queries
5. Use lazy loading for images
6. Profile with Flutter DevTools

👁️ **See:** [FRONTEND_DOCUMENTATION.md](FRONTEND_DOCUMENTATION.md#-performance-optimization)

---

## 🐛 **Troubleshooting**

### **Port 4000 already in use**
```bash
npx kill-port 4000
```

### **Cannot connect to backend**
```bash
# Check backend is running
curl http://192.168.x.x:4000/health

# Update backend URL in api_constants.dart
static const String backendBase = 'http://192.168.x.x:4000';
```

### **MongoDB connection error**
```bash
# Start local MongoDB
mongod --dbpath ./data

# Or use Atlas (recommended)
# Update .env: MONGODB_URI=mongodb+srv://...
```

### **Flutter build error**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build
flutter run
```

👁️ **See:** [README_COMPREHENSIVE.md](README_COMPREHENSIVE.md#-troubleshooting)

---

## 📞 **Getting Help**

### **Documentation**
- [Frontend Development](FRONTEND_DOCUMENTATION.md)
- [Backend API Reference](BACKEND_DOCUMENTATION.md)
- [Project Overview](README_COMPREHENSIVE.md)
- [Razorpay Setup](docs/razorpay_integration_setup.md)

### **External Resources**
- [Flutter Docs](https://flutter.dev)
- [BLoC Library](https://bloclibrary.dev)
- [Express.js](https://expressjs.com)
- [MongoDB](https://docs.mongodb.com)
- [Razorpay API](https://razorpay.com/docs)
- [WalletConnect](https://docs.walletconnect.com)

### **Contact**
- 🐛 **Bug Reports**: GitHub Issues
- 💬 **Questions**: Team Slack / Discord
- 📧 **Email**: support@kryptokart.app

---

## ✅ **Checklist for New Developers**

- [ ] Read this file (Documentation Index)
- [ ] Read [README_COMPREHENSIVE.md](README_COMPREHENSIVE.md) (Project Overview)
- [ ] Choose: Frontend or Backend
  - [ ] Frontend → Read [FRONTEND_DOCUMENTATION.md](FRONTEND_DOCUMENTATION.md)
  - [ ] Backend → Read [BACKEND_DOCUMENTATION.md](BACKEND_DOCUMENTATION.md)
- [ ] Set up environment locally
- [ ] Review relevant API endpoints
- [ ] Understand feature workflows
- [ ] Run project locally
- [ ] Review code style guidelines
- [ ] Start contributing!

---

## 📈 **Project Stats**

- **Total Lines of Code**: ~50,000+
- **Frontend**: ~30,000 lines (Flutter/Dart)
- **Backend**: ~15,000 lines (Node.js/JavaScript)
- **Database**: 6 collections + relationships
- **API Endpoints**: 40+
- **Features**: 12 major features
- **Test Coverage**: Comprehensive (unit, widget, integration)
- **Build Time**: ~3 minutes (clean build)

---

## 🎓 **Learning Path**

### **For Frontend Developers (Beginners)**
1. Flutter basics (widgets, navigation)
2. State management (BLoC pattern)
3. API integration (Dio, error handling)
4. Local storage (Hive)
5. Payment integration (Razorpay, WalletConnect)
6. Testing (unit, widget tests)

### **For Backend Developers (Beginners)**
1. Express.js & REST APIs
2. MongoDB & Mongoose
3. User authentication (JWT)
4. Error handling & validation
5. Payment processing (Razorpay)
6. Testing & deployment

---

## 📅 **Version History**

| Version | Date | Status | Highlights |
|---------|------|--------|-----------|
| 1.0.0 | Mar 28, 2026 | ✅ Production | Full release |
| 0.9.0 | Mar 20, 2026 | 🧪 Beta | Testing phase |
| 0.5.0 | Mar 1, 2026 | 🔧 Development | Core features |

---

## 🎯 **Future Roadmap**

### **Q2 2026**
- [ ] Multi-language support (Hindi, Tamil, etc.)
- [ ] Real-time notifications
- [ ] Instant refunds
- [ ] Bill sharing & QR invoices

### **Q3 2026**
- [ ] Voice commands
- [ ] AR product visualization
- [ ] Machine learning for fraud detection
- [ ] Advanced analytics dashboard

### **Q4 2026**
- [ ] B2B wholesale marketplace
- [ ] Subscription management
- [ ] API for third-party integration
- [ ] White-label solution

---

## 📝 **License**

Proprietary © KryptoKart Inc. 2026

---

**Last Updated:** March 28, 2026  
**Maintained by:** KryptoKart Development Team  
**Status:** Production Ready ✅

---

**Need Help?** Start with the [README_COMPREHENSIVE.md](README_COMPREHENSIVE.md) or ask your team lead!