# KryptoKart Backend - API & Setup Documentation

Complete backend documentation for the KryptoKart payment and billing system.

---

## 📋 **Table of Contents**
1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Installation & Setup](#installation--setup)
5. [Environment Configuration](#environment-configuration)
6. [Database Schema](#database-schema)
7. [API Endpoints](#api-endpoints)
8. [Authentication & Security](#authentication--security)
9. [Error Handling](#error-handling)
10. [Deployment](#deployment)

---

## 📖 **Overview**

The KryptoKart backend is a Node.js/Express REST API that serves the Flutter mobile application. It handles:
- User authentication (JWT-based)
- Product inventory management
- Shopping cart operations
- Payment processing (UPI via Razorpay, Crypto via blockchain)
- Transaction tracking and reporting
- User profile and KYC management
- Wallet address management

---

## 🛠️ **Tech Stack**

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Runtime** | Node.js | 18.x LTS+ | JavaScript execution |
| **Framework** | Express.js | 4.19.2+ | REST API framework |
| **Database** | MongoDB | 6.0+ | Document database |
| **ORM/ODM** | Mongoose | 8.2.0 | MongoDB schema & validation |
| **Auth** | JWT | jsonwebtoken 9.0.2 | Token-based authentication |
| **Password** | bcryptjs | 2.4.3 | Secure password hashing |
| **Payments** | Razorpay | 2.9.4 | UPI/card payments |
| **Validation** | validator | 13.11.0 | Input validation |
| **CORS** | cors | 2.8.5 | Cross-origin handling |
| **Logging** | morgan | 1.10.0 | HTTP request logging |
| **Config** | dotenv | 16.4.5 | Environment variables |

---

## 📁 **Project Structure**

```
backend/
├── server.js                  # Express app entry point
├── package.json               # Dependencies & scripts
├── .env                       # Environment variables (NOT in version control)
├── .env.example               # Example env template
│
├── config/
│   ├── db.js                  # MongoDB Mongoose connection
│   └── environment.js         # Config management
│
├── middleware/
│   ├── auth.js                # JWT verification middleware
│   ├── errorHandler.js        # Global error handling
│   ├── requestLogger.js       # HTTP request logging
│   └── validator.js           # Input validation middleware
│
├── models/
│   ├── User.js                # User schema & methods
│   ├── Product.js             # Product catalog model
│   ├── Cart.js                # Shopping cart model
│   ├── Transaction.js         # Payment transaction record
│   ├── Watchlist.js           # User watchlist/favorites
│   └── Settings.js            # App settings & config
│
├── routes/
│   ├── auth.js                # Login, register, refresh token
│   ├── user.js                # Profile, KYC, balance
│   ├── products.js            # CRUD operations, search
│   ├── cart.js                # Add, update, remove, clear
│   ├── payments.js            # Create order, verify payment
│   ├── transactions.js        # History, stats, export
│   ├── watchlist.js           # Toggle, list favorites
│   ├── wallet.js              # Manage crypto addresses
│   └── settings.js            # User preferences
│
├── controllers/               # Business logic layer
│   ├── authController.js      # Authentication logic
│   ├── userController.js      # User operations
│   ├── productController.js   # Product operations
│   ├── paymentController.js   # Payment processing
│   └── transactionController.js
│
├── services/
│   ├── razorpay.js            # Razorpay integration
│   ├── jwt.js                 # JWT token management
│   ├── crypto.js              # Blockchain interactions
│   └── email.js               # Email notifications
│
├── utils/
│   ├── validators.js          # Validation utilities
│   ├── errorHandler.js        # Error classes
│   ├── logger.js              # Logging utility
│   └── constants.js           # App constants
│
└── seeds/
    └── seed.js                # Database seeding script
```

---

## ⚙️ **Installation & Setup**

### **Step 1: Prerequisites**
```bash
# Verify versions
node --version      # Should be 18.0.0+
npm --version       # Should be 9.0.0+
mongodb --version   # Should be 6.0+
```

### **Step 2: Clone & Install**
```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Verify installation
npm list --depth=0
```

### **Step 3: Create Environment File**
```bash
# Copy template
cp .env.example .env

# Edit with your values
nano .env  # or open in editor
```

### **Step 4: Start Services**
```bash
# Terminal 1: Start MongoDB
mongod --dbpath ./data

# Terminal 2: Start backend server
npm start                # Production
npm run dev              # Development (with auto-reload)
```

### **Step 5: Verify Setup**
```bash
# Test health endpoint
curl http://localhost:4000/health

# Expected response:
# {"ok":true,"service":"KryptoKart Backend","timestamp":"2026-03-28T..."}
```

---

## 🔐 **Environment Configuration**

### **.env File Template**
```env
# Server
PORT=4000
NODE_ENV=development

# Database
MONGODB_URI=mongodb://localhost:27017/kryptokart
# Or MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/kryptokart?retryWrites=true&w=majority

# JWT
JWT_SECRET=your_super_secret_jwt_key_here_min_32_characters
JWT_EXPIRE=7d

# Razorpay (UPI Payments)
RAZORPAY_KEY_ID=rzp_live_AbCdEfGhIjKlMnOp
RAZORPAY_SECRET=your_razorpay_secret_key_here
RAZORPAY_WEBHOOK_SECRET=webhook_secret_from_dashboard

# WalletConnect (Crypto Payments)
WALLETCONNECT_PROJECT_ID=abc123def456ghi789jkl012mnopqrst
WALLETCONNECT_PROJECT_SECRET=xyz789uvw456rst123opq890lmn567ih

# External APIs
COINGECKO_API_KEY=your_coingecko_api_key  # Optional, free tier available
INFURA_API_KEY=your_infura_key_for_blockchain

# Email Service (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# CORS
CORS_ORIGIN=*

# Logging
LOG_LEVEL=info

# App Config
APP_NAME=KryptoKart
APP_VERSION=1.0.0
```

### **Configuration Priority**
1. **Environment Variables** (highest priority)
2. **.env File**
3. **Default Values** (in code)

---

## 🗄️ **Database Schema**

### **Users Collection**
```javascript
{
  _id: ObjectId,
  name: {
    type: String,
    required: true,
    minlength: 2,
    maxlength: 100
  },
  phone: {
    type: String,
    required: true,
    unique: true,
    match: /^[0-9]{10}$/  // 10 digits
  },
  password: {
    type: String,        // Hashed via bcryptjs
    required: true,
    minlength: 4
  },
  
  // Payment Methods
  upiId: String,                    // UPI identifier
  walletAddress: String,             // ETH/Polygon address
  
  // KYC Status
  kycStatus: {
    type: String,
    enum: ['pending', 'in_progress', 'verified'],
    default: 'pending'
  },
  kycData: {
    pan: String,                     // 10-char PAN
    aadhaar: String,                 // 12-digit Aadhaar
    dob: Date,                       // Date of birth
    bankName: String,
    accountNumber: String,
    ifsc: String,                    // Bank IFSC code
    accountHolderName: String,
    kycSubmittedAt: Date
  },
  
  // Balances
  portfolioValue: { type: Number, default: 0 },
  cryptoBalanceInr: { type: Number, default: 0 },
  upiBalance: { type: Number, default: 0 },
  
  // Profile
  avatarUrl: String,
  email: { type: String, unique: true, sparse: true },
  
  // Timestamps
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}
```

### **Products Collection**
```javascript
{
  _id: ObjectId,
  name: {
    type: String,
    required: true,
    index: true
  },
  description: String,
  category: {
    type: String,
    default: 'General',
    index: true
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  barcode: {
    type: String,
    unique: true,
    sparse: true,
    index: true
  },
  sku: String,                      // Stock keeping unit
  imageUrl: String,
  
  // Inventory
  quantity: { type: Number, default: 0 },
  minQuantity: { type: Number, default: 5 },
  inStock: Boolean,
  
  // Pricing
  costPrice: Number,
  discount: { type: Number, default: 0 },
  taxRate: { type: Number, default: 0 },
  
  // Metadata
  supplier: String,
  expiryDate: Date,
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}
```

### **Transactions Collection**
```javascript
{
  _id: ObjectId,
  userId: ObjectId,                 // ref: User
  
  // Amount Info
  amount: Number,
  currency: {
    type: String,
    enum: ['INR', 'ETH', 'MATIC'],
    default: 'INR'
  },
  
  // Payment Details
  type: {
    type: String,
    enum: ['upi', 'crypto', 'wallet'],
    required: true
  },
  paymentMethod: {
    type: String,
    enum: ['razorpay', 'walletconnect', 'direct'],
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'completed', 'failed', 'refunded'],
    default: 'pending',
    index: true
  },
  
  // Reference IDs
  razorpayOrderId: String,
  razorpayPaymentId: String,
  razorpaySignature: String,
  txHash: String,                   // Blockchain tx hash
  
  // Cart Items
  items: [{
    productId: ObjectId,
    productName: String,
    quantity: Number,
    unitPrice: Number,
    totalPrice: Number
  }],
  
  // Totals
  subtotal: Number,
  taxAmount: Number,
  discountAmount: Number,
  finalAmount: Number,
  
  // Receipt
  receipt: {
    url: String,
    generatedAt: Date,
    printedAt: Date
  },
  
  // Timestamps
  createdAt: { type: Date, default: Date.now, index: true },
  completedAt: Date,
  updatedAt: { type: Date, default: Date.now }
}
```

### **Carts Collection**
```javascript
{
  _id: ObjectId,
  userId: ObjectId,                 // ref: User
  items: [{
    productId: ObjectId,            // ref: Product
    quantity: Number,
    addedAt: Date
  }],
  total: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
  expiresAt: { type: Date, index: { expireAfterSeconds: 604800 } }  // 7 days TTL
}
```

---

## 🔗 **API Endpoints**

### **Authentication** (`/api/auth`)

#### **POST /register**
Register a new user.

```bash
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9876543210",
    "password": "SecurePassword123",
    "name": "John Doe"
  }'
```

**Request Body:**
```json
{
  "phone": "9876543210",      // 10 digits
  "password": "SecurePassword123",  // min 4 chars
  "name": "John Doe"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "_id": "607f1f77bcf86cd799439011",
      "name": "John Doe",
      "phone": "9876543210",
      "kycStatus": "pending"
    }
  }
}
```

---

#### **POST /login**
Authenticate user and get JWT token.

```bash
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9876543210",
    "password": "SecurePassword123"
  }'
```

**Request Body:**
```json
{
  "phone": "9876543210",
  "password": "SecurePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "_id": "607f1f77bcf86cd799439011",
      "name": "John Doe",
      "phone": "9876543210",
      "portfolioValue": 842500,
      "kycStatus": "verified"
    }
  }
}
```

---

#### **POST /refresh**
Refresh expired JWT token.

```bash
curl -X POST http://localhost:4000/api/auth/refresh \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### **User Management** (`/api/user`)

#### **GET /profile**
Get logged-in user's profile.

```bash
curl -X GET http://localhost:4000/api/user/profile \
  -H "Authorization: Bearer {token}"
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "607f1f77bcf86cd799439011",
    "name": "John Doe",
    "phone": "9876543210",
    "email": "john@example.com",
    "upiId": "john@okhbank",
    "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f76bC4",
    "kycStatus": "verified",
    "portfolioValue": 842500,
    "cryptoBalanceInr": 797500,
    "upiBalance": 45000,
    "avatarUrl": "https://example.com/avatar.jpg",
    "createdAt": "2026-01-15T10:30:00Z"
  }
}
```

---

#### **POST /kyc**
Submit or update KYC information.

```bash
curl -X POST http://localhost:4000/api/user/kyc \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "pan": "ABCDE1234F",
    "aadhaar": "123456789012",
    "dob": "1990-05-15",
    "bankName": "HDFC Bank",
    "accountNumber": "1234567890123456",
    "ifsc": "HDFC0000123",
    "accountHolderName": "John Doe"
  }'
```

**Request Body:**
```json
{
  "pan": "ABCDE1234F",
  "aadhaar": "123456789012",
  "dob": "1990-05-15",
  "bankName": "HDFC Bank",
  "accountNumber": "1234567890123456",
  "ifsc": "HDFC0000123",
  "accountHolderName": "John Doe"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "KYC submitted successfully",
  "data": {
    "kycStatus": "in_progress",
    "kycData": { /* ... */ }
  }
}
```

---

#### **GET /balance**
Get user's current balances.

```bash
curl -X GET http://localhost:4000/api/user/balance \
  -H "Authorization: Bearer {token}"
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "upiBalance": 45000,
    "cryptoBalanceInr": 797500,
    "portfolioValue": 842500,
    "details": {
      "eth": {
        "amount": "0.25",
        "valueInr": 597500
      },
      "matic": {
        "amount": "500",
        "valueInr": 200000
      }
    }
  }
}
```

---

### **Products** (`/api/products`)

#### **GET /** (List Products)
Get all products with pagination.

```bash
curl -X GET 'http://localhost:4000/api/products?page=1&limit=20&category=Electronics' \
  -H "Authorization: Bearer {token}"
```

**Query Parameters:**
- `page` (default: 1) — Page number
- `limit` (default: 20) — Items per page
- `category` — Filter by category
- `search` — Search by name
- `sortBy` — Sort field (price, name, createdAt)
- `sortOrder` — `asc` or `desc`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "_id": "607f1f77bcf86cd799439012",
        "name": "iPhone 15 Pro",
        "barcode": "123456789012",
        "price": 99999,
        "category": "Electronics",
        "inStock": true,
        "quantity": 45,
        "imageUrl": "https://example.com/iphone.jpg"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 95,
      "limit": 20
    }
  }
}
```

---

#### **GET /barcode/:barcode**
Search product by barcode.

```bash
curl -X GET http://localhost:4000/api/products/barcode/123456789012 \
  -H "Authorization: Bearer {token}"
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "607f1f77bcf86cd799439012",
    "name": "iPhone 15 Pro",
    "barcode": "123456789012",
    "price": 99999,
    "category": "Electronics",
    "description": "Latest iPhone with advanced features",
    "inStock": true,
    "quantity": 45
  }
}
```

---

#### **POST /** (Create Product)
Create a new product (admin only).

```bash
curl -X POST http://localhost:4000/api/products \
  -H "Authorization: Bearer {admin_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Samsung Galaxy S24",
    "description": "Flagship Android phone",
    "price": 79999,
    "barcode": "987654321098",
    "category": "Electronics",
    "quantity": 30,
    "costPrice": 60000
  }'
```

**Response (201):**
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "_id": "607f1f77bcf86cd799439013",
    "name": "Samsung Galaxy S24",
    "barcode": "987654321098",
    "price": 79999,
    "category": "Electronics"
  }
}
```

---

### **Cart** (`/api/cart`)

#### **GET /**
Get current user's cart.

```bash
curl -X GET http://localhost:4000/api/cart \
  -H "Authorization: Bearer {token}"
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "607f1f77bcf86cd799439014",
    "userId": "607f1f77bcf86cd799439011",
    "items": [
      {
        "productId": "607f1f77bcf86cd799439012",
        "productName": "iPhone 15 Pro",
        "quantity": 2,
        "price": 99999,
        "totalPrice": 199998,
        "addedAt": "2026-03-28T10:30:00Z"
      }
    ],
    "total": 199998
  }
}
```

---

#### **POST /add**
Add item to cart.

```bash
curl -X POST http://localhost:4000/api/cart/add \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "607f1f77bcf86cd799439012",
    "quantity": 2
  }'
```

**Response (200):**
```json
{
  "success": true,
  "message": "Item added to cart",
  "data": {
    "cart": { /* ... */ }
  }
}
```

---

#### **PUT /update**
Update item quantity in cart.

```bash
curl -X PUT http://localhost:4000/api/cart/update \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "607f1f77bcf86cd799439012",
    "quantity": 5
  }'
```

---

#### **DELETE /remove**
Remove item from cart.

```bash
curl -X DELETE http://localhost:4000/api/cart/remove \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"productId": "607f1f77bcf86cd799439012"}'
```

---

#### **DELETE /clear**
Empty the entire cart.

```bash
curl -X DELETE http://localhost:4000/api/cart/clear \
  -H "Authorization: Bearer {token}"
```

---

### **Payments** (`/api/payments`)

#### **POST /create-order**
Create a Razorpay order for UPI payment.

```bash
curl -X POST http://localhost:4000/api/payments/create-order \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 199998,
    "currency": "INR",
    "items": [
      {"productId": "607f1f77bcf86cd799439012", "quantity": 2}
    ]
  }'
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "orderId": "order_N9wHfpLB9xb8aM",
    "amount": 199998,
    "currency": "INR",
    "razorpayKey": "rzp_live_AbCdEfGhIjKlMnOp"
  }
}
```

---

#### **POST /verify**
Verify Razorpay payment and record transaction.

```bash
curl -X POST http://localhost:4000/api/payments/verify \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "pay_N9wHj4J0l7a9xB",
    "order_id": "order_N9wHfpLB9xb8aM",
    "signature": "9ef4dffbfd84f1318f6739a3ce19f9d85851857ae648f114332d8401e0949a3d"
  }'
```

**Response (200):**
```json
{
  "success": true,
  "message": "Payment verified and recorded",
  "data": {
    "transactionId": "txn_607f1f77bcf86cd799439015",
    "status": "completed",
    "amount": 199998,
    "razorpayPaymentId": "pay_N9wHj4J0l7a9xB"
  }
}
```

---

#### **POST /crypto**
Process cryptocurrency payment.

```bash
curl -X POST http://localhost:4000/api/payments/crypto \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 199998,
    "currency": "INR",
    "cryptoType": "ETH",
    "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f76bC4"
  }'
```

---

### **Transactions** (`/api/transactions`)

#### **GET /**
Get user's transaction history.

```bash
curl -X GET 'http://localhost:4000/api/transactions?type=upi&page=1&limit=20' \
  -H "Authorization: Bearer {token}"
```

**Query Parameters:**
- `type` — `upi`, `crypto`, or `all`
- `status` — `completed`, `pending`, `failed`
- `startDate` — ISO date string
- `endDate` — ISO date string
- `page` — Page number
- `limit` — Items per page

**Response (200):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "_id": "607f1f77bcf86cd799439015",
        "amount": 199998,
        "currency": "INR",
        "type": "upi",
        "status": "completed",
        "items": [ /* ... */ ],
        "createdAt": "2026-03-28T10:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 52
    }
  }
}
```

---

#### **GET /stats**
Get transaction statistics.

```bash
curl -X GET 'http://localhost:4000/api/transactions/stats?period=month' \
  -H "Authorization: Bearer {token}"
```

**Query Parameters:**
- `period` — `day`, `week`, `month`, `year`, `all`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "period": "month",
    "totalTransactions": 45,
    "totalAmount": 2450000,
    "avgAmount": 54444,
    "byType": {
      "upi": { "count": 32, "amount": 1680000 },
      "crypto": { "count": 13, "amount": 770000 }
    },
    "byStatus": {
      "completed": { "count": 44, "amount": 2400000 },
      "pending": { "count": 1, "amount": 50000 },
      "failed": { "count": 0, "amount": 0 }
    }
  }
}
```

---

### **Wallet** (`/api/wallet`)

#### **GET /address**
Get user's saved crypto wallet address.

```bash
curl -X GET http://localhost:4000/api/wallet/address \
  -H "Authorization: Bearer {token}"
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f76bC4",
    "chainId": 1,
    "chain": "ethereum"
  }
}
```

---

#### **POST /save**
Save or update wallet address.

```bash
curl -X POST http://localhost:4000/api/wallet/save \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f76bC4",
    "chain": "ethereum"
  }'
```

**Response (200):**
```json
{
  "success": true,
  "message": "Wallet address saved",
  "data": {
    "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f76bC4"
  }
}
```

---

## 🔐 **Authentication & Security**

### **JWT Token Structure**
```
Header:       { "alg": "HS256", "typ": "JWT" }
Payload:      { "userId": "...", "iat": 1234567890, "exp": 1234654290 }
Signature:    HMACSHA256(header.payload, SECRET)
```

### **Bearer Token Usage**
All authenticated endpoints require:
```
Authorization: Bearer {jwt_token}
```

### **Password Security**
- Passwords hashed with **bcryptjs** (10 rounds)
- Minimum 4 characters required
- Never stored in plain text
- **Never sent back** in API responses

### **Token Expiration**
- Access token: 7 days
- Refresh token: 30 days
- Use `/api/auth/refresh` to get new access token

---

## ⚠️ **Error Handling**

### **Response Format**
All errors follow standard format:
```json
{
  "success": false,
  "message": "User-friendly error message",
  "error": {
    "code": "ERROR_CODE",
    "details": "Technical details"
  }
}
```

### **Common HTTP Status Codes**
| Code | Meaning | Example |
|------|---------|---------|
| 200 | ✅ Success | GET request successful |
| 201 | ✅ Created | POST resource created |
| 400 | ❌ Bad Request | Invalid input data |
| 401 | ❌ Unauthorized | Missing/invalid token |
| 403 | ❌ Forbidden | Insufficient permissions |
| 404 | ❌ Not Found | Resource doesn't exist |
| 409 | ❌ Conflict | Duplicate phone/email |
| 422 | ❌ Unprocessable | Validation error |
| 500 | ❌ Server Error | Internal error |

### **Error Examples**

**Invalid Phone:**
```json
{
  "success": false,
  "message": "Phone must be 10 digits",
  "error": {
    "code": "INVALID_PHONE",
    "details": "Phone format: 10 digit number"
  }
}
```

**Unauthorized:**
```json
{
  "success": false,
  "message": "Unauthorized access",
  "error": {
    "code": "NO_TOKEN",
    "details": "Missing Authorization header"
  }
}
```

**Insufficient Balance:**
```json
{
  "success": false,
  "message": "Insufficient balance",
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "required": 50000,
    "available": 35000
  }
}
```

---

## 🚀 **Deployment**

### **Production Checklist**
- [ ] All environment variables set in production
- [ ] JWT_SECRET is strong (32+ characters)
- [ ] MongoDB connected via Atlas with proper credentials
- [ ] Razorpay production keys configured
- [ ] CORS origin set to frontend domain only
- [ ] Error logging configured
- [ ] SSL/TLS enabled on backend
- [ ] Database backups configured
- [ ] Rate limiting enabled
- [ ] Input validation on all endpoints

### **Deploy on Heroku**
```bash
# Install Heroku CLI
npm install -g heroku

# Login to Heroku
heroku login

# Create app
heroku create kryptokart-api

# Set environment variables
heroku config:set PORT=$PORT
heroku config:set MONGODB_URI=$(cat .env | grep MONGODB_URI | cut -d '=' -f2)
heroku config:set JWT_SECRET=$(cat .env | grep JWT_SECRET | cut -d '=' -f2)
# ... set all other variables

# Deploy
git push heroku main

# View logs
heroku logs --tail
```

### **Deploy on AWS (EC2)**
```bash
# SSH into instance
ssh -i key.pem ec2-user@instance-ip

# Install Node
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Clone repo
git clone <repo-url>
cd backend

# Install & start with PM2
npm install -g pm2
npm install
pm2 start server.js --name "kryptokart-api"
pm2 startup
pm2 save

# Install Nginx reverse proxy
sudo yum install -y nginx
# Configure nginx to proxy to port 4000
```

### **Scaling Considerations**
1. **Horizontal Scaling**: Use load balancer (AWS ALB, Nginx)
2. **Database**: Use MongoDB Atlas with auto-scaling
3. **Caching**: Redis for session/token caching
4. **CDN**: CloudFront for static assets
5. **Monitoring**: New Relic, DataDog, or CloudWatch

---

## 📊 **Monitoring & Logs**

### **Enable Morgan Logging**
Already configured in `server.js`:
```javascript
app.use(morgan('dev'));  // Development
app.use(morgan('combined'));  // Production
```

### **Application Logs**
```bash
# View logs
tail -f logs/app.log

# Rotate logs (optional)
npm install --save-dev logrotate
```

---

## 🧪 **Testing**

### **Unit Tests (Jest)**
```bash
npm install --save-dev jest supertest

npm test
```

### **API Tests (cURL)**
See individual endpoint sections above for curl examples.

### **Load Testing (Artillery)**
```bash
npm install -g artillery

artillery quick --count 100 --num 10 http://localhost:4000/health
```

---

## 📝 **Changelog**

### **Version 1.0.0** (March 2026)
- ✅ Initial release
- ✅ Complete API implementation
- ✅ Razorpay integration
- ✅ Crypto payment support
- ✅ JWT authentication
- ✅ KYC workflow
- ✅ Transaction tracking

---

## 🆘 **Troubleshooting**

### **MongoDB Connection Error**
```
ERROR: connect ECONNREFUSED 127.0.0.1:27017
```

**Fix:**
```bash
# Start MongoDB
mongod --dbpath ./data

# Or use Atlas
# Update .env: MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/kryptokart
```

### **Port 4000 Already in Use**
```
ERROR: listen EADDRINUSE: address already in use :::4000
```

**Fix:**
```bash
npx kill-port 4000
# Or change PORT in .env
```

### **JWT Token Expired**
```
ERROR: jwt expired
```

**Fix:**
- Call `POST /api/auth/refresh` with valid refresh token
- Frontend automatically handles token refresh

---

## 📞 **Support & Contact**

- 📧 Backend Team: backend@kryptokart.app
- 🐛 Issue Tracker: GitHub Issues
- 📚 Docs: [API Documentation](README_COMPREHENSIVE.md)
- 🔧 Environment Help: [Setup Guide](#environment-configuration)

---

**Last Updated:** March 28, 2026  
**Maintainer:** KryptoKart Team  
**Status:** Production Ready ✅