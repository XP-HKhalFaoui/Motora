-- =====================================================================
-- Motora — partial fill-ups
--
-- L/100km is only meaningful between two *full* tanks: the litres poured
-- in tell you what was consumed since the last time the tank was brimmed.
-- FuelService assumed every fill-up was a full one, so a partial fill
-- produced a nonsense figure with nothing to flag it.
--
-- Defaults to true so existing rows keep the old interpretation, which is
-- what they were entered under.
-- =====================================================================

alter table public.maintenance_history
  add column if not exists is_full_tank boolean not null default true;
