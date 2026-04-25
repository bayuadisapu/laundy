-- Menambahkan kolom status pembayaran dan waktu pembayaran ke tabel orders
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'Belum Lunas',
ADD COLUMN IF NOT EXISTS payment_time TIMESTAMPTZ;
