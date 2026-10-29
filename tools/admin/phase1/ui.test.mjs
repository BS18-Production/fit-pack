import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { demoSupport } from './demo.mjs';

// Küçük DOM yüzeyi; gerçek uygulama olay işleyicilerini dış paket olmadan çalıştırır.
class Element {
  children = []; attributes = {}; listeners = {}; hidden = false; disabled = false; value = ''; className = ''; _text = '';
  constructor(tag) { this.tag = tag; }
  set textContent(value) { this._text = String(value); this.children = []; }
  get textContent() { return this._text + this.children.map(c => c.textContent ?? String(c)).join(''); }
  append(...children) { this.children.push(...children); }
  replaceChildren(...children) { this._text = ''; this.children = children; }
  setAttribute(k, v) { this.attributes[k] = String(v); }
  toggleAttribute(k, yes) { if (yes) this.attributes[k] = ''; else delete this.attributes[k]; }
  addEventListener(type, fn) { this.listeners[type] = fn; }
  focus() {}
  fire(type, extra = {}) { return this.listeners[type]?.({ preventDefault() {}, submitter: new Element('button'), ...extra }); }
}
async function page(fetcher) {
  const html = readFileSync(new URL('./index.html', import.meta.url), 'utf8');
  const nodes = Object.fromEntries([...html.matchAll(/id="([^"]+)"/g)].map(m => [m[1], new Element(m[1])]));
  nodes.days.value = '7';
  globalThis.document = { getElementById: id => nodes[id], createElement: tag => new Element(tag), createElementNS: (_, tag) => new Element(tag) };
  globalThis.window = { addEventListener() {} };
  globalThis.fetch = fetcher;
  await import(`./app.mjs?test=${crypto.randomUUID()}`);
  return nodes;
}
const tick = () => new Promise(r => setImmediate(r));
const json = (value, status = 200) => new Response(JSON.stringify(value), { status });
const id = '00000000-0000-4000-8000-000000000001';
function fillLogin(n) { n.project.value = 'https://synthetic.supabase.co'; n.publishable.value = 'sb_publishable_test'; n.email.value = 'owner@example.test'; n.password.value = 'test-password'; }

test('synthetic demo overview and support run without any network/auth calls', async () => {
  let calls = 0;
  const n = await page(() => { calls++; throw new Error('demo must never fetch'); });
  n.demo.fire('click'); await tick();
  assert.equal(n.workspace.hidden, false);
  assert.equal(n['demo-banner'].hidden, false);
  assert.ok(n.metrics.textContent.includes('Gözlenen hesap'));
  assert.ok(n.onboarding.textContent.includes('Kurulum tamamlandı'));
  assert.ok(n.onboarding.textContent.includes('6 hesap'));
  assert.ok(n.versions.textContent.includes('1.0.0 (2) · iOS 26'));
  assert.ok(n.versions.textContent.includes('24 ziyaret'));
  n['tab-support'].fire('click'); n.lookup.value = 'synthetic@example.test'; n.reason.value = 'missing_records';
  await n['support-form'].fire('submit');
  assert.ok(n['support-result'].textContent.includes('d***@example.test'));
  assert.ok(n['support-result'].textContent.includes('erişim günlüğü veya kullanıcı sorgusu oluşturulmadı'));
  assert.equal(n.lookup.value, '');
  assert.equal(calls, 0);
  n.exit.fire('click');
  assert.equal(n.workspace.hidden, true);
  assert.ok(!n['support-result'].textContent.includes('d***@'));
});
test('support error clears old account data and is not rendered as zero records', async () => {
  let supportCalls = 0;
  const n = await page(async (url, init) => {
    if (url.includes('/token?')) return json({ access_token: 'synthetic-token' });
    if (url.endsWith('/user')) return json({ id, factors: [] });
    const body = JSON.parse(init.body);
    if (body.action === 'overview') return json({ error: 'not_enabled' }, 503);
    if (body.action === 'support') return ++supportCalls === 1 ? json(demoSupport()) : json({ error: 'unavailable', detail: 'PRIVATE DATA MUST NOT SHOW' }, 503);
    return new Response(null, { status: 204 });
  });
  fillLogin(n); await n['login-form'].fire('submit'); await tick();
  assert.ok(n.status.textContent.includes('henüz etkin değil'));
  n['tab-support'].fire('click'); n.lookup.value = id; n.reason.value = 'sync_issue'; await n['support-form'].fire('submit');
  assert.ok(n['support-result'].textContent.includes('d***@example.test'));
  n.lookup.value = id; await n['support-form'].fire('submit');
  assert.ok(!n['support-result'].textContent.includes('d***@example.test'));
  assert.ok(n.status.textContent.includes('doğrulanamadı'));
  assert.ok(!n.status.textContent.includes('PRIVATE DATA'));
});
test('late support response cannot re-open a user after sign out', async () => {
  let settle;
  const pending = new Promise(r => { settle = r; });
  const n = await page(async (url, init) => {
    if (url.includes('/token?')) return json({ access_token: 'synthetic-token' });
    if (url.endsWith('/user')) return json({ id, factors: [] });
    if (url.includes('/logout?')) return new Response(null, { status: 204 });
    const body = JSON.parse(init.body);
    if (body.action === 'support') return pending;
    return json({ error: 'not_enabled' }, 503);
  });
  fillLogin(n); await n['login-form'].fire('submit'); await tick();
  n['tab-support'].fire('click'); n.lookup.value = id; n.reason.value = 'sync_issue';
  const request = n['support-form'].fire('submit');
  n.exit.fire('click'); settle(json(demoSupport())); await request;
  assert.equal(n.workspace.hidden, true);
  assert.equal(n.email.value, ''); assert.equal(n.password.value, ''); assert.equal(n.publishable.value, '');
  assert.ok(!n['support-result'].textContent.includes('d***@example.test'));
});
test('unknown onboarding remains unknown and health/extra response fields never render', async () => {
  const response = demoSupport(); response.account.onboarded = null; response.account.email_masked = 'fullperson@example.test'; response.account.weight_kg = 80; response.categories[0].sets = 'PRIVATE HEALTH VALUE';
  const n = await page(async (url, init) => {
    if (url.includes('/token?')) return json({ access_token: 'synthetic-token' });
    if (url.endsWith('/user')) return json({ id, factors: [] });
    return JSON.parse(init.body).action === 'support' ? json(response) : json({ error: 'not_enabled' }, 503);
  });
  fillLogin(n); await n['login-form'].fire('submit'); await tick();
  n['tab-support'].fire('click'); n.lookup.value = id; n.reason.value = 'account_setup'; await n['support-form'].fire('submit');
  assert.ok(n['support-result'].textContent.includes('Bilinmiyor · profil henüz eşitlenmemiş'));
  assert.ok(n['support-result'].textContent.includes('f***@example.test'));
  assert.ok(!n['support-result'].textContent.includes('fullperson@'));
  assert.ok(!n['support-result'].textContent.includes('PRIVATE HEALTH'));
});
