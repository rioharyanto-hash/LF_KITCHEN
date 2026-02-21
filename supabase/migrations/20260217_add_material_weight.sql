-- Migration: Add unit conversion to raw_materials, and recipe_yield to products
ALTER TABLE raw_materials
ADD COLUMN IF NOT EXISTS base_unit TEXT,
ADD COLUMN IF NOT EXISTS unit_conversion DOUBLE PRECISION DEFAULT 1;

ALTER TABLE products
ADD COLUMN IF NOT EXISTS recipe_yield INTEGER DEFAULT 1;

-- Update comments for documentation
COMMENT ON COLUMN raw_materials.base_unit IS 'The smallest unit used in recipes (e.g., butir, gr, ml)';

COMMENT ON COLUMN raw_materials.unit_conversion IS 'How many base_units are in 1 purchase unit (e.g., 16 for kg->butir)';

COMMENT ON COLUMN products.recipe_yield IS 'Number of units produced by the recipe';