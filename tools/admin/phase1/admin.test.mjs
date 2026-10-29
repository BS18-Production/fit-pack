import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { AdminClient, ApiError } from './api.mjs';
import { projectOverview, projectSupport, validateConfig, exactQuery, maskedEmail } from './model.mjs';
import { demoOverview, demoSupport } from './demo.mjs';
const config = { url: 'https://synthetic.supabase.co', key: 'sb_publishable_synthetic' };
const response = (data, status = 200) => new Response(JSON.stringify(data), { status });
const id = '00000000-0000-4000-8000-000000000001';

test('demo projection exposes only approved fields and masks unexpected full email', () => {
  const demo = demoSupport(); demo.account.email_masked = 'person@example.test'; demo.account.weight_kg = 99; demo.categories[0].workout_sets = [{ weight: 99 }]; demo.categories.push({ category: 'photos', count: 9 });
  const safe = projectSupport(demo);
  assert.equal(safe.account.email_masked, 'p***@example.test');
  assert.equal(safe.categories.length, 3);
  assert.ok(!JSON.stringify(safe).includes('weight'));
  assert.ok(!JSON.stringify(safe).includes('photos'));
  assert.ok(!JSON.stringify(safe).includes('person@'));
  assert.equal(maskedEmail('fullperson@example.tes*'), 'Gizli');
  assert.equal(maskedEmail('fullperson***@example.test'), 'f***@example.test');
});
test('overview drops arbitrary server text and non-allowlisted errors', () => {
  const demo = demoOverview(); demo.notice = 'sensitive text'; demo.errors.push({ code: 'raw sensitive error', screen: 'app', count: 1 }); demo.metrics.weight_kg = 75;
  const safe = projectOverview(demo);
  assert.equal(safe.errors.length, 2);
  assert.ok(!JSON.stringify(safe).includes('sensitive'));
  assert.ok(!JSON.stringify(safe).includes('weight_kg'));
  assert.equal(projectOverview({ ...demo, metrics: {} }).metrics.session_starts, null);
});
test('approved onboarding/version groups are optional, bounded and project only non-health fields', () => {
  const raw = demoOverview();
  raw.onboarding[0].answers = 'PRIVATE ANSWER'; raw.onboarding.push({ step: 'weight_kg', count: 80, accounts: 1 });
  raw.versions[0].device_id = 'PRIVATE ID'; raw.versions.push({ version: 'PRIVATE TEXT', build: '4', platform: 'ios', os_major: 26, sessions: 1, accounts: 1 });
  const safe = projectOverview(raw);
  assert.equal(safe.onboarding.length, 3); assert.equal(safe.versions.length, 2);
  assert.deepEqual(safe.versions[0], { version: '1.0.0', build: '2', platform: 'ios', os_major: 26, sessions: 24, accounts: 6 });
  assert.ok(!JSON.stringify(safe).includes('PRIVATE')); assert.ok(!JSON.stringify(safe).includes('weight_kg'));
  delete raw.onboarding; delete raw.versions;
  assert.deepEqual(projectOverview(raw).onboarding, []); assert.deepEqual(projectOverview(raw).versions, []);
});
test('live config rejects secret keys, non-anon JWTs, URL parameters and foreign endpoints', () => {
  assert.deepEqual(validateConfig(config.url, config.key), config);
  const legacy = role => `ey.test.${role}`.replace('test', btoa(JSON.stringify({ role })));
  assert.equal(validateConfig(config.url, legacy('anon')).url, config.url);
  for (const key of ['sb_secret_no', legacy('service_role'), legacy('authenticated')]) assert.throws(() => validateConfig(config.url, key), /publishable_only/);
  for (const u of ['https://attacker.test', 'https://synthetic.supabase.co?token=x', 'https://user@synthetic.supabase.co', 'http://synthetic.supabase.co', 'http://localhost:1234']) assert.throws(() => validateConfig(u, config.key), /invalid_config/);
  assert.equal(validateConfig('http://127.0.0.1:54321', config.key).url, 'http://127.0.0.1:54321');
});
test('support requires exact account lookup, reason and request id before network', async () => {
  const calls = [], client = new AdminClient(config, (...args) => { calls.push(args); return response({}); });
  assert.equal(exactQuery('person'), null); assert.equal(exactQuery('p@example.test'), 'p@example.test');
  for (const args of [['person', 'sync_issue', id], ['p@example.test', '', id], ['p@example.test', 'sync_issue', 'bad']]) assert.throws(() => client.support(...args), ApiError);
  assert.equal(calls.length, 0);
});
test('auth uses existing Supabase endpoints and support transmits no data in URL', async () => {
  const calls = [], results = [response({ access_token: 'synthetic-token' }), response({ id, factors: [] }), response(demoSupport())];
  const client = new AdminClient(config, async (url, init) => { calls.push({ url, init }); return results.shift(); });
  await client.signIn('owner@example.test', 'synthetic-password');
  await client.support('person@example.test', 'sync_issue', id);
  assert.equal(calls[0].url, `${config.url}/auth/v1/token?grant_type=password`);
  assert.equal(calls[1].url, `${config.url}/auth/v1/user`);
  assert.equal(calls[2].url, `${config.url}/functions/v1/product-data`);
  assert.deepEqual(JSON.parse(calls[2].init.body), { action: 'support', query: 'person@example.test', reason: 'sync_issue', case_id: id });
  assert.equal(calls[2].init.headers.authorization, 'Bearer synthetic-token');
  assert.equal(calls[2].init.cache, 'no-store');
  client.clear();
  await assert.rejects(client.overview(7), e => e.status === 401);
  assert.equal(calls.length, 3);
});
test('TOTP uses existing verified factor challenge and verification, never enrollment', async () => {
  const calls = [], results = [response({ access_token: 'aal1' }), response({ id, factors: [{ id, status: 'verified', factor_type: 'totp' }] }), response({ id }), response({ access_token: 'aal2' }), response(demoOverview())];
  const client = new AdminClient(config, async (url, init) => { calls.push({ url, init }); return results.shift(); });
  const auth = await client.signIn('owner@example.test', 'p');
  assert.equal(auth.needsMfa, true);
  await client.verifyTotp(auth.factorId, '123456');
  await client.overview(7);
  assert.equal(calls[2].url, `${config.url}/auth/v1/factors/${id}/challenge`);
  assert.deepEqual(JSON.parse(calls[3].init.body), { challenge_id: id, code: '123456' });
  assert.equal(calls[4].init.headers.authorization, 'Bearer aal2');
  assert.equal(calls.filter(c => c.url.endsWith('/factors')).length, 0);
});
test('pending sign-in cannot restore a token after local sign out', async () => {
  let settle; const pending = new Promise(r => { settle = r; }); let calls = 0;
  const client = new AdminClient(config, async () => { calls++; return pending; });
  const login = client.signIn('owner@example.test', 'p'); client.clear(); settle(response({ access_token: 'old-token' }));
  await assert.rejects(login, e => e.status === 401);
  await assert.rejects(client.overview(7), e => e.status === 401);
  assert.equal(calls, 1);
});
test('server role, audit and activation failures are errors, not zero data', async () => {
  for (const [status, code] of [[403, 'forbidden'], [503, 'not_enabled'], [503, 'audit_failed']]) {
    const results = [response({ access_token: 'token' }), response({ id }), response({ error: code, detail: 'sensitive error' }, status)];
    const client = new AdminClient(config, async () => results.shift());
    await client.signIn('owner@example.test', 'p');
    await assert.rejects(client.support(id, 'missing_records', id), e => e.status === status && e.message === code && !e.message.includes('sensitive'));
  }
});
test('admin source has no persistent credential store, HTML interpolation or third-party script', () => {
  const app = readFileSync(new URL('./app.mjs', import.meta.url), 'utf8');
  const api = readFileSync(new URL('./api.mjs', import.meta.url), 'utf8');
  const html = readFileSync(new URL('./index.html', import.meta.url), 'utf8');
  assert.ok(!/localStorage|sessionStorage|innerHTML|insertAdjacentHTML/.test(app + api));
  assert.ok(html.includes("script-src 'self'"));
  assert.ok(!/<script[^>]+src="https?:/.test(html));
  assert.ok(html.includes('Sentetik yerel demo; canlı veri değil'));
});
