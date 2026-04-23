-- 1. Tabel Users (Profil & Hak Akses)
-- Hubungkan ke auth.users Supabase
CREATE TABLE public.users (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  username TEXT UNIQUE,
  img_url TEXT,
  role TEXT CHECK (role IN ('admin', 'staff')) DEFAULT 'staff',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabel Orders (Data Cucian)
CREATE TABLE public.orders (
  id TEXT PRIMARY KEY, -- Menggunakan ID manual (misal: LF-123)
  customer TEXT NOT NULL,
  service TEXT NOT NULL,
  weight DECIMAL NOT NULL,
  price INTEGER NOT NULL,
  status TEXT NOT NULL,
  pic TEXT, -- Nama staff yang menangani
  date TEXT NOT NULL, -- Format YYYY-MM-DD
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Aktifkan Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- 4. Policies (Agar semua user authenticated bisa baca/tulis sementara untuk dev)
CREATE POLICY "Allow all for authenticated users" ON public.users FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated users" ON public.orders FOR ALL TO authenticated USING (true);

-- 5. Trigger Otomatis Pembuatan Profil saat Auth Register
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'name', 'staff');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
