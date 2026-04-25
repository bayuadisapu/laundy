-- Add items column to orders table for multi-service support
-- items is stored as JSONB array: [{service, qty, unit, price_per_unit, subtotal}]
ALTER TABLE orders ADD COLUMN IF NOT EXISTS items jsonb DEFAULT NULL;
