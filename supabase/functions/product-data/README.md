# Product data — phase 1

Local implementation of docs/58 (**A1–A8 + B1 + C1**). No marketing,
personalization engine, health-record payload, third-party analytics SDK, or
real-user fixture. This directory does not activate or deploy itself.

## Verification

`node --test supabase/functions/product-data/handler_test.ts` tests the actual
HTTP boundary and exact field allowlist without network or dependencies.
`deno check supabase/functions/product-data/index.ts` checks the deployed entry
when Deno is available. The SDK import is pinned to the existing ask-route
version. `supabase/tests/phase1_product_data.sql` is a transactional synthetic
integration test for an **isolated local/test Supabase database only**, after
the new migration. It is not a production diagnostic.

The Node suite is not a PostgreSQL integration test. A running local Postgres
runtime is required to confirm grants, RLS, locks, cascades and SQL execution.

## API

All actions are `POST /functions/v1/product-data`, authenticated using existing
Supabase Auth and online `getUser`. Raw JWTs, errors, queries, names and health
values are never logged. Every response is `cache-control: no-store`.

- `consent_status` → `enabled`, `generation`, `policy_version`.
- `consent`: `enabled`, `expected_generation`, `request_id`, `policy_version`.
  Enable needs the current generation and an online acknowledgement. Disable
  may use an older expected generation; it increments the generation and
  removes raw events. Replaying an old enable returns the current state and
  never re-enables after a later withdrawal.
- `ingest`: current `generation`, 1–50 strict events, maximum request 32 KiB.
  IDs are deduplicated per account. Events must be no older than 7 days and
  no more than five minutes in the future. Each account has a conservative
  5000-event UTC-day write ceiling (retry batches near the ceiling may refuse).
- `overview`: `days` 7/14/30; production observations only, no historical
  backfill or health values. Counts are reported observations, not population
  estimates or measured crash rates. No claim of prior coverage is made.
  `onboarding:[{step,count,accounts}]` shows independent observed step reach,
  not a guaranteed sequential funnel. `versions:[{version,build,platform,
  os_major,sessions,accounts}]` shows at most 30 coarse technical groups;
  a person can appear in more than one group.
- `support`: exact `query` email/UUID, fixed `reason` and UUID `case_id`.
  Only masked account metadata and category counts/latest record dates/server
  changes return. No list-all, prefix search, health rows, exports or editing.

The request actor is chosen by verified server authentication. Clients cannot
choose another actor. Admins need AAL2 and an enabled private allowlist row.
The DB rereads this row on every request; user-editable metadata and cached
JWT role claims never grant admin access. Overview-only cannot call support.
The allowlist starts **empty**. Access audit insertion is in the same
transaction as the support result; failure closes the request. Denied and
not-found requests are recorded without the search email. Audit preserves
minimal actor/target references after account deletion, never record contents.

## Activation — separate approval required

1. Apply/review `20261029083943_product_data_phase1.sql` in an isolated local
   environment; run the SQL suite with real `service_role` execution. All public
   RPCs are service-role-only and SECURITY INVOKER. A single non-exposed private
   `support_summary` helper is SECURITY DEFINER: it is the explicitly privileged
   cross-account A1/C1 boundary, with fixed SELECTs, fresh role/MFA checks and
   audit in the same transaction. No old auth/users/health table grants change.
   Verify the helper's owner is the trusted migration owner, never an app/admin
   user or role that browser users can become. Its search_path is empty and
   execute is revoked from PUBLIC/anon/authenticated. A dedicated narrow DB
   owner role is a future hardening alternative requiring separately reviewed
   privileges; no such role/credential is created now. The Edge credential is
   still broad; do not describe it as a least-privilege DB credential.
2. Review production migration, role appointment, deployment and origins at
   action time. Explicitly approve each before production use. No credentials
   or administrator accounts are created by these files.
3. Deploy with `PRODUCT_DATA_ENABLED` and `PRODUCT_ADMIN_ENABLED` **absent or
   false**. Independently enable only the reviewed surfaces. Configure exact
   `PRODUCT_ADMIN_ORIGINS` (comma-separated); default allows no browser origins.
   The collection flag blocks opt-ins/ingestion; authenticated `consent_status`
   and withdrawal remain available so a rollback cannot prevent revocation.
4. Require an existing verified TOTP/appropriate Supabase AAL2 session for the
   admin and appoint only reviewed roles. `service_role` stays only on server;
   browser/app use existing public keys and user sessions.
5. Separately review and schedule `public.phase1_retain()` at least daily.
   This code does not create/activate a cron job. Monitor backlog and repeat
   bounded batches when needed. Until scheduled, old physical rows may remain;
   the overview still excludes raw rows received more than 30 days ago.

### Reviewed scheduling example (documentation only — not activated)

After the migration, SQL integration suite, and **separate production approval**:

1. Confirm `pg_cron` is already available; enabling an extension is a separate
   environment action. Confirm the scheduler timezone is UTC/GMT before using
   the time below. Run as the trusted maintenance/migration owner that may
   execute `phase1_retain`, never as a mobile/browser role.
2. Inspect `cron.job` for `jobname = 'fitpack-product-data-retention'` first.
   Do not overwrite an existing same-name job: Supabase Cron treats that as an
   update. If it exists, review its schedule/owner/command explicitly.
3. Only after those checks and approval, the daily registration is:

```sql
-- Daily at 02:15 UTC/GMT. This README does not execute this statement.
select cron.schedule(
  'fitpack-product-data-retention',
  '15 2 * * *',
  'select public.phase1_retain();'
);
```

One run deletes at most 5000 expired rows **per table** (events, consent
history, access audit), not an unbounded scan/delete loop. Confirm the job is
active and owned by the reviewed maintenance role. Check its run history and
the following expired-row counts after the first run and after failures:

```sql
-- Counts only, no user records returned; maintenance access required.
select
  (select count(*) from product_private.events
   where received_at < now() - interval '30 days') as expired_events,
  (select count(*) from product_private.consent_history
   where at < now() - interval '180 days') as expired_consents,
  (select count(*) from product_private.access_audit
   where at < now() - interval '180 days') as expired_audits;
```

If counts remain, a bounded backlog remains: approve/run additional batches or
adjust the reviewed schedule. Do not claim a strict physical 30/180-day bound
while a backlog or failed job exists. With daily successful runs and no
backlog, cleanup occurs on the first run after eligibility (up to roughly one
extra day). Cron run-history cleanup is a separate maintenance decision; this
feature does not delete other jobs' history. Scheduling API reference:
[Supabase Cron quickstart](https://supabase.com/docs/guides/cron/quickstart).

## Effective retention and rollback

Raw events: eligible after 30 days of **receipt**, with 5000-row cleanup batches.
Consent history/access audit: eligible after 180 days, 5000 each per call.
The current preference is retained while the account exists so expired history
cannot re-enable old clients. Account deletion cascades preferences, history,
events and admin appointment. Withdrawal deletes that account's events now.
No independent persistent aggregates are created, so deletion cannot leave an
older linked aggregate behind. All history is derived from the retained rows.

Rollback: disable both server flags first, disable mobile rollout, revoke admin
appointments using separately approved operations; leave additive tables and
functions in place. No business schema, business record, or notification work
is changed. Old applications keep their existing behavior. Do not drop tables
or run destructive rollback SQL to turn the feature off. Purging already
collected data is a distinct, explicitly reviewed operation.
