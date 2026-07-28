-- =====================================================================
-- Motora — Photo-verified mileage readings
-- Adds an optional photo_url to mileage_logs (odometer photo backing a
-- reading — shown as "certifié" vs "déclaratif" in the app) and a
-- dedicated storage bucket + per-user policies for it.
-- =====================================================================

alter table public.mileage_logs
  add column if not exists photo_url text;

insert into storage.buckets (id, name, public)
values ('mileage-photos', 'mileage-photos', false)
on conflict (id) do nothing;

create policy "mileage_photos_read" on storage.objects
  for select using (
    bucket_id = 'mileage-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "mileage_photos_write" on storage.objects
  for insert with check (
    bucket_id = 'mileage-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "mileage_photos_update" on storage.objects
  for update using (
    bucket_id = 'mileage-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "mileage_photos_delete" on storage.objects
  for delete using (
    bucket_id = 'mileage-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
