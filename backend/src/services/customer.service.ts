import { supabase } from '../config/supabase';

export interface Customer {
    id: string;
    name: string;
    phone: string;
    address?: string;
    notes?: string;
    is_special_price: boolean;
    created_at: string;
    updated_at?: string;
}

export const CustomerService = {
    async getAll(): Promise<Customer[]> {
        const { data, error } = await supabase
            .from('customers')
            .select('*')
            .order('name');

        if (error) throw new Error(error.message);
        return data || [];
    },

    async getById(id: string): Promise<Customer | null> {
        const { data, error } = await supabase
            .from('customers')
            .select('*')
            .eq('id', id)
            .single();

        if (error) throw new Error(error.message);
        return data;
    },

    async create(customer: Omit<Customer, 'id' | 'created_at' | 'updated_at'>): Promise<Customer> {
        const { data, error } = await supabase
            .from('customers')
            .insert(customer)
            .select()
            .single();

        if (error) throw new Error(error.message);
        return data;
    },

    async update(id: string, customer: Partial<Customer>): Promise<Customer> {
        const { data, error } = await supabase
            .from('customers')
            .update({ ...customer, updated_at: new Date().toISOString() })
            .eq('id', id)
            .select()
            .single();

        if (error) throw new Error(error.message);
        return data;
    },

    async delete(id: string): Promise<void> {
        const { error } = await supabase
            .from('customers')
            .delete()
            .eq('id', id);

        if (error) throw new Error(error.message);
    },

    async search(query: string): Promise<Customer[]> {
        const { data, error } = await supabase
            .from('customers')
            .select('*')
            .or(`name.ilike.%${query}%,phone.ilike.%${query}%`)
            .order('name');

        if (error) throw new Error(error.message);
        return data || [];
    },
};
