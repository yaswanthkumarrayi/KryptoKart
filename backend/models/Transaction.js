const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  txnId: {
    type: String,
    required: true,
    unique: true,
  },
  type: {
    type: String,
    enum: ['upi', 'crypto', 'shopping'],
    required: true,
  },
  amountInr: {
    type: Number,
    required: true,
  },
  cryptoCoin: {
    type: String,
    default: null,
  },
  cryptoAmount: {
    type: Number,
    default: null,
  },
  recipientName: {
    type: String,
    required: true,
  },
  recipientAddress: {
    type: String,
    default: '',
  },
  status: {
    type: String,
    enum: ['success', 'failed', 'pending'],
    default: 'pending',
  },
  txnHash: {
    type: String,
    default: null,
  },
  itemIds: {
    type: [String],
    default: [],
  },
  networkFee: {
    type: Number,
    default: 0,
  },
  razorpayOrderId: {
    type: String,
    default: null,
  },
  razorpayPaymentId: {
    type: String,
    default: null,
  },
}, {
  timestamps: true,
});

// Index for faster queries
transactionSchema.index({ userId: 1, createdAt: -1 });
transactionSchema.index({ type: 1 });

module.exports = mongoose.model('Transaction', transactionSchema);
