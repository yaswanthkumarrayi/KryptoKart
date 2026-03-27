const express = require('express');
const crypto = require('crypto');
const auth = require('../middleware/auth');
const Razorpay = require('razorpay');

const router = express.Router();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// POST /api/payments/create-order
router.post('/create-order', auth, async (req, res) => {
  try {
    const amount = Number(req.body?.amount);
    const currency = (req.body?.currency || 'INR').toString().trim().toUpperCase();

    if (!Number.isInteger(amount) || amount <= 0) {
      return res.status(400).json({ error: 'amount must be a positive integer (paise).' });
    }

    const order = await razorpay.orders.create({
      amount,
      currency,
      receipt: `kk_${req.userId}_${Date.now()}`,
      payment_capture: 1,
    });

    console.log('[payments/create-order] success', {
      orderId: order.id,
      amount: order.amount,
    });

    res.json({
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
      key_id: process.env.RAZORPAY_KEY_ID,
    });
  } catch (error) {
    console.error('[payments/create-order] error', error);
    res.status(500).json({ error: 'Unable to create order.' });
  }
});

// POST /api/payments/verify
router.post('/verify', auth, async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({ error: 'Missing verification fields.' });
    }

    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    const verified = expectedSignature === razorpay_signature;

    console.log('[payments/verify]', {
      razorpay_order_id,
      razorpay_payment_id,
      verified,
    });

    if (!verified) {
      return res.status(400).json({ verified: false, error: 'Invalid signature.' });
    }

    res.json({ verified: true });
  } catch (error) {
    console.error('[payments/verify] error', error);
    res.status(500).json({ verified: false, error: 'Verification failed.' });
  }
});

module.exports = router;
