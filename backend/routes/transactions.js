const express = require('express');
const auth = require('../middleware/auth');
const Transaction = require('../models/Transaction');

const router = express.Router();

// GET /api/transactions
router.get('/', auth, async (req, res) => {
  try {
    const { type, status, limit = 50, skip = 0 } = req.query;
    const query = { userId: req.userId };

    if (type && type !== 'all') query.type = type;
    if (status) query.status = status;

    const transactions = await Transaction.find(query)
      .sort({ createdAt: -1 })
      .skip(Number(skip))
      .limit(Number(limit));

    const total = await Transaction.countDocuments(query);

    res.json({ transactions, total });
  } catch (error) {
    console.error('[transactions/list] error', error);
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

// GET /api/transactions/stats
router.get('/stats', auth, async (req, res) => {
  try {
    const userId = req.userId;

    const stats = await Transaction.aggregate([
      { $match: { userId, status: 'success' } },
      {
        $group: {
          _id: null,
          totalSent: {
            $sum: { $cond: [{ $gt: ['$amountInr', 0] }, '$amountInr', 0] },
          },
          totalReceived: {
            $sum: { $cond: [{ $lt: ['$amountInr', 0] }, { $abs: '$amountInr' }, 0] },
          },
          count: { $sum: 1 },
        },
      },
    ]);

    res.json({
      totalSent: stats[0]?.totalSent || 0,
      totalReceived: stats[0]?.totalReceived || 0,
      count: stats[0]?.count || 0,
    });
  } catch (error) {
    console.error('[transactions/stats] error', error);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

// GET /api/transactions/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const transaction = await Transaction.findOne({
      _id: req.params.id,
      userId: req.userId,
    });

    if (!transaction) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    res.json({ transaction });
  } catch (error) {
    console.error('[transactions/get] error', error);
    res.status(500).json({ error: 'Failed to fetch transaction' });
  }
});

// POST /api/transactions
router.post('/', auth, async (req, res) => {
  try {
    const {
      txnId,
      type,
      amountInr,
      cryptoCoin,
      cryptoAmount,
      recipientName,
      recipientAddress,
      status,
      txnHash,
      itemIds,
      networkFee,
      razorpayOrderId,
      razorpayPaymentId,
    } = req.body;

    if (!txnId || !type || amountInr === undefined || !recipientName) {
      return res.status(400).json({ error: 'txnId, type, amountInr, and recipientName are required' });
    }

    const transaction = new Transaction({
      userId: req.userId,
      txnId,
      type,
      amountInr,
      cryptoCoin,
      cryptoAmount,
      recipientName,
      recipientAddress: recipientAddress || '',
      status: status || 'success',
      txnHash,
      itemIds: itemIds || [],
      networkFee: networkFee || 0,
      razorpayOrderId,
      razorpayPaymentId,
    });

    await transaction.save();

    console.log('[transactions/create] success', { txnId, type, amountInr });

    res.status(201).json({ transaction });
  } catch (error) {
    console.error('[transactions/create] error', error);
    res.status(500).json({ error: 'Failed to create transaction' });
  }
});

module.exports = router;
