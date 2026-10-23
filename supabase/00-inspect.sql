
-- 00-inspect.sql
-- Read-only audit for Supabase SQL Editor.
-- No CREATE, ALTER, INSERT, UPDATE, DELETE, or DROP.

-- 1. PostgreSQL version and current session
SELECT version() AS postgres_version,
       current_user AS current_user,
       current_role AS current_role,
       current_database() AS current_database,
       current_schema() AS current_schema;

-- 2. Tables in public schema
SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 3. Check key application tables
SELECT target.table_name,
       EXISTS (
         SELECT 1 FROM information_schema.tables t
         WHERE t.table_schema = 'public'
           AND t.table_name = target.table_name
       ) AS table_exists,
       EXISTS (
         SELECT 1 FROM information_schema.columns c
         WHERE c.table_schema = 'public'
           AND c.table_name = target.table_name
           AND c.column_name = 'id'
       ) AS has_id,
       EXISTS (
         SELECT 1 FROM information_schema.columns c
         WHERE c.table_schema = 'public'
           AND c.table_name = target.table_name
           AND c.column_name = 'user_id'
       ) AS has_user_id,
       EXISTS (
         SELECT 1 FROM information_schema.columns c
         WHERE c.table_schema = 'public'
           AND c.table_name = target.table_name
           AND c.column_name = 'created_at'
       ) AS has_created_at
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
ORDER BY target.table_name;

-- 4. Row Level Security status
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 5. Policies in public schema
SELECT schemaname, tablename, policyname, permissive,
       roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 6. Public function signatures
SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS args,
       pg_get_function_result(p.oid) AS result,
       p.prosecdef AS security_definer,
       p.proconfig AS function_settings
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.prokind = 'f'
ORDER BY p.proname, pg_get_function_identity_arguments(p.oid);

-- 7. Storage tables visible to this database role
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'storage'
ORDER BY table_name;

-- 8. Storage buckets, if visible
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
ORDER BY id;

-- 9. Storage object columns (inspect before querying object data)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'storage'
  AND table_name = 'objects'
ORDER BY ordinal_position;

-- 10. Grants on public tables
SELECT table_schema, table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
ORDER BY table_name, grantee, privilege_type;

-- 11. Grants on storage tables
SELECT table_schema, table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'storage'
ORDER BY table_name, grantee, privilege_type;
