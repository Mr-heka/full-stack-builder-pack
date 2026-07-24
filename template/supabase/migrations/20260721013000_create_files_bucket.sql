-- Storage pattern (builder pack, data-auth module): one private bucket
-- "files". Any signed-in user can touch it — which today means the owner,
-- because the built-in mailer only delivers sign-in links to org members.
-- Custom SMTP removes that filter: disable public signups before enabling
-- it, or anyone who signs up gets these policies. Downloads use signed
-- URLs; a private bucket has no public links.
--
-- Note: no `alter table storage.objects ...` here — RLS is already enabled
-- on storage tables, and migrations don't own them (the statement would
-- fail with "must be owner").

insert into storage.buckets (id, name, public)
values ('files', 'files', false)
on conflict (id) do nothing;

-- The policies are wrapped so a platform permission change can never abort
-- the deploy — this file doubles as the migration that proves the
-- GitHub-linked deploy on an app's first push, and it must stay green.
-- (supabase/supabase#41126 reports CREATE POLICY on storage.objects being
-- refused to the migration role on some projects; see the builder pack's
-- known-issues entry.) If the block is skipped, the bucket exists but stays
-- locked for everyone until policies are added by a later migration.
do $$
begin
  create policy "Signed-in users can read files"
    on storage.objects for select to authenticated
    using (bucket_id = 'files');

  create policy "Signed-in users can add files"
    on storage.objects for insert to authenticated
    with check (bucket_id = 'files');

  create policy "Signed-in users can update files"
    on storage.objects for update to authenticated
    using (bucket_id = 'files')
    with check (bucket_id = 'files');

  create policy "Signed-in users can delete files"
    on storage.objects for delete to authenticated
    using (bucket_id = 'files');
exception
  when insufficient_privilege then
    raise warning 'files-bucket policies skipped (no privilege to create policies on storage.objects) — bucket stays locked; see builder-pack known-issues/storage-policy-migrations.md';
end
$$;
