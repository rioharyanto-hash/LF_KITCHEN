import { supabase } from '../config/supabase';

export interface OrderItem {
    id?: string;
    order_id?: string;
    product_id: string;
    product_name: string;
    quantity: number;
    unit_price: number;
    subtotal: number;
}

export interface Order {
    id: string;
    customer_id?: string;
    order_date: string;
    order_type: 'DIRECT' | 'PO';
    status: 'DRAFT' | 'CONFIRMED' | 'PROCESSING' | 'READY' | 'COMPLETED' | 'CANCELLED';
    total_amount: number;
    dp_amount: number;
    payment_status: 'UNPAID' | 'DP' | 'PAID';
    delivery_date?: string;
    notes?: string;
    created_at: string;
    updated_at?: string;
    items?: OrderItem[];
    customer?: { name: string; phone: string };
}

export const OrderService = {
    async getAll(filters?: { status?: string; date?: string }): Promise<Order[]> {
        let query = supabase
            .from('orders')
            .select(`
        *,
        customer:customers(name, phone),
        items:order_items(*)
      `)
            .order('created_at', { ascending: false });

        if (filters?.status) {
            query = query.eq('status', filters.status);
        }

        if (filters?.date) {
            query = query.gte('order_date', filters.date);
        }

        const { data, error } = await query;
        if (error) throw new Error(error.message);
        return data || [];
    },

    async getById(id: string): Promise<Order | null> {
        const { data, error } = await supabase
            .from('orders')
            .select(`
        *,
        customer:customers(name, phone),
        items:order_items(*)
      `)
            .eq('id', id)
            .single();

        if (error) throw new Error(error.message);
        return data;
    },

    async create(order: Omit<Order, 'id' | 'created_at' | 'updated_at'>, items: OrderItem[]): Promise<Order> {
        // Create order
        const { data: orderData, error: orderError } = await supabase
            .from('orders')
            .insert({
                customer_id: order.customer_id,
                order_date: order.order_date,
                order_type: order.order_type,
                status: order.status,
                total_amount: order.total_amount,
                dp_amount: order.dp_amount,
                payment_status: order.payment_status,
                delivery_date: order.delivery_date,
                notes: order.notes,
            })
            .select()
            .single();

        if (orderError) throw new Error(orderError.message);

        // Create order items
        if (items.length > 0) {
            const orderItems = items.map((item) => ({
                order_id: orderData.id,
                product_id: item.product_id,
                product_name: item.product_name,
                quantity: item.quantity,
                unit_price: item.unit_price,
                subtotal: item.subtotal,
            }));

            const { error: itemsError } = await supabase
                .from('order_items')
                .insert(orderItems);

            if (itemsError) throw new Error(itemsError.message);
        }

        return orderData;
    },

    async update(id: string, order: Partial<Order>): Promise<Order> {
        const { data, error } = await supabase
            .from('orders')
            .update({ ...order, updated_at: new Date().toISOString() })
            .eq('id', id)
            .select()
            .single();

        if (error) throw new Error(error.message);
        return data;
    },

    async updateStatus(id: string, status: Order['status']): Promise<Order> {
        return this.update(id, { status });
    },

    async updatePayment(id: string, paymentStatus: Order['payment_status'], dpAmount?: number): Promise<Order> {
        const updateData: Partial<Order> = { payment_status: paymentStatus };
        if (dpAmount !== undefined) {
            updateData.dp_amount = dpAmount;
        }
        return this.update(id, updateData);
    },

    async delete(id: string): Promise<void> {
        // Delete order items first (cascade should handle this, but just in case)
        await supabase.from('order_items').delete().eq('order_id', id);

        const { error } = await supabase
            .from('orders')
            .delete()
            .eq('id', id);

        if (error) throw new Error(error.message);
    },

    async getToday(): Promise<Order[]> {
        const today = new Date().toISOString().split('T')[0];
        const { data, error } = await supabase
            .from('orders')
            .select(`*, customer:customers(name, phone), items:order_items(*)`)
            .gte('order_date', today)
            .order('created_at', { ascending: false });

        if (error) throw new Error(error.message);
        return data || [];
    },
};
