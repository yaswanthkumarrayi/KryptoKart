const express = require('express');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /api/user/profile
router.get('/profile', auth, async (req, res) => {
  try {
    res.json({ user: req.user.toJSON() });
  } catch (error) {
    console.error('[user/profile] error', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// PUT /api/user/profile
router.put('/profile', auth, async (req, res) => {
  try {
    const { name, upiId, walletAddress, avatarUrl } = req.body;
    const user = req.user;

    if (name) user.name = name;
    if (upiId !== undefined) user.upiId = upiId;
    if (walletAddress !== undefined) user.walletAddress = walletAddress;
    if (avatarUrl !== undefined) user.avatarUrl = avatarUrl;

    await user.save();

    res.json({ user: user.toJSON() });
  } catch (error) {
    console.error('[user/profile update] error', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// PUT /api/user/kyc
router.put('/kyc', auth, async (req, res) => {
  try {
    const { pan, aadhaar, dob, bankName, accountNumber, ifsc, accountHolderName, step } = req.body;
    const user = req.user;

    if (pan !== undefined) user.kycData.pan = pan;
    if (aadhaar !== undefined) user.kycData.aadhaar = aadhaar;
    if (dob !== undefined) user.kycData.dob = dob;
    if (bankName !== undefined) user.kycData.bankName = bankName;
    if (accountNumber !== undefined) user.kycData.accountNumber = accountNumber;
    if (ifsc !== undefined) user.kycData.ifsc = ifsc;
    if (accountHolderName !== undefined) user.kycData.accountHolderName = accountHolderName;

    // Update KYC status based on step
    if (step === 3) {
      user.kycStatus = 'verified';
    } else if (step >= 1) {
      user.kycStatus = 'in_progress';
    }

    await user.save();

    res.json({ user: user.toJSON() });
  } catch (error) {
    console.error('[user/kyc] error', error);
    res.status(500).json({ error: 'Failed to update KYC' });
  }
});

// PUT /api/user/balance
router.put('/balance', auth, async (req, res) => {
  try {
    const { portfolioValue, cryptoBalanceInr, upiBalance } = req.body;
    const user = req.user;

    if (portfolioValue !== undefined) user.portfolioValue = portfolioValue;
    if (cryptoBalanceInr !== undefined) user.cryptoBalanceInr = cryptoBalanceInr;
    if (upiBalance !== undefined) user.upiBalance = upiBalance;

    await user.save();

    res.json({ user: user.toJSON() });
  } catch (error) {
    console.error('[user/balance] error', error);
    res.status(500).json({ error: 'Failed to update balance' });
  }
});

module.exports = router;
