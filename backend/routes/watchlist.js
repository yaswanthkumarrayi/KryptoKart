const express = require('express');
const auth = require('../middleware/auth');
const Watchlist = require('../models/Watchlist');

const router = express.Router();

// GET /api/watchlist
router.get('/', auth, async (req, res) => {
  try {
    let watchlist = await Watchlist.findOne({ userId: req.userId });
    if (!watchlist) {
      watchlist = await Watchlist.create({ userId: req.userId, coinIds: [] });
    }
    res.json({ coinIds: watchlist.coinIds });
  } catch (error) {
    console.error('[watchlist/get] error', error);
    res.status(500).json({ error: 'Failed to fetch watchlist' });
  }
});

// POST /api/watchlist/toggle
router.post('/toggle', auth, async (req, res) => {
  try {
    const { coinId } = req.body;

    if (!coinId) {
      return res.status(400).json({ error: 'coinId is required' });
    }

    let watchlist = await Watchlist.findOne({ userId: req.userId });
    if (!watchlist) {
      watchlist = new Watchlist({ userId: req.userId, coinIds: [] });
    }

    const index = watchlist.coinIds.indexOf(coinId);
    if (index > -1) {
      watchlist.coinIds.splice(index, 1);
    } else {
      watchlist.coinIds.push(coinId);
    }

    await watchlist.save();

    res.json({ coinIds: watchlist.coinIds, added: index === -1 });
  } catch (error) {
    console.error('[watchlist/toggle] error', error);
    res.status(500).json({ error: 'Failed to toggle watchlist' });
  }
});

module.exports = router;
