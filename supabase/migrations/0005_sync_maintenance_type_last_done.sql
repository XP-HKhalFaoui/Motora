-- =====================================================================
-- Motora — derive maintenance_types.last_done_* from the history
--
-- These two columns are the anchor every forecast is measured from
-- (PredictionService.predict), and the client used to maintain them with
-- a second write issued right after inserting or updating a history row.
-- That was wrong in three ways:
--
--   * not atomic — if the second write failed, the intervention was
--     already committed and the anchor silently drifted;
--   * editing an *older* intervention overwrote the anchor with its
--     values even when a more recent one existed, regressing it;
--   * deleting an intervention never reverted the anchor at all, so the
--     type kept pointing at a row that no longer existed.
--
-- A trigger recomputes them from the latest remaining intervention
-- instead, so they can no longer disagree with the history.
--
-- Note: when the last intervention for a type is deleted, the anchor
-- becomes null and the type goes back to the app's "à configurer" state.
-- That is deliberate — with no intervention on record there is nothing
-- to measure the next échéance from.
-- =====================================================================

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
  -- An UPDATE can move a row between two types; both need recomputing.
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
                and h.is_fuel is not true
              order by h.done_at desc, h.created_at desc
              limit 1
           ),
           last_done_date = (
             select h.done_at
               from public.maintenance_history h
              where h.maintenance_type_id = target
                and h.is_fuel is not true
              order by h.done_at desc, h.created_at desc
              limit 1
           )
     where mt.id = target;
  end loop;

  return null;
end;
$$;

drop trigger if exists trg_sync_maintenance_type_last_done
  on public.maintenance_history;
create trigger trg_sync_maintenance_type_last_done
  after insert or update or delete on public.maintenance_history
  for each row execute function public.sync_maintenance_type_last_done();

-- One-off backfill: realign any type whose anchor already drifted away
-- from its history. Types with no linked intervention keep whatever was
-- entered by hand in the maintenance-type form.
update public.maintenance_types mt
   set last_done_km = latest.km,
       last_done_date = latest.done_at
  from (
    select distinct on (h.maintenance_type_id)
           h.maintenance_type_id,
           h.km,
           h.done_at
      from public.maintenance_history h
     where h.maintenance_type_id is not null
       and h.is_fuel is not true
     order by h.maintenance_type_id, h.done_at desc, h.created_at desc
  ) latest
 where mt.id = latest.maintenance_type_id
   and (mt.last_done_km is distinct from latest.km
        or mt.last_done_date is distinct from latest.done_at);
