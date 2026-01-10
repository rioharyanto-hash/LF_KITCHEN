import { supabase } from '../config/supabase';

export interface Product {
    id: string;
    name: string;
    description?: string;
    unit_price: number;
    special_price: number;
    cost_price?: number;
    stock_qty: number;
    category?: string;
    image_url?: string;
    created_at: string;
    updated_at?: string;
}

export const ProductService = {
    async getAll(): Promise<Product[]> {
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .order('name');

        if (error) throw new Error(error.message);
        return data || [];
    },

    async getById(id: string): Promise<Product | null> {
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .eq('id', id)
            .single();

        if (error) throw new Error(error.message);
        return data;
    },

    async create(product: Omit<Product, 'id' | 'created_at' | 'updated_at'>): Promise<Product> {
        const { data, error } = await supabase
            .from('products')
            .insert(product)
            .select()
            .single();

        if (error) throw new Error(error.message);
        return data;
    },

    async update(id: string, product: Partial<Product>): Promise<Product> {
        const { data, error } = await supabase
            .from('products')
            .update({ ...product, updated_at: new Date().toISOString() })
            .eq('id', id)
            .select()
            .single();

        if (error) throw new Error(error.message);
        return data;
    },

    async delete(id: string): Promise<void> {
        const { error } = await supabase
            .from('products')
            .delete()
            .eq('id', id);

        if (error) throw new Error(error.message);
    },

    async getByCategory(category: string): Promise<Product[]> {
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .ilike('category', category)
            .order('name');

        if (error) throw new Error(error.message);
        return data || [];
    },
};
