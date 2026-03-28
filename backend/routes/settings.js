const express = require('express');
const auth = require('../middleware/auth');
const Settings = require('../models/Settings');

const router = express.Router();

// GET /api/settings
router.get('/', auth, async (req, res) => {
  try {
    let settings = await Settings.findOne({ userId: req.userId });
    if (!settings) {
      settings = await Settings.create({ userId: req.userId });
    }
    res.json({ settings });
  } catch (error) {
    console.error('[settings/get] error', error);
    res.status(500).json({ error: 'Failed to fetch settings' });
  }
});

// PUT /api/settings
router.put('/', auth, async (req, res) => {
  try {
    const updates = {};
    const allowed = ['theme', 'biometricEnabled', 'autoLockMinutes', 'paymentAlerts', 'priceAlerts', 'printerAddress'];

    for (const key of allowed) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }

    let settings = await Settings.findOneAndUpdate(
      { userId: req.userId },
      { $set: updates },
      { new: true, upsert: true }
    );

    res.json({ settings });
  } catch (error) {
    console.error('[settings/update] error', error);
    res.status(500).json({ error: 'Failed to update settings' });
  }
});

module.exports = router;
