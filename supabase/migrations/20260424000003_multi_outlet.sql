-- 1. Rename shop_settings to shops and prepare for multi-outlet
ALTER TABLE IF EXISTS shop_settings RENAME TO shops;

-- 2. Add shop_id to users (public.users)
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS shop_id BIGINT REFERENCES shops(id) DEFAULT 1;

-- 3. Add shop_id to orders
ALTER TABLE IF EXISTS orders ADD COLUMN IF NOT EXISTS shop_id BIGINT REFERENCES shops(id) DEFAULT 1;

-- 4. Add shop_id to price_config
ALTER TABLE IF EXISTS price_config ADD COLUMN IF NOT EXISTS shop_id BIGINT REFERENCES shops(id) DEFAULT 1;

-- Fix unique constraint on price_config to be per shop
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'price_config_service_key') THEN
        ALTER TABLE price_config DROP CONSTRAINT price_config_service_key;
    END IF;
END $$;

-- Check if the new unique constraint already exists, if not, add it
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'price_config_shop_service_key') THEN
        ALTER TABLE price_config ADD CONSTRAINT price_config_shop_service_key UNIQUE (shop_id, service);
    END IF;
END $$;

-- 5. Add shop_id to cashier_shifts
ALTER TABLE IF EXISTS cashier_shifts ADD COLUMN IF NOT EXISTS shop_id BIGINT REFERENCES shops(id) DEFAULT 1;

-- 6. Add shop_id to audit_logs
ALTER TABLE IF EXISTS audit_logs ADD COLUMN IF NOT EXISTS shop_id BIGINT REFERENCES shops(id) DEFAULT 1;
