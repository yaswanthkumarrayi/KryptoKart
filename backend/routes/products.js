const express = require('express');
const auth = require('../middleware/auth');
const Product = require('../models/Product');

const router = express.Router();

// GET /api/products
router.get('/', auth, async (req, res) => {
  try {
    const { search, category } = req.query;
    const query = { userId: req.userId };

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { barcode: { $regex: search, $options: 'i' } },
      ];
    }
    if (category) query.category = category;

    const products = await Product.find(query).sort({ name: 1 });
    res.json({ products });
  } catch (error) {
    console.error('[products/list] error', error);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// GET /api/products/barcode/:barcode
router.get('/barcode/:barcode', auth, async (req, res) => {
  try {
    const product = await Product.findOne({
      userId: req.userId,
      barcode: req.params.barcode,
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ product });
  } catch (error) {
    console.error('[products/barcode] error', error);
    res.status(500).json({ error: 'Failed to fetch product' });
  }
});

// POST /api/products
router.post('/', auth, async (req, res) => {
  try {
    const { barcode, name, priceInr, imageUrl, category } = req.body;

    if (!barcode || !name || priceInr === undefined) {
      return res.status(400).json({ error: 'barcode, name, and priceInr are required' });
    }

    const product = new Product({
      userId: req.userId,
      barcode,
      name,
      priceInr,
      imageUrl: imageUrl || '',
      category: category || 'General',
    });

    await product.save();

    res.status(201).json({ product });
  } catch (error) {
    console.error('[products/create] error', error);
    if (error.code === 11000) {
      return res.status(409).json({ error: 'Product with this barcode already exists' });
    }
    res.status(500).json({ error: 'Failed to create product' });
  }
});

// PUT /api/products/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const { name, priceInr, imageUrl, category } = req.body;

    const product = await Product.findOneAndUpdate(
      { _id: req.params.id, userId: req.userId },
      { $set: { name, priceInr, imageUrl, category } },
      { new: true }
    );

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ product });
  } catch (error) {
    console.error('[products/update] error', error);
    res.status(500).json({ error: 'Failed to update product' });
  }
});

// DELETE /api/products/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const product = await Product.findOneAndDelete({
      _id: req.params.id,
      userId: req.userId,
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ message: 'Product deleted' });
  } catch (error) {
    console.error('[products/delete] error', error);
    res.status(500).json({ error: 'Failed to delete product' });
  }
});

module.exports = router;
