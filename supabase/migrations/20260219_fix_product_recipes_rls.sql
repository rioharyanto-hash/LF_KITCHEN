-- =============================================
-- Create product_recipes table with correct RLS
-- Previous migration file was never executed.
-- =============================================

CREATE TABLE public.product_recipes (
    id uuid NOT NULL DEFAULT gen_random_uuid (),
    product_id uuid NOT NULL REFERENCES public.products (id) ON DELETE CASCADE,
    raw_material_id uuid NOT NULL REFERENCES public.raw_materials (id) ON DELETE RESTRICT,
    quantity numeric NOT NULL DEFAULT 0,
    unit text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz,
    PRIMARY KEY (id)
);

-- Enable RLS with permissive policy
ALTER TABLE public.product_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations for all users" ON public.product_recipes FOR ALL USING (true)
WITH
    CHECK (true);