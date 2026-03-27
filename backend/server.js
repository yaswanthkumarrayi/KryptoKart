require('dotenv').config();

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const Razorpay = require('razorpay');

const app = express();

app.use(express.json({ limit: '1mb' }));
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || '*',
  })
);
app.use(morgan('dev'));

const {
  PORT = 4000,
  RAZORPAY_KEY_ID,
  RAZORPAY_KEY_SECRET,
} = process.env;

if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
  console.error('Missing Razorpay credentials in environment variables.');
  process.exit(1);
}

const razorpay = new Razorpay({
  key_id: RAZORPAY_KEY_ID,
  key_secret: RAZORPAY_KEY_SECRET,
});

function isPositiveInteger(value) {
  return Number.isInteger(value) && value > 0;
}

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.post('/create-order', async (req, res) => {
  try {
    const amount = Number(req.body?.amount);
    const currency = (req.body?.currency || 'INR').toString().trim().toUpperCase();

    if (!isPositiveInteger(amount)) {
      return res.status(400).json({ error: 'amount must be a positive integer (paise).' });
    }
    if (!/^[A-Z]{3}$/.test(currency)) {
      return res.status(400).json({ error: 'currency must be a 3-letter code.' });
    }

    const order = await razorpay.orders.create({
      amount,
      currency,
      receipt: `kk_${Date.now()}`,
      payment_capture: 1,
    });

    console.log('[create-order] success', {
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
    });

    return res.json({
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
    });
  } catch (error) {
    console.error('[create-order] error', error);
    return res.status(500).json({ error: 'Unable to create order.' });
  }
});

app.post('/verify-payment', (req, res) => {
  try {
    const razorpayOrderId = req.body?.razorpay_order_id;
    const razorpayPaymentId = req.body?.razorpay_payment_id;
    const razorpaySignature = req.body?.razorpay_signature;

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({ error: 'Missing verification fields.' });
    }

    const expectedSignature = crypto
      .createHmac('sha256', RAZORPAY_KEY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    const verified = expectedSignature === razorpaySignature;

    console.log('[verify-payment]', {
      razorpayOrderId,
      razorpayPaymentId,
      verified,
    });

    if (!verified) {
      return res.status(400).json({ verified: false, error: 'Invalid signature.' });
    }

    // Mark payment successful in DB here in real systems.
    return res.json({ verified: true });
  } catch (error) {
    console.error('[verify-payment] error', error);
    return res.status(500).json({ verified: false, error: 'Verification failed.' });
  }
});

app.listen(PORT, () => {
  console.log(`Razorpay backend running on port ${PORT}`);
});
