const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: 2,
    maxlength: 100,
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    unique: true,
    match: [/^[0-9]{10}$/, 'Phone must be 10 digits'],
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: 4,
  },
  upiId: {
    type: String,
    default: '',
    trim: true,
  },
  walletAddress: {
    type: String,
    default: '',
    trim: true,
  },
  kycStatus: {
    type: String,
    enum: ['pending', 'in_progress', 'verified'],
    default: 'pending',
  },
  kycData: {
    pan: { type: String, default: '' },
    aadhaar: { type: String, default: '' },
    dob: { type: String, default: '' },
    bankName: { type: String, default: '' },
    accountNumber: { type: String, default: '' },
    ifsc: { type: String, default: '' },
    accountHolderName: { type: String, default: '' },
  },
  portfolioValue: {
    type: Number,
    default: 842500.0,
  },
  cryptoBalanceInr: {
    type: Number,
    default: 797500.0,
  },
  upiBalance: {
    type: Number,
    default: 45000.0,
  },
  avatarUrl: {
    type: String,
    default: '',
  },
}, {
  timestamps: true,
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Remove password from JSON output
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  delete user.password;
  return user;
};

module.exports = mongoose.model('User', userSchema);
