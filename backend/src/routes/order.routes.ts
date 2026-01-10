import { Router, Request, Response, NextFunction } from 'express';
import { OrderService } from '../services/order.service';

const router = Router();

// GET /api/orders
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { status, date } = req.query;
        const filters: { status?: string; date?: string } = {};

        if (status && typeof status === 'string') filters.status = status;
        if (date && typeof date === 'string') filters.date = date;

        const orders = await OrderService.getAll(Object.keys(filters).length > 0 ? filters : undefined);
        res.json(orders);
    } catch (error) {
        next(error);
    }
});

// GET /api/orders/today
router.get('/today', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const orders = await OrderService.getToday();
        res.json(orders);
    } catch (error) {
        next(error);
    }
});

// GET /api/orders/:id
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const order = await OrderService.getById(req.params.id);
        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }
        res.json(order);
    } catch (error) {
        next(error);
    }
});

// POST /api/orders
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { items, ...orderData } = req.body;
        const order = await OrderService.create(orderData, items || []);
        res.status(201).json(order);
    } catch (error) {
        next(error);
    }
});

// PUT /api/orders/:id
router.put('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const order = await OrderService.update(req.params.id, req.body);
        res.json(order);
    } catch (error) {
        next(error);
    }
});

// PATCH /api/orders/:id/status
router.patch('/:id/status', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { status } = req.body;
        if (!status) {
            return res.status(400).json({ error: 'Status is required' });
        }
        const order = await OrderService.updateStatus(req.params.id, status);
        res.json(order);
    } catch (error) {
        next(error);
    }
});

// PATCH /api/orders/:id/payment
router.patch('/:id/payment', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { payment_status, dp_amount } = req.body;
        if (!payment_status) {
            return res.status(400).json({ error: 'Payment status is required' });
        }
        const order = await OrderService.updatePayment(req.params.id, payment_status, dp_amount);
        res.json(order);
    } catch (error) {
        next(error);
    }
});

// DELETE /api/orders/:id
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        await OrderService.delete(req.params.id);
        res.status(204).send();
    } catch (error) {
        next(error);
    }
});

export default router;
