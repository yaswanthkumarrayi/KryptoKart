const express = require('express');
const auth = require('../middleware/auth');
const Cart = require('../models/Cart');

const router = express.Router();

// GET /api/cart
router.get('/', auth, async (req, res) => {
  try {
    let cart = await Cart.findOne({ userId: req.userId }).populate('items.productId');
    if (!cart) {
      cart = await Cart.create({ userId: req.userId, items: [] });
    }
    res.json({ cart });
  } catch (error) {
    console.error('[cart/get] error', error);
    res.status(500).json({ error: 'Failed to fetch cart' });
  }
});

// POST /api/cart/add
router.post('/add', auth, async (req, res) => {
  try {
    const { productId, quantity = 1 } = req.body;

    if (!productId) {
      return res.status(400).json({ error: 'productId is required' });
    }

    let cart = await Cart.findOne({ userId: req.userId });
    if (!cart) {
      cart = new Cart({ userId: req.userId, items: [] });
    }

    const existingItem = cart.items.find(
      (item) => item.productId.toString() === productId
    );

    if (existingItem) {
      existingItem.quantity += quantity;
    } else {
      cart.items.push({ productId, quantity });
    }

    await cart.save();
    cart = await Cart.findById(cart._id).populate('items.productId');

    res.json({ cart });
  } catch (error) {
    console.error('[cart/add] error', error);
    res.status(500).json({ error: 'Failed to add to cart' });
  }
});

// POST /api/cart/update
router.post('/update', auth, async (req, res) => {
  try {
    const { productId, quantity } = req.body;

    if (!productId || quantity === undefined) {
      return res.status(400).json({ error: 'productId and quantity are required' });
    }

    const cart = await Cart.findOne({ userId: req.userId });
    if (!cart) {
      return res.status(404).json({ error: 'Cart not found' });
    }

    if (quantity <= 0) {
      cart.items = cart.items.filter(
        (item) => item.productId.toString() !== productId
      );
    } else {
      const item = cart.items.find(
        (item) => item.productId.toString() === productId
      );
      if (item) {
        item.quantity = quantity;
      }
    }

    await cart.save();
    const populated = await Cart.findById(cart._id).populate('items.productId');

    res.json({ cart: populated });
  } catch (error) {
    console.error('[cart/update] error', error);
    res.status(500).json({ error: 'Failed to update cart' });
  }
});

// POST /api/cart/remove
router.post('/remove', auth, async (req, res) => {
  try {
    const { productId } = req.body;

    if (!productId) {
      return res.status(400).json({ error: 'productId is required' });
    }

    const cart = await Cart.findOne({ userId: req.userId });
    if (!cart) {
      return res.status(404).json({ error: 'Cart not found' });
    }

    cart.items = cart.items.filter(
      (item) => item.productId.toString() !== productId
    );

    await cart.save();
    const populated = await Cart.findById(cart._id).populate('items.productId');

    res.json({ cart: populated });
  } catch (error) {
    console.error('[cart/remove] error', error);
    res.status(500).json({ error: 'Failed to remove from cart' });
  }
});

// DELETE /api/cart/clear
router.delete('/clear', auth, async (req, res) => {
  try {
    const cart = await Cart.findOne({ userId: req.userId });
    if (cart) {
      cart.items = [];
      await cart.save();
    }

    res.json({ message: 'Cart cleared' });
  } catch (error) {
    console.error('[cart/clear] error', error);
    res.status(500).json({ error: 'Failed to clear cart' });
  }
});

module.exports = router;
