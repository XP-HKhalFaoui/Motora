-- =====================================================================
-- Carnet Auto — Storage buckets + policies
-- Run in the Supabase SQL editor (or via CLI) after 0001_initial_schema.
-- =====================================================================

insert into storage.buckets (id, name, public)
values
  ('vehicle-photos', 'vehicle-photos', false),
  ('invoices', 'invoices', false),
  ('admin-documents', 'admin-documents', false)
on conflict (id) do nothing;

-- Each user can only touch files under a folder named with their uid:
--   <bucket>/<auth.uid()>/<filename>
create policy "own_folder_read" on storage.objects
  for select using (
    bucket_id in ('vehicle-photos','invoices','admin-documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "own_folder_write" on storage.objects
  for insert with check (
    bucket_id in ('vehicle-photos','invoices','admin-documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "own_folder_update" on storage.objects
  for update using (
    bucket_id in ('vehicle-photos','invoices','admin-documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "own_folder_delete" on storage.objects
  for delete using (
    bucket_id in ('vehicle-photos','invoices','admin-documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  );
