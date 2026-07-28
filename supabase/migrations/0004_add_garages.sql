-- =====================================================================
-- Motora — Garages (repair shops / mécaniciens)
-- Promotes the free-text maintenance_history.garage_name to a proper,
-- user-level directory entity that interventions can link to via
-- garage_id. garage_name is kept as a denormalized label so history
-- stays readable even if a garage is later deleted.
-- =====================================================================

create table if not exists public.garages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  phone text,
  address text,
  note text,
  created_at timestamptz default now()
);

create index if not exists idx_garages_user on public.garages(user_id, name);

alter table public.maintenance_history
  add column if not exists garage_id uuid
    references public.garages(id) on delete set null;

create index if not exists idx_maintenance_history_garage
  on public.maintenance_history(garage_id);

alter table public.garages enable row level security;

drop policy if exists "garages_owner" on public.garages;
create policy "garages_owner" on public.garages
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
