/**
 * Wallet Routes — wallet→UPI mapping for KryptoKart.
 * After MetaMask connection, the real wallet address is saved to the user's
 * profile. When a UPI QR is scanned and Crypto is chosen, we look up the
 * UPI ID mapped to the scanned merchant's wallet address.
 *
 * For the demo, we keep a static map plus dynamically map any user's
 * wallet to their own registered UPI ID.
 */
const express = require('express');
const auth = require('../middleware/auth');
const User = require('../models/User');

const router = express.Router();

// ──────────────────────────────────────────────────────────────
// Static demo wallet → UPI mapping (extended at runtime)
// ──────────────────────────────────────────────────────────────
const STATIC_WALLET_UPI_MAP = {
  '0x742d35cc6634c0532925a3b844bc9e7595f2bd38': '9876543210@kryptokart',
  '0xab5801a7d398351b8be11c439e05c5b3259aec9b': 'alex.miller@upi',
  '0x1234567890abcdef1234567890abcdef12345678': 'sarah.chen@upi',
};

/**
 * GET /api/wallet/upi-mapping/:address
 * Returns the UPI ID mapped to a given wallet address.
 * First checks the static map, then looks up the database for a user
 * with that wallet address and returns their UPI ID.
 */
router.get('/upi-mapping/:address', auth, async (req, res) => {
  try {
    const address = (req.params.address || '').toLowerCase().trim();

    if (!address || !address.startsWith('0x')) {
      return res.status(400).json({ error: 'Invalid wallet address' });
    }

    // 1. Check static map
    let upiId = STATIC_WALLET_UPI_MAP[address];
    let source = 'hardcoded';

    // 2. If not in static map, look up any user with this wallet address
    if (!upiId) {
      const user = await User.findOne({
        walletAddress: { $regex: new RegExp(`^${address}$`, 'i') }
      });
      if (user && user.upiId) {
        upiId = user.upiId;
        source = 'database';
      } else {
        // 3. Fallback — generate from address prefix
        upiId = `${address.slice(2, 10)}@kryptokart`;
        source = 'generated';
      }
    }

    console.log('[wallet/upi-mapping]', { address, upiId, source });

    res.json({ address, upiId, source });
  } catch (error) {
    console.error('[wallet/upi-mapping] error', error);
    res.status(500).json({ error: 'Failed to fetch UPI mapping' });
  }
});

/**
 * GET /api/wallet/address
 * Returns the currently connected wallet address for the authenticated user,
 * plus the UPI mapping for that address.
 */
router.get('/address', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    const address = user?.walletAddress || '';
    let upiId = '';

    if (address) {
      const lower = address.toLowerCase();
      upiId = STATIC_WALLET_UPI_MAP[lower] || user?.upiId || `${lower.slice(2, 10)}@kryptokart`;
    }

    res.json({ address, upiId });
  } catch (error) {
    console.error('[wallet/address] error', error);
    res.status(500).json({ error: 'Failed to fetch wallet address' });
  }
});

/**
 * PUT /api/wallet/save
 * Save a wallet address to the authenticated user's profile.
 * This is called after MetaMask connection.
 */
router.put('/save', auth, async (req, res) => {
  try {
    const { walletAddress } = req.body;

    if (!walletAddress) {
      return res.status(400).json({ error: 'walletAddress is required' });
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { walletAddress },
      { new: true }
    );

    console.log('[wallet/save]', { userId: user._id, walletAddress });

    res.json({ user: user.toJSON() });
  } catch (error) {
    console.error('[wallet/save] error', error);
    res.status(500).json({ error: 'Failed to save wallet address' });
  }
});

module.exports = router;
