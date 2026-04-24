-- Create shop_settings table
CREATE TABLE IF NOT EXISTS shop_settings (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL DEFAULT 'LaundryKu',
    address TEXT,
    phone TEXT,
    logo_url TEXT,
    receipt_footer TEXT DEFAULT 'Terima kasih telah menggunakan jasa kami!',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings if empty
INSERT INTO shop_settings (id, name, address, phone)
SELECT 1, 'LaundryKu', 'Jl. Contoh No. 123', '08123456789'
WHERE NOT EXISTS (SELECT 1 FROM shop_settings WHERE id = 1);
