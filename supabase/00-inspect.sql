-- 00-inspect.sql
-- Safe, read-only schema audit for Supabase SQL Editor and local Postgres.
-- This script inspects the actual live database without creating or altering objects.

\echo '=== Postgres version ==='
SELECT version();

\echo '=== Search path / roles ==='
SELECT current_user AS current_user, current_role AS current_role, current_database() AS current_database, current_schema() AS current_schema;

\echo '=== Tables in public schema ==='
SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

\echo '=== Key application tables ==='
SELECT table_name,
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=target.table_name AND column_name='id') AS has_id,
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=target.table_name AND column_name='user_id') AS has_user_id,
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=target.table_name AND column_name='created_at') AS has_created_at
FROM (
  VALUES
    ('admins'),
    ('site_settings'),
    ('site_published'),
    ('site_published_secret'),
    ('photos'),
    ('timeline'),
    ('letter'),
    ('quiz_questions'),
    ('quest_steps'),
    ('guest_messages'),
    ('visit_stats')
) AS target(table_name)
ORDER BY table_name;

\echo '=== RLS-enabled tables ==='
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = true
ORDER BY tablename;

\echo '=== Policies in public schema ==='
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

\echo '=== Function signatures in public schema ==='
SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS args,
       pg_get_function_result(p.oid) AS result
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
ORDER BY p.proname, pg_get_function_identity_arguments(p.oid);

\echo '=== Storage buckets and policies ==='
SELECT schema_name, table_name
FROM information_schema.tables
WHERE table_schema = 'storage'
ORDER BY table_name;

SELECT bucket_id, public, file_size_limit, allowed_mime_types
FROM storage.buckets
ORDER BY bucket_id;

\echo '=== Objects in storage schema (sample) ==='
SELECT id, bucket_id, name, owner, path_tokens, metadata
FROM storage.objects
LIMIT 20;

\echo '=== Grant summary for public schema ==='
SELECT table_schema, table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
ORDER BY table_name, grantee, privilege_type;

\echo '=== Grant summary for storage schema ==='
SELECT table_schema, table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'storage'
ORDER BY table_name, grantee, privilege_type;

\echo '=== Result: objects that must exist before any security test ==='
SELECT 'public.admins' AS object_name,
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='admins') AS exists
UNION ALL
SELECT 'public.site_settings', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='site_settings')
UNION ALL
SELECT 'public.site_published', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='site_published')
UNION ALL
SELECT 'public.site_published_secret', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='site_published_secret')
UNION ALL
SELECT 'public.photos', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='photos')
UNION ALL
SELECT 'public.timeline', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='timeline')
UNION ALL
SELECT 'public.letter', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='letter')
UNION ALL
SELECT 'public.quiz_questions', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='quiz_questions')
UNION ALL
SELECT 'public.quest_steps', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='quest_steps')
UNION ALL
SELECT 'public.guest_messages', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='guest_messages')
UNION ALL
SELECT 'public.visit_stats', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='visit_stats')
ORDER BY object_name;
