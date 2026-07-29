// Deletes the calling user's account and everything attached to it.
//
// Apple (App Store guideline 5.1.1(v)) and Google both require in-app
// account deletion for any app that lets you create an account. It cannot
// be done from the client: removing a row from auth.users needs the
// service_role key, which must never ship inside the app.
//
// Deploy with:
//   supabase functions deploy delete-account
//
// SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are
// injected by the platform; no extra secrets to set.

import { createClient } from 'jsr:@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })

// Every bucket stores objects under a <user-id>/ prefix (see uploadFile in
// lib/services/supabase_service.dart and supabase/storage_buckets.sql).
const BUCKETS = [
  'vehicle-photos',
  'invoices',
  'admin-documents',
  'mileage-photos',
]

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return json({ error: 'missing_authorization' }, 401)

  const url = Deno.env.get('SUPABASE_URL')!

  // The account to delete is whoever the JWT says it is — never a user id
  // read from the request body, which any caller could forge.
  const caller = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user }, error: authError } = await caller.auth.getUser()
  if (authError || !user) return json({ error: 'invalid_token' }, 401)

  const admin = createClient(
    url,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  )

  // Storage first: objects are not owned by any table, so deleting the
  // user would otherwise orphan them permanently.
  for (const bucket of BUCKETS) {
    const { data: files, error } = await admin.storage
      .from(bucket)
      .list(user.id, { limit: 1000 })
    if (error) {
      console.error(`list ${bucket} failed`, error)
      continue
    }
    if (files?.length) {
      const paths = files.map((f) => `${user.id}/${f.name}`)
      const { error: removeError } = await admin.storage
        .from(bucket)
        .remove(paths)
      if (removeError) console.error(`remove ${bucket} failed`, removeError)
    }
  }

  // vehicles.user_id and garages.user_id both reference auth.users with
  // ON DELETE CASCADE, and every other table cascades from vehicles, so
  // this one call takes the whole tree with it.
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id)
  if (deleteError) {
    console.error('deleteUser failed', deleteError)
    return json({ error: 'delete_failed' }, 500)
  }

  return json({ deleted: true }, 200)
})
