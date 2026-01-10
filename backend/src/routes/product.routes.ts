import { Router, Request, Response, NextFunction } from 'express';
import { ProductService } from '../services/product.service';

const router = Router();

// GET /api/products
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { category } = req.query;
        let products;

        if (category && typeof category === 'string') {
            products = await ProductService.getByCategory(category);
        } else {
            products = await ProductService.getAll();
        }

        res.json(products);
    } catch (error) {
        next(error);
    }
});

// GET /api/products/:id
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const product = await ProductService.getById(req.params.id);
        if (!product) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json(product);
    } catch (error) {
        next(error);
    }
});

// POST /api/products
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const product = await ProductService.create(req.body);
        res.status(201).json(product);
    } catch (error) {
        next(error);
    }
});

// PUT /api/products/:id
router.put('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const product = await ProductService.update(req.params.id, req.body);
        res.json(product);
    } catch (error) {
        next(error);
    }
});

// DELETE /api/products/:id
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        await ProductService.delete(req.params.id);
        res.status(204).send();
    } catch (error) {
        next(error);
    }
});

export default router;
