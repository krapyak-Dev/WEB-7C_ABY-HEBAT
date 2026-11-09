-- Jalankan seluruh SQL ini di Supabase > SQL Editor > New query.
-- Setelah membuat akun lewat Authentication, semua akun otomatis mendapat profil role siswa.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  full_name text not null default 'Siswa',
  role text not null default 'siswa' check (role in ('admin','siswa')),
  qr_code text unique,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id,email,full_name,role)
  values (new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name','Siswa'),'siswa')
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  day_name text not null check(day_name in ('Senin','Selasa','Rabu','Kamis','Jumat')),
  day_index int not null,
  start_time text not null,
  subject text not null,
  teacher text,
  created_at timestamptz not null default now()
);
create table if not exists public.duties (
  id uuid primary key default gen_random_uuid(),
  day_name text not null check(day_name in ('Senin','Selasa','Rabu','Kamis','Jumat')),
  day_index int not null,
  student_id uuid not null references public.profiles(id) on delete cascade,
  task text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  attendance_date date not null,
  status text not null check(status in ('masuk','tidak_masuk')),
  recorded_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(student_id,attendance_date),
  check(extract(isodow from attendance_date) between 1 and 5)
);
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  event_date date,
  event_time time,
  location text,
  date_certainty text not null default 'pasti' check(date_certainty in ('pasti','perkiraan')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create table if not exists public.class_settings (
  id int primary key default 1 check(id=1),
  next_due_date date,
  monthly_amount int not null default 10000,
  target_amount bigint,
  updated_by uuid references public.profiles(id)
);
insert into public.class_settings(id,next_due_date,monthly_amount)
values(1,null,10000) on conflict(id) do nothing;

alter table public.profiles enable row level security;
alter table public.lessons enable row level security;
alter table public.duties enable row level security;
alter table public.attendance enable row level security;
alter table public.announcements enable row level security;
alter table public.class_settings enable row level security;

-- Profil: siswa dapat melihat profil kelas dan mengubah profilnya sendiri secara terbatas.
drop policy if exists "profiles read authenticated" on public.profiles;
create policy "profiles read authenticated" on public.profiles for select to authenticated using (true);
drop policy if exists "profiles update self or admin" on public.profiles;
drop policy if exists "profiles admin update only" on public.profiles;
create policy "profiles admin update only" on public.profiles for update to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Data kelas: semua pengguna login dapat melihat, hanya admin yang dapat mengubah.
do $$ declare t text; begin
 foreach t in array array['lessons','duties','announcements'] loop
  execute format('drop policy if exists "read %1$s" on public.%1$I',t);
  execute format('create policy "read %1$s" on public.%1$I for select to authenticated using (true)',t);
  execute format('drop policy if exists "admin manage %1$s" on public.%1$I',t);
  execute format('create policy "admin manage %1$s" on public.%1$I for all to authenticated using (public.is_admin()) with check (public.is_admin())',t);
 end loop;
end $$;

-- Presensi: siswa hanya dapat melihat miliknya; admin dapat melihat dan mengelola semuanya.
drop policy if exists "attendance own or admin read" on public.attendance;
create policy "attendance own or admin read" on public.attendance for select to authenticated
using(student_id=auth.uid() or public.is_admin());
drop policy if exists "attendance admin insert" on public.attendance;
create policy "attendance admin insert" on public.attendance for insert to authenticated
with check(public.is_admin());
drop policy if exists "attendance admin update" on public.attendance;
create policy "attendance admin update" on public.attendance for update to authenticated
using(public.is_admin()) with check(public.is_admin());
drop policy if exists "attendance admin delete" on public.attendance;
create policy "attendance admin delete" on public.attendance for delete to authenticated
using(public.is_admin());

-- Pengaturan kas dapat dibaca semua akun, tetapi target hanya dikirim ke browser admin.
-- Untuk menjaga target tetap rahasia, siswa memakai view aman di bawah, bukan tabel langsung.
drop policy if exists "settings admin all" on public.class_settings;
create policy "settings admin all" on public.class_settings for all to authenticated
using(public.is_admin()) with check(public.is_admin());
create or replace view public.public_class_settings as
select id,next_due_date,monthly_amount from public.class_settings;
grant select on public.public_class_settings to authenticated;

-- Supabase REST view perlu tabel yang bisa dibaca oleh pemilik view; batasi tabel settings ke admin.
-- View memakai security_invoker=false secara default pada konfigurasi standar PostgreSQL.
-- Jika proyek memakai security_invoker view, ubah akses melalui RPC khusus admin/siswa.
