const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Settings = require('../models/Settings');
const Watchlist = require('../models/Watchlist');
const Cart = require('../models/Cart');

const router = express.Router();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { name, phone, password, upiId, walletAddress } = req.body;

    if (!name || !phone || !password) {
      return res.status(400).json({ error: 'Name, phone, and password are required' });
    }

    if (!/^[0-9]{10}$/.test(phone)) {
      return res.status(400).json({ error: 'Phone must be 10 digits' });
    }

    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return res.status(409).json({ error: 'Phone number already registered' });
    }

    const user = new User({
      name,
      phone,
      password,
      upiId: upiId || `${phone}@kryptokart`,
      walletAddress: walletAddress || '',
    });

    await user.save();

    // Create default settings, watchlist, and cart
    await Settings.create({ userId: user._id });
    await Watchlist.create({ userId: user._id, coinIds: ['bitcoin', 'ethereum'] });
    await Cart.create({ userId: user._id, items: [] });

    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log('[auth/register] success', { userId: user._id, phone });

    res.status(201).json({
      token,
      user: user.toJSON(),
    });
  } catch (error) {
    console.error('[auth/register] error', error);
    if (error.code === 11000) {
      return res.status(409).json({ error: 'Phone number already registered' });
    }
    res.status(500).json({ error: 'Registration failed' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const startTime = Date.now();
    const { phone, password } = req.body;
    console.log('[auth/login] request received', { phone });

    if (!phone || !password) {
      return res.status(400).json({ error: 'Phone and password are required' });
    }

    const dbQueryStart = Date.now();
    const user = await User.findOne({ phone });
    console.log(`[auth/login] DB query time: ${Date.now() - dbQueryStart}ms`);
    
    if (!user) {
      return res.status(401).json({ error: 'Invalid phone or password' });
    }

    const passwordCheckStart = Date.now();
    const isMatch = await user.comparePassword(password);
    console.log(`[auth/login] Password check time: ${Date.now() - passwordCheckStart}ms`);
    
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid phone or password' });
    }

    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log('[auth/login] success', { userId: user._id, phone, totalTime: `${Date.now() - startTime}ms` });

    res.json({
      token,
      user: user.toJSON(),
    });
  } catch (error) {
    console.error('[auth/login] error', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

module.exports = router;
