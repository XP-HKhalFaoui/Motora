-- =====================================================================
-- Motora — Fuel consumption tracking
-- Adds liters + an explicit is_fuel flag to maintenance_history so fuel
-- fill-ups can be distinguished from repairs and L/100km can be computed
-- between consecutive fill-ups.
-- =====================================================================

alter table public.maintenance_history
  add column if not exists is_fuel boolean not null default false,
  add column if not exists liters numeric(6,2);
