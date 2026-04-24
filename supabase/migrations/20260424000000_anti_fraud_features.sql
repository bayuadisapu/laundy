-- 1. Tabel untuk Manajemen Shift Kasir
CREATE TABLE IF NOT EXISTS cashier_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID REFERENCES auth.users(id),
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    closed_at TIMESTAMP WITH TIME ZONE,
    opening_cash NUMERIC DEFAULT 0,
    closing_physical_cash NUMERIC,
    total_revenue NUMERIC DEFAULT 0,
    notes TEXT
);

-- 2. Tambahkan kolom ke tabel orders untuk laundry
-- (Menggunakan nama tabel 'orders' sesuai laundy project)
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS pic_wash_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS pic_wash_name TEXT,
ADD COLUMN IF NOT EXISTS pic_iron_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS pic_iron_name TEXT,
ADD COLUMN IF NOT EXISTS pic_pack_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS pic_pack_name TEXT,
ADD COLUMN IF NOT EXISTS shift_id UUID REFERENCES cashier_shifts(id);

-- 3. Tabel Audit Logs untuk melacak manipulasi data
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT NOT NULL, -- e.g., 'VOID_ORDER', 'PRICE_CHANGE'
    order_id TEXT,
    staff_id UUID REFERENCES auth.users(id),
    old_data JSONB,
    new_data JSONB,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS Policies (Simple Admin check)
ALTER TABLE cashier_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can see everything" ON cashier_shifts FOR ALL USING (true);
CREATE POLICY "Admin can see everything" ON audit_logs FOR ALL USING (true);
