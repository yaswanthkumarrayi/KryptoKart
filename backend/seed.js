require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const User = require('./models/User');
const Transaction = require('./models/Transaction');
const Product = require('./models/Product');
const Cart = require('./models/Cart');
const Watchlist = require('./models/Watchlist');
const Settings = require('./models/Settings');

const seed = async () => {
  try {
    await connectDB();
    console.log('🌱 Starting seed...\n');

    // Clear existing data
    await User.deleteMany({});
    await Transaction.deleteMany({});
    await Product.deleteMany({});
    await Cart.deleteMany({});
    await Watchlist.deleteMany({});
    await Settings.deleteMany({});

    // Create demo user
    const user = new User({
      name: 'Yaswa Kumar',
      phone: '9876543210',
      password: '1234',
      upiId: '9876543210@kryptokart',
      walletAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD38',
      kycStatus: 'verified',
      portfolioValue: 842500.0,
      cryptoBalanceInr: 797500.0,
      upiBalance: 45000.0,
    });
    await user.save();
    console.log('✅ Demo user created (phone: 9876543210, pass: 1234)');

    // Create settings
    await Settings.create({ userId: user._id });
    console.log('✅ Settings created');

    // Create watchlist
    await Watchlist.create({
      userId: user._id,
      coinIds: ['bitcoin', 'ethereum', 'solana'],
    });
    console.log('✅ Watchlist created');

    // Create cart
    await Cart.create({ userId: user._id, items: [] });
    console.log('✅ Cart created');

    // Create demo products
    const products = await Product.insertMany([
      { userId: user._id, barcode: '89012345', name: 'Premium Coffee Beans', priceInr: 450, category: 'Beverages' },
      { userId: user._id, barcode: '89012346', name: 'Organic Green Tea', priceInr: 280, category: 'Beverages' },
      { userId: user._id, barcode: '89012347', name: 'Dark Chocolate Bar', priceInr: 150, category: 'Snacks' },
      { userId: user._id, barcode: '89012348', name: 'Wireless Mouse', priceInr: 1200, category: 'Electronics' },
      { userId: user._id, barcode: '89012349', name: 'USB-C Cable', priceInr: 350, category: 'Electronics' },
      { userId: user._id, barcode: '89012350', name: 'Notebook A5', priceInr: 120, category: 'Stationery' },
      { userId: user._id, barcode: '89012351', name: 'Ballpoint Pen Set', priceInr: 80, category: 'Stationery' },
      { userId: user._id, barcode: '89012352', name: 'Hand Sanitizer', priceInr: 99, category: 'Health' },
    ]);
    console.log(`✅ ${products.length} products created`);

    // Create demo transactions
    const now = new Date();
    const txns = await Transaction.insertMany([
      {
        userId: user._id,
        txnId: 'TXN-001-DEMO',
        type: 'upi',
        amountInr: 1250.0,
        recipientName: 'Coffee Shop Express',
        recipientAddress: 'coffeeshop@upi',
        status: 'success',
        createdAt: new Date(now - 2 * 60 * 60 * 1000),
      },
      {
        userId: user._id,
        txnId: 'TXN-002-DEMO',
        type: 'crypto',
        amountInr: 12500.0,
        cryptoCoin: 'ethereum',
        cryptoAmount: 0.052,
        recipientName: 'Alex Miller',
        recipientAddress: '0xAb5801a7D398351b8bE11C439e05C5B3259aec9B',
        status: 'success',
        txnHash: '0x6f7b2c9d8e1a3b5c4d7e9f0a1b2c3d4e5f6a7b8c',
        networkFee: 0.0015,
        createdAt: new Date(now - 5 * 60 * 60 * 1000),
      },
      {
        userId: user._id,
        txnId: 'TXN-003-DEMO',
        type: 'shopping',
        amountInr: 3400.0,
        recipientName: 'KryptoMart Store',
        recipientAddress: 'kryptomart@upi',
        status: 'success',
        itemIds: [products[0]._id.toString(), products[3]._id.toString()],
        createdAt: new Date(now - 24 * 60 * 60 * 1000),
      },
      {
        userId: user._id,
        txnId: 'TXN-004-DEMO',
        type: 'crypto',
        amountInr: 25000.0,
        cryptoCoin: 'bitcoin',
        cryptoAmount: 0.0042,
        recipientName: 'Sarah Chen',
        recipientAddress: '0x1234567890abcdef1234567890abcdef12345678',
        status: 'success',
        txnHash: '0xabc123def456789abc123def456789abc123def4',
        networkFee: 0.0002,
        createdAt: new Date(now - 48 * 60 * 60 * 1000),
      },
      {
        userId: user._id,
        txnId: 'TXN-005-DEMO',
        type: 'upi',
        amountInr: 500.0,
        recipientName: 'Food Corner',
        recipientAddress: 'foodcorner@paytm',
        status: 'success',
        createdAt: new Date(now - 72 * 60 * 60 * 1000),
      },
    ]);
    console.log(`✅ ${txns.length} transactions created`);

    console.log('\n🎉 Seed completed successfully!\n');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seed error:', error);
    process.exit(1);
  }
};

seed();
