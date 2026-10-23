# Supabase test commands and expected results

## 1. Read-only SQL Editor checks

Use in Supabase SQL Editor only.

```sql
\i supabase/00-inspect.sql
\i supabase/tests/01-readonly-sql-editor.sql
```

Expected result:
- Reports actual schema for `public` and `storage`.
- Shows whether RLS is enabled and which policies are active.
- Does not modify data or schema.

## 2. Local PostgreSQL integration checks

Run against a local test database with a real Postgres engine.

```bash
psql "$LOCAL_TEST_DB_URL" -v ON_ERROR_STOP=1 -f supabase/00-inspect.sql
psql "$LOCAL_TEST_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/02-local-psql.sql
```

Expected result:
- Exits with status 0 when all required objects exist.
- Raises `RAISE EXCEPTION` when a required table or policy is missing.

## 3. JWT / RPC / Storage / RLS checks

These must be run in a real Supabase project, not the production database, and only after creating a local or staging environment. They require Supabase Auth and JWTs for the following roles:

- `anon`
- `authenticated` regular user
- admin user in `admins`

Typical flow:

```bash
supabase login
supabase link --project-ref <project-ref>
supabase start
supabase db reset
supabase auth api sign-in --email test@example.com --password s3cr3t
```

Then verify:

```bash
curl -H "Authorization: Bearer $JWT" \
  -X POST "$SUPABASE_URL/rest/v1/rpc/publish_site"
```

And check:

- `anon` cannot read draft tables or `site_published_secret`
- authenticated user cannot access admin-only rows or RPCs
- admin can manage content only where `admins` policy allows it
- Storage bucket operations are restricted by bucket and ACL

## 4. What not to do

- Do not run `INSERT INTO auth.users` in production.
- Do not set `ALTER TABLE ... DISABLE ROW LEVEL SECURITY` to make tests pass.
- Do not grant broad permissions to `anon` or `authenticated`.
- Do not delete `site_settings` rows or any production data.

## 5. Test cleanup

- Delete temporary rows created in local test fixtures.
- Roll back any transaction in local integration scripts.
- Use a dedicated local database or a disposable Supabase branch.

## 6. Android / mobile repeatability

If a team member on Android needs to repeat the same checks, the simplest method is to:

1. Share the SQL scripts via Git or zip file.
2. Open the project in a local Supabase Studio or a dev environment.
3. Run the read-only scripts first.
4. Only then execute the JWT-based verification steps in a staging project.

This keeps credentials and secrets out of chat and avoids destructive changes.
