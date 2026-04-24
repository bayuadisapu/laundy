-- Enable RLS on shops
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (from old shop_settings)
DROP POLICY IF EXISTS "Enable read access for all authenticated users" ON shops;
DROP POLICY IF EXISTS "Enable full access for admins" ON shops;
DROP POLICY IF EXISTS "Policy for shop settings" ON shops;

-- 1. Read access for everyone (for login, profile, and receipts)
CREATE POLICY "shops_select_policy" ON shops
FOR SELECT TO authenticated USING (true);

-- 2. Full access for Admin users
CREATE POLICY "shops_admin_all_policy" ON shops
FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);

-- Update RLS for other tables to ensure they respect shop boundaries if needed
-- But for now, fixing the shops table error is priority.

-- Ensure price_config has shop-based RLS
ALTER TABLE price_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "price_config_policy" ON price_config;
CREATE POLICY "price_config_shop_isolation" ON price_config
FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND (users.role = 'admin' OR users.shop_id = price_config.shop_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);
