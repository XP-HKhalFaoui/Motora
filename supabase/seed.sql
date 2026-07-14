-- =====================================================================
-- Motora — Demo data (Clio 4 / Golf 7), per PROMPT-claude-code.md §7.
--
-- Run AFTER 0001_initial_schema.sql and storage_buckets.sql, against a
-- real Supabase user. Replace :'demo_user_id' below with your own
-- auth.uid() (Authentication -> Users -> copy the UUID), e.g. via psql:
--   psql "$DB_URL" -v demo_user_id="'11111111-2222-3333-4444-555555555555'" -f seed.sql
-- or just find/replace the placeholder before running in the SQL editor.
-- =====================================================================

do $$
declare
  v_user_id uuid := :'demo_user_id'::uuid;
  v_clio_id uuid := '00000000-0000-0000-0000-000000000001';
  v_golf_id uuid := '00000000-0000-0000-0000-000000000002';
  v_vidange_id uuid;
  v_plaquettes_id uuid;
  v_batterie_id uuid;
  v_pneus_id uuid;
  v_distribution_id uuid;
begin
  -- ---------------- Vehicles ------------------------------------------
  insert into public.vehicles (id, user_id, name, brand, model, year, plate_number, current_km, created_at)
  values (v_clio_id, v_user_id, 'Clio 4', 'Renault', 'Diesel', 2018, 'AB-123-CD', 112480, now())
  on conflict (id) do nothing;

  insert into public.vehicles (id, user_id, name, brand, model, year, plate_number, current_km, created_at)
  values (v_golf_id, v_user_id, 'Golf 7', 'Volkswagen', 'Essence', 2016, 'CD-456-EF', 98200, now())
  on conflict (id) do nothing;

  -- ---------------- Mileage history (drives the km/mois average) ------
  insert into public.mileage_logs (vehicle_id, km, recorded_at) values
    (v_clio_id, 105400, now() - interval '6 months'),
    (v_clio_id, 108900, now() - interval '3 months'),
    (v_clio_id, 110200, now() - interval '2 months'),
    (v_clio_id, 112480, now());

  insert into public.mileage_logs (vehicle_id, km, recorded_at) values
    (v_golf_id, 93700, now() - interval '5 months'),
    (v_golf_id, 96380, now() - interval '2 months'),
    (v_golf_id, 98200, now());

  -- ---------------- Maintenance types (Clio 4) -------------------------
  insert into public.maintenance_types (vehicle_id, label, interval_km, last_done_km, icon)
  values (v_clio_id, 'Vidange moteur', 10000, 102160, 'oil_barrel')
  returning id into v_vidange_id;

  insert into public.maintenance_types (vehicle_id, label, interval_km, last_done_km, icon)
  values (v_clio_id, 'Plaquettes avant', 30000, 88400, 'disc_full')
  returning id into v_plaquettes_id;

  insert into public.maintenance_types (vehicle_id, label, interval_months, last_done_date, icon)
  values (v_clio_id, 'Batterie', 48, (current_date - interval '3 years' - interval '4 months')::date, 'battery_charging_full')
  returning id into v_batterie_id;

  insert into public.maintenance_types (vehicle_id, label, interval_km, last_done_km, icon)
  values (v_clio_id, 'Pneus', 30000, 105400, 'tire_repair')
  returning id into v_pneus_id;

  insert into public.maintenance_types (vehicle_id, label, interval_km, last_done_km, icon)
  values (v_clio_id, 'Kit distribution', 60000, 90000, 'settings_input_component')
  returning id into v_distribution_id;

  insert into public.maintenance_types (vehicle_id, label, interval_months, icon)
  values (v_clio_id, 'Contrôle technique', 24, 'fact_check');

  -- ---------------- Maintenance history (Clio 4) ------------------------
  insert into public.maintenance_history (vehicle_id, maintenance_type_id, title, km, cost, garage_name, done_at) values
    (v_clio_id, v_vidange_id, 'Vidange + filtre à huile', 110200, 89.00, 'Norauto Lyon', '2026-03-12'),
    (v_clio_id, v_plaquettes_id, 'Plaquettes avant', 108900, 145.00, 'Speedy', '2026-01-05'),
    (v_clio_id, v_pneus_id, 'Pneus avant x2', 105400, 220.00, 'Euromaster', '2025-10-20');

  -- ---------------- Admin documents -------------------------------------
  insert into public.admin_documents (vehicle_id, doc_type, year, expiry_date, status) values
    (v_golf_id, 'assurance', 2026, current_date + interval '12 days', 'valid'),
    (v_clio_id, 'vignette', 2026, date '2026-12-31', 'valid'),
    (v_clio_id, 'controle_technique', 2026, current_date + interval '3 months', 'pending');
end $$;
