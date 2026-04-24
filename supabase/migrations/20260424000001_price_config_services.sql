-- =============================================
-- PRICE CONFIG: Semua Layanan LaundryKu
-- Jalankan di Supabase SQL Editor
-- =============================================

-- 1. Buat tabel price_config jika belum ada
CREATE TABLE IF NOT EXISTS price_config (
  id            BIGSERIAL PRIMARY KEY,
  service       TEXT NOT NULL UNIQUE,
  price_per_unit INT  NOT NULL DEFAULT 0,
  unit          TEXT NOT NULL DEFAULT 'kg',
  default_days  INT  NOT NULL DEFAULT 2,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tambahkan kolom yang mungkin belum ada (aman jika sudah ada)
ALTER TABLE price_config ADD COLUMN IF NOT EXISTS service       TEXT;
ALTER TABLE price_config ADD COLUMN IF NOT EXISTS price_per_unit INT NOT NULL DEFAULT 0;
ALTER TABLE price_config ADD COLUMN IF NOT EXISTS unit          TEXT NOT NULL DEFAULT 'kg';
ALTER TABLE price_config ADD COLUMN IF NOT EXISTS default_days  INT  NOT NULL DEFAULT 2;

-- Pastikan kolom service punya UNIQUE constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'price_config_service_key'
  ) THEN
    ALTER TABLE price_config ADD CONSTRAINT price_config_service_key UNIQUE (service);
  END IF;
END $$;

-- 3. Aktifkan RLS
ALTER TABLE price_config ENABLE ROW LEVEL SECURITY;

-- 4. Policy: semua user login bisa baca
DROP POLICY IF EXISTS "Anyone can read price_config" ON price_config;
CREATE POLICY "Anyone can read price_config"
  ON price_config FOR SELECT
  USING (auth.role() = 'authenticated');

-- 5. Policy: hanya admin yang bisa edit
DROP POLICY IF EXISTS "Admin can manage price_config" ON price_config;
CREATE POLICY "Admin can manage price_config"
  ON price_config FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );

-- 6. Insert / Update semua harga layanan
INSERT INTO price_config (service, price_per_unit, unit, default_days) VALUES

-- ======== CUCI KILOAN (PCS/PAKET) ========
('Cuci 5kg',               10000, 'pcs', 3),
('Cuci-Kering 5kg',        20000, 'pcs', 2),
('Cuci-Kering-Lipat 5kg',  25000, 'pcs', 2),
('Cuci 8kg',               15000, 'pcs', 3),
('Cuci-Kering 8kg',        30000, 'pcs', 2),
('Cuci-Kering-Lipat 8kg',  35000, 'pcs', 2),

-- ======== CUCI-SETRIKA (PER KG) ========
('Cuci-Setrika 24jam',          9000, 'kg', 1),
('Cuci-Setrika Express 6-8jam', 12000, 'kg', 1),
('Cuci-Setrika Kilat 3jam',     16000, 'kg', 1),
('Setrika Saja',                5000,  'kg', 1),
('Setrika Saja Express',        7000,  'kg', 1),

-- ======== SELIMUT (PER PCS) ========
('Selimut Kecil',       10000, 'pcs', 2),
('Selimut Besar',       15000, 'pcs', 2),
('Selimut Tebal',       20000, 'pcs', 3),
('Selimut Jumbo',       30000, 'pcs', 3),
('Selimut Extra Jumbo', 35000, 'pcs', 3),

-- ======== BED COVER (PER PCS) ========
('Bed Cover 4kaki',         20000, 'pcs', 3),
('Bed Cover 5kaki',         25000, 'pcs', 3),
('Bed Cover 6kaki',         30000, 'pcs', 3),
('Bed Cover 6kaki Berenda', 35000, 'pcs', 4),

-- ======== HORDEN (PER KG) ========
('Horden', 12000, 'kg', 3),

-- ======== PAKAIAN KHUSUS (PER PCS/SET) ========
('Kemeja/Batik',           15000, 'pcs', 3),
('Jaket Khusus',           20000, 'pcs', 3),
('Celana/Rok',             15000, 'pcs', 3),
('Jas',                    20000, 'pcs', 4),
('Jas+Celana',             30000, 'set', 4),
('Jas+Celana+Rompi',       35000, 'set', 4),
('Selendang/Kemban',       10000, 'pcs', 2),
('Songket',                25000, 'pcs', 4),
('Kebaya Pendek',          15000, 'pcs', 3),
('Kebaya Panjang',         20000, 'pcs', 4),
('Jubah Tebal',            30000, 'pcs', 3),
('Jubah Tipis',            20000, 'pcs', 2),
('Treatment Baju Luntur',  35000, 'pcs', 5),
('Gaun Anak',              15000, 'pcs', 3),
('Gaun Pendek',            20000, 'pcs', 3),
('Gaun Panjang',           25000, 'pcs', 4),

-- ======== BONEKA & BANTAL (PER PCS) ========
('Boneka Kecil',  15000, 'pcs', 3),
('Boneka Sedang', 20000, 'pcs', 3),
('Boneka Besar',  25000, 'pcs', 3),
('Boneka Jumbo',  30000, 'pcs', 4),
('Bantal',        20000, 'pcs', 2),

-- ======== ADD ON ========
('Add On: Express', 10000, 'menu', 0)

ON CONFLICT (service) DO UPDATE SET
  price_per_unit = EXCLUDED.price_per_unit,
  unit = EXCLUDED.unit,
  default_days = EXCLUDED.default_days;
