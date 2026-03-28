const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
  },
  theme: {
    type: String,
    enum: ['dark', 'light'],
    default: 'dark',
  },
  biometricEnabled: {
    type: Boolean,
    default: false,
  },
  autoLockMinutes: {
    type: Number,
    default: 5,
  },
  paymentAlerts: {
    type: Boolean,
    default: true,
  },
  priceAlerts: {
    type: Boolean,
    default: true,
  },
  printerAddress: {
    type: String,
    default: '',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Settings', settingsSchema);
