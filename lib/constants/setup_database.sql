-- ============================================================
-- SETUP DATABASE LAUNDRY KU - LENGKAP
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- 1. Drop dan buat ulang tabel orders
drop table if exists public.orders;

-- 2. Update tabel users - tambah kolom phone
alter table public.users add column if not exists phone text;

-- 3. Buat tabel price_config
create table if not exists public.price_config (
  service text not null primary key,
  price_per_unit integer not null,
  unit text not null default 'kg',
  default_days integer not null default 2
);

alter table public.price_config enable row level security;
drop policy if exists "Allow all price_config" on public.price_config;
create policy "Allow all price_config" on public.price_config using (true) with check (true);

-- 4. Insert harga default
insert into public.price_config (service, price_per_unit, unit, default_days) values
  ('Biasa',   7000,  'kg',  3),
  ('Express', 15000, 'kg',  1),
  ('Lipat',   3000,  'kg',  2),
  ('Setrika', 3000,  'kg',  2),
  ('Satuan',  5000,  'pcs', 2)
on conflict (service) do update set
  price_per_unit = excluded.price_per_unit,
  unit = excluded.unit,
  default_days = excluded.default_days;

-- 5. Buat tabel orders baru (schema lengkap)
create table public.orders (
  id text not null primary key,
  customer text not null,
  phone text,
  service text not null,
  weight double precision default 0,
  price_per_unit integer default 0,
  price integer not null default 0,
  status text not null default 'Proses',
  pic_id uuid references public.users(id),
  pic_name text,
  notes text,
  estimated_date text,
  order_time timestamp with time zone default timezone('utc', now()),
  completed_time timestamp with time zone,
  picked_up_time timestamp with time zone,
  created_at timestamp with time zone default timezone('utc', now())
);

alter table public.orders enable row level security;
drop policy if exists "Allow all orders" on public.orders;
create policy "Allow all orders" on public.orders using (true) with check (true);

-- 6. Update RLS users agar anonymous juga bisa (untuk dev)
drop policy if exists "Allow all" on public.users;
drop policy if exists "Allow all for authenticated users" on public.users;
create policy "Allow all" on public.users using (true) with check (true);

-- 7. Trigger handle_new_user (update agar tidak error jika kolom tidak ada)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, name, username, role)
  values (
    new.id, new.email,
    coalesce(new.raw_user_meta_data->>'name', new.email),
    new.email, 'staff'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 8. Set admin (ganti email sesuai akun admin Anda)
insert into public.users (id, email, name, username, role)
select id, email, 'Administrator', 'admin', 'admin'
from auth.users where email = 'admin@gmail.com'
on conflict (id) do update set role = 'admin';
