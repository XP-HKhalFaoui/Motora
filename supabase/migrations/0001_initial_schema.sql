-- =====================================================================
-- Carnet Auto — Schéma initial
-- =====================================================================

-- ---------- Tables ---------------------------------------------------

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  brand text,
  model text,
  year int,
  plate_number text,
  current_km int not null default 0,
  purchase_date date,
  photo_url text,
  created_at timestamptz default now()
);

create table if not exists public.mileage_logs (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references public.vehicles(id) on delete cascade not null,
  km int not null,
  recorded_at timestamptz default now(),
  note text
);

create table if not exists public.maintenance_types (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references public.vehicles(id) on delete cascade not null,
  label text not null,
  interval_km int,
  interval_months int,
  last_done_km int,
  last_done_date date,
  icon text
);

create table if not exists public.maintenance_history (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references public.vehicles(id) on delete cascade not null,
  maintenance_type_id uuid references public.maintenance_types(id) on delete set null,
  title text not null,
  description text,
  km int,
  cost numeric(10,2),
  garage_name text,
  done_at date not null,
  invoice_url text,
  created_at timestamptz default now()
);

create table if not exists public.admin_documents (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references public.vehicles(id) on delete cascade not null,
  doc_type text not null,
  year int not null,
  issued_date date,
  expiry_date date not null,
  file_url text,
  status text default 'pending',
  created_at timestamptz default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references public.vehicles(id) on delete cascade not null,
  related_table text,
  related_id uuid,
  title text not null,
  body text,
  trigger_date timestamptz not null,
  is_sent boolean default false
);

-- ---------- Indexes --------------------------------------------------

create index if not exists idx_mileage_logs_vehicle on public.mileage_logs(vehicle_id, recorded_at desc);
create index if not exists idx_maintenance_types_vehicle on public.maintenance_types(vehicle_id);
create index if not exists idx_maintenance_history_vehicle on public.maintenance_history(vehicle_id, done_at desc);
create index if not exists idx_admin_documents_vehicle on public.admin_documents(vehicle_id, expiry_date);
create index if not exists idx_notifications_vehicle on public.notifications(vehicle_id, trigger_date);

-- ---------- Row Level Security --------------------------------------

alter table public.vehicles           enable row level security;
alter table public.mileage_logs       enable row level security;
alter table public.maintenance_types  enable row level security;
alter table public.maintenance_history enable row level security;
alter table public.admin_documents    enable row level security;
alter table public.notifications      enable row level security;

-- Helper: a row of a child table belongs to the current user when its
-- parent vehicle belongs to the current user.
create or replace function public.owns_vehicle(v_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.vehicles v
    where v.id = v_id and v.user_id = auth.uid()
  );
$$;

-- vehicles: direct ownership
drop policy if exists "vehicles_owner" on public.vehicles;
create policy "vehicles_owner" on public.vehicles
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- child tables: ownership via vehicle
drop policy if exists "mileage_logs_owner" on public.mileage_logs;
create policy "mileage_logs_owner" on public.mileage_logs
  for all using (public.owns_vehicle(vehicle_id)) with check (public.owns_vehicle(vehicle_id));

drop policy if exists "maintenance_types_owner" on public.maintenance_types;
create policy "maintenance_types_owner" on public.maintenance_types
  for all using (public.owns_vehicle(vehicle_id)) with check (public.owns_vehicle(vehicle_id));

drop policy if exists "maintenance_history_owner" on public.maintenance_history;
create policy "maintenance_history_owner" on public.maintenance_history
  for all using (public.owns_vehicle(vehicle_id)) with check (public.owns_vehicle(vehicle_id));

drop policy if exists "admin_documents_owner" on public.admin_documents;
create policy "admin_documents_owner" on public.admin_documents
  for all using (public.owns_vehicle(vehicle_id)) with check (public.owns_vehicle(vehicle_id));

drop policy if exists "notifications_owner" on public.notifications;
create policy "notifications_owner" on public.notifications
  for all using (public.owns_vehicle(vehicle_id)) with check (public.owns_vehicle(vehicle_id));

-- ---------- Keep vehicles.current_km in sync with mileage_logs -------

create or replace function public.sync_vehicle_km()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.vehicles
     set current_km = greatest(current_km, new.km)
   where id = new.vehicle_id;
  return new;
end;
$$;

drop trigger if exists trg_sync_vehicle_km on public.mileage_logs;
create trigger trg_sync_vehicle_km
  after insert on public.mileage_logs
  for each row execute function public.sync_vehicle_km();
