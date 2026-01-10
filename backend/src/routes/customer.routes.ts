import { Router, Request, Response, NextFunction } from 'express';
import { CustomerService } from '../services/customer.service';

const router = Router();

// GET /api/customers
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { q } = req.query;
        let customers;

        if (q && typeof q === 'string') {
            customers = await CustomerService.search(q);
        } else {
            customers = await CustomerService.getAll();
        }

        res.json(customers);
    } catch (error) {
        next(error);
    }
});

// GET /api/customers/:id
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const customer = await CustomerService.getById(req.params.id);
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found' });
        }
        res.json(customer);
    } catch (error) {
        next(error);
    }
});

// POST /api/customers
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const customer = await CustomerService.create(req.body);
        res.status(201).json(customer);
    } catch (error) {
        next(error);
    }
});

// PUT /api/customers/:id
router.put('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const customer = await CustomerService.update(req.params.id, req.body);
        res.json(customer);
    } catch (error) {
        next(error);
    }
});

// DELETE /api/customers/:id
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        await CustomerService.delete(req.params.id);
        res.status(204).send();
    } catch (error) {
        next(error);
    }
});

export default router;
