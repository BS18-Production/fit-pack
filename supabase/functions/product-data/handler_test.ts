import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHandler, validEvent, PROPERTY_RULES, MAX_BODY_BYTES, type Dependencies } from './handler.ts';

const OWNER = '00000000-0000-4000-8000-000000000001';
const REQUEST = '00000000-0000-4000-8000-000000000002';
const NOW = Date.parse('2026-10-29T10:00:00Z');
const context = { version: '1.0.0', build: '2', platform: 'ios', os_major: 26, environment: 'production' };
const event = (name = 'workout_saved', properties: Record<string, unknown> = { mode: 'routine', source: 'live' }) => ({
  event_id: REQUEST, session_id: OWNER, occurred_at: new Date(NOW).toISOString(), name, properties, context: { ...context },
});
function setup(overrides: Partial<Dependencies> = {}) {
  const calls: { name: string; args: Record<string, unknown> }[] = [];
  let authCalls = 0;
  const deps: Dependencies = {
    dataEnabled: () => true, adminEnabled: () => true, allowedOrigins: () => ['https://admin.example.test'],
    authenticate: async token => { authCalls++; return token === 'valid' ? { id: OWNER, aal: 'aal2' } : null; },
    rpc: async (name, args) => { calls.push({ name, args }); return { accepted: 1 }; }, uuid: () => REQUEST, now: () => NOW,
    ...overrides,
  };
  const handle = createHandler(deps);
  const send = (body: unknown, headers: Record<string, string> = {}) => handle(new Request('https://project.example.test/functions/v1/product-data', {
    method: 'POST', headers: { authorization: 'Bearer valid', 'content-type': 'application/json', ...headers }, body: JSON.stringify(body),
  }));
  return { handle, send, calls, authCalls: () => authCalls };
}
test('all supported properties validate, every candidate excluded field is rejected', () => {
  for (const [name, rules] of Object.entries(PROPERTY_RULES)) {
    const properties = Object.fromEntries(Object.entries(rules).map(([k, v]) => [k, v[0]]));
    assert.equal(validEvent(event(name, properties), NOW), true, name);
    for (const field of ['weight_kg', 'reps', 'kcal', 'food', 'exercise', 'routine_name', 'email', 'question', 'note', 'steps', 'photo', 'url', 'stack', 'marketing', 'personalization']) {
      assert.equal(validEvent(event(name, { ...properties, [field]: 'private' }), NOW), false, `${name}.${field}`);
    }
    for (const field of Object.keys(properties)) {
      assert.equal(validEvent(event(name, { ...properties, [field]: null }), NOW), false);
      const incomplete = { ...properties }; delete incomplete[field];
      assert.equal(validEvent(event(name, incomplete), NOW), false);
    }
  }
});
test('schema rejects root/context extras, unsupported events and invalid technical dimensions', () => {
  assert.equal(validEvent({ ...event(), owner_id: OWNER }, NOW), false);
  assert.equal(validEvent({ ...event(), context: { ...context, device_id: 'fingerprint' } }, NOW), false);
  assert.equal(validEvent(event('nutrition_entry_saved', { source: 'barcode' }), NOW), false);
  for (const os_major of [-1, 26.5, 100, '26', null]) assert.equal(validEvent({ ...event(), context: { ...context, os_major } }, NOW), false);
  assert.equal(validEvent({ ...event(), context: { ...context, version: 'token-or-user-text' } }, NOW), false);
  assert.equal(validEvent({ ...event(), context: { ...context, platform: 'iPhone 17 Samet' } }, NOW), false);
});
test('only seven-day-old or newer UTC events within five-minute future tolerance pass', () => {
  assert.equal(validEvent({ ...event(), occurred_at: new Date(NOW - 7 * 86400_000).toISOString() }, NOW), true);
  for (const occurred_at of [new Date(NOW - 7 * 86400_000 - 1).toISOString(), new Date(NOW + 300_001).toISOString(), '2026-10-29T10:00:00+00:00', 'not-a-date']) {
    assert.equal(validEvent({ ...event(), occurred_at }, NOW), false);
  }
});
test('data rollout disabled means no authentication or database call', async () => {
  const s = setup({ dataEnabled: () => false });
  const r = await s.send({ action: 'ingest', generation: 1, events: [event()] });
  assert.equal(r.status, 503); assert.deepEqual(await r.json(), { error: 'not_enabled' });
  assert.equal(s.authCalls(), 0); assert.equal(s.calls.length, 0);
});
test('admin flag is separate from data flag', async () => {
  const s = setup({ adminEnabled: () => false });
  assert.equal((await s.send({ action: 'overview', days: 7 })).status, 503);
  assert.equal((await s.send({ action: 'consent_status' })).status, 200);
  assert.equal(s.calls.length, 1);
});
test('collection kill switch leaves authenticated status/revocation available and blocks new opt-ins', async () => {
  const s = setup({ dataEnabled: () => false });
  assert.equal((await s.send({ action: 'consent_status' })).status, 200);
  assert.equal((await s.send({ action: 'consent', enabled: false, expected_generation: 0, request_id: REQUEST, policy_version: 'phase1-v1' })).status, 200);
  assert.deepEqual(s.calls.map(c => c.name), ['phase1_consent_status', 'phase1_set_consent']);
  assert.equal((await s.send({ action: 'consent', enabled: true, expected_generation: 0, request_id: REQUEST, policy_version: 'phase1-v1' })).status, 503);
  assert.equal(s.calls.length, 2);
  assert.equal((await s.send({ action: 'consent_status' }, { authorization: 'Bearer invalid' })).status, 401);
});
test('unverified, deleted or unavailable account cannot call any RPC', async () => {
  for (const authenticate of [async () => null, async () => { throw new Error('upstream with sensitive details'); }]) {
    const s = setup({ authenticate });
    assert.equal((await s.send({ action: 'consent_status' })).status, 401); assert.equal(s.calls.length, 0);
  }
  const s = setup();
  assert.equal((await s.send({ action: 'consent_status' }, { authorization: 'Bearer invalid' })).status, 401);
});
test('consent uses server actor, original idempotency id and expected generation', async () => {
  const s = setup();
  const body = { action: 'consent', enabled: true, expected_generation: 3, request_id: REQUEST, policy_version: 'phase1-v1' };
  assert.equal((await s.send(body)).status, 200);
  assert.deepEqual(s.calls[0], { name: 'phase1_set_consent', args: { p_actor: OWNER, p_enabled: true, p_expected_generation: 3, p_request_id: REQUEST, p_policy_version: 'phase1-v1' } });
  assert.equal((await s.send({ ...body, actor: REQUEST })).status, 400);
  assert.equal((await s.send({ ...body, policy_version: 'marketing-v1' })).status, 400);
});
test('revoke can carry a stale expected generation; only DB decides current state', async () => {
  const s = setup({ rpc: async () => ({ enabled: false, generation: 9, policy_version: 'phase1-v1' }) });
  const r = await s.send({ action: 'consent', enabled: false, expected_generation: 1, request_id: REQUEST, policy_version: 'phase1-v1' });
  assert.equal(r.status, 200); assert.equal((await r.json()).generation, 9);
});
test('ingest cannot override owner or supply a stale-generation success from an error', async () => {
  const s = setup({ rpc: async () => { throw { message: 'stale_consent' }; } });
  const r = await s.send({ action: 'ingest', generation: 1, events: [event()] });
  assert.equal(r.status, 409); assert.deepEqual(await r.json(), { error: 'stale_consent' });
  assert.equal((await s.send({ action: 'ingest', generation: 1, events: [event()], user_id: REQUEST })).status, 400);
});
test('batch bounds and malformed data fail before database', async () => {
  const s = setup();
  for (const events of [[], Array(51).fill(event()), [{ ...event(), properties: { weight_kg: 100 } }]]) {
    assert.equal((await s.send({ action: 'ingest', generation: 1, events })).status, 400);
  }
  assert.equal((await s.send({ action: 'ingest', generation: 1.5, events: [event()] })).status, 400);
  assert.equal(s.calls.length, 0);
});
test('same event ids reach database unchanged for deduplication', async () => {
  const s = setup();
  const body = { action: 'ingest', generation: 1, events: [event()] };
  await s.send(body); await s.send(body);
  assert.deepEqual(s.calls[0], s.calls[1]);
});
test('overview has fixed window and no caller-controlled actor, SQL, role or fields', async () => {
  const s = setup();
  assert.equal((await s.send({ action: 'overview', days: 14 })).status, 200);
  assert.deepEqual(s.calls[0], { name: 'phase1_admin_overview', args: { p_actor: OWNER, p_aal: 'aal2', p_days: 14, p_request_id: REQUEST } });
  for (const body of [{ action: 'overview', days: 90 }, { action: 'overview', days: 7, fields: ['weight'] }, { action: 'overview', days: 7, sql: 'select *' }]) assert.equal((await s.send(body)).status, 400);
});
test('production UUID generator works without a test dependency', async () => {
  const s = setup({ uuid: undefined });
  assert.equal((await s.send({ action: 'overview', days: 7 })).status, 200);
  assert.match(String(s.calls[0].args.p_request_id), /^[0-9a-f-]{36}$/);
});
test('support requires exact lookup, fixed reason and case id', async () => {
  const s = setup();
  const body = { action: 'support', query: 'synthetic@example.test', reason: 'missing_records', case_id: REQUEST };
  assert.equal((await s.send(body)).status, 200);
  assert.equal(s.calls[0].args.p_actor, OWNER); assert.equal(s.calls[0].args.p_query, 'synthetic@example.test');
  for (const query of ['synth', 'all', 'select * from auth.users']) {
    assert.equal((await s.send({ ...body, query })).status, 400);
  }
  // A percent in a full email remains a literal parameter, never a LIKE filter.
  assert.equal((await s.send({ ...body, query: '%@example.test' })).status, 200);
  assert.equal(s.calls.at(-1)?.args.p_query, '%@example.test');
  assert.equal((await s.send({ ...body, reason: 'marketing' })).status, 400);
  assert.equal((await s.send({ ...body, case_id: null })).status, 400);
});
test('verified aal1 is forwarded for live DB denial/audit, not elevated by request', async () => {
  const s = setup({ authenticate: async () => ({ id: OWNER, aal: 'aal1' }), rpc: async (_name, args) => {
    assert.equal(args.p_aal, 'aal1'); return { error: 'forbidden' };
  } });
  assert.equal((await s.send({ action: 'support', query: OWNER, reason: 'sync_issue', case_id: REQUEST })).status, 403);
});
test('database role denial is not turned into an empty support success', async () => {
  const s = setup({ rpc: async () => ({ error: 'forbidden' }) });
  const r = await s.send({ action: 'support', query: OWNER, reason: 'sync_issue', case_id: REQUEST });
  assert.equal(r.status, 403); assert.deepEqual(await r.json(), { error: 'forbidden' });
});
test('audit/database failure releases no support data or underlying error message', async () => {
  const s = setup({ rpc: async () => { throw { message: 'audit disk full for synthetic@example.test with weight_kg' }; } });
  const r = await s.send({ action: 'support', query: OWNER, reason: 'sync_issue', case_id: REQUEST });
  assert.equal(r.status, 503); assert.deepEqual(await r.json(), { error: 'unavailable' });
  assert.equal(r.headers.get('cache-control'), 'no-store');
});
test('request body byte cap catches streamed oversized bodies even without content-length', async () => {
  const s = setup();
  const r = await s.handle(new Request('https://example.test', { method: 'POST', body: ' '.repeat(MAX_BODY_BYTES + 1) }));
  assert.equal(r.status, 413); assert.equal(s.calls.length, 0);
});
test('CORS uses configured exact origins and never wildcard', async () => {
  const s = setup();
  const good = await s.send({ action: 'consent_status' }, { origin: 'https://admin.example.test' });
  assert.equal(good.headers.get('access-control-allow-origin'), 'https://admin.example.test');
  const bad = await s.send({ action: 'consent_status' }, { origin: 'https://admin.example.test.evil.invalid' });
  assert.equal(bad.status, 403); assert.equal(bad.headers.get('access-control-allow-origin'), null);
});
test('invalid UTF8 / JSON, unsupported methods and unknown actions are closed', async () => {
  const s = setup();
  assert.equal((await s.handle(new Request('https://example.test', { method: 'GET' }))).status, 405);
  assert.equal((await s.handle(new Request('https://example.test', { method: 'POST', body: '{' }))).status, 400);
  assert.equal((await s.send({ action: 'campaign' })).status, 400);
});
test('SQL artifact has service-only RPCs, one private privileged support boundary, and independent retention', () => {
  // Static guard only. The separate SQL integration suite still needs Postgres.
  const sql = readFileSync(new URL('../../migrations/20261029083943_product_data_phase1.sql', import.meta.url), 'utf8');
  assert.equal((sql.match(/security\s+definer/gi) ?? []).length, 1);
  assert.match(sql, /create function product_private\.support_summary[\s\S]*?security definer set search_path = ''/);
  assert.match(sql, /revoke all on function product_private\.support_summary\(uuid,text,text,text,uuid,uuid\) from public,anon,authenticated/);
  const headers = [...sql.matchAll(/create function ([\w.]+)\([^;]*?language (?:sql|plpgsql)(?: stable| immutable)? security (invoker|definer)/gi)];
  assert.equal(headers.filter(h => h[1].startsWith('public.')).length, 6);
  for (const h of headers.filter(h => h[1].startsWith('public.'))) assert.equal(h[2], 'invoker', h[1]);
  assert.doesNotMatch(sql, /insert\s+into\s+product_private\.admins/i);
  assert.match(sql, /from public,anon,authenticated/);
  assert.match(sql, /received_at<now\(\)-interval '30 days'/);
  assert.match(sql, /at<now\(\)-interval '180 days'/);
  assert.match(sql, /references auth\.users\(id\) on delete cascade/);
});
