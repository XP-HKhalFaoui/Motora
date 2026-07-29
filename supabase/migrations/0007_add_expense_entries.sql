-- =====================================================================
-- Motora — expenses that are not maintenance
--
-- maintenance_history was already a two-kind ledger: interventions, plus
-- fuel fill-ups flagged with is_fuel. Everything else you spend on a car
-- — insurance, vignette, taxes, tolls, parking, car wash, fines — had
-- nowhere to go, so the only way to record it was to disguise it as an
-- intervention, which then polluted the maintenance history and the
-- carnet PDF.
--
-- `kind` replaces the is_fuel boolean with a proper three-way
-- distinction. is_fuel is kept and written in sync for now so an APK
-- built before this migration keeps working; it can be dropped once
-- every install is past this point.
-- =====================================================================

alter table public.maintenance_history
  add column if not exists kind text not null default 'maintenance',
  add column if not exists category text;

-- Backfill from the flag that used to carry this meaning.
update public.maintenance_history
   set kind = 'fuel'
 where is_fuel is true
   and kind is distinct from 'fuel';

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'maintenance_history_kind_check'
  ) then
    alter table public.maintenance_history
      add constraint maintenance_history_kind_check
      check (kind in ('maintenance', 'fuel', 'expense'));
  end if;
end $$;

-- The history screen filters by kind within a vehicle, newest first.
create index if not exists idx_maintenance_history_kind
  on public.maintenance_history(vehicle_id, kind, done_at desc);

-- An expense is never an intervention, so it must not move a maintenance
-- type's anchor. The trigger from 0005 already filters on is_fuel; widen
-- it to anything that isn't a maintenance entry.
create or replace function public.sync_maintenance_type_last_done()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  affected uuid[];
  target uuid;
begin
  affected := array_remove(array[
    case when tg_op in ('UPDATE', 'DELETE') then old.maintenance_type_id end,
    case when tg_op in ('INSERT', 'UPDATE') then new.maintenance_type_id end
  ], null);

  foreach target in array affected loop
    update public.maintenance_types mt
       set last_done_km = (
             select h.km
               from public.maintenance_history h
              where h.maintenance_type_id = target
                and h.kind = 'maintenance'
              order by h.done_at desc, h.created_at desc
              limit 1
           ),
           last_done_date = (
             select h.done_at
               from public.maintenance_history h
              where h.maintenance_type_id = target
                and h.kind = 'maintenance'
              order by h.done_at desc, h.created_at desc
              limit 1
           )
     where mt.id = target;
  end loop;

  return null;
end;
$$;
