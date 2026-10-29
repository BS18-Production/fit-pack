import { AdminClient, ApiError } from './api.mjs';
import { projectOverview, projectSupport, validateConfig, exactQuery, CATEGORY_LABELS } from './model.mjs';
import { demoOverview, demoSupport } from './demo.mjs';

const $ = id => document.getElementById(id);
const number = v => v === null ? '—' : new Intl.NumberFormat('tr').format(v);
const when = v => v ? new Intl.DateTimeFormat('tr', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(v)) : 'Henüz bildirilmedi';
const day = v => new Intl.DateTimeFormat('tr', { day: 'numeric', month: 'short', timeZone: 'UTC' }).format(new Date(v));
const node = (tag, text, cls) => { const n = document.createElement(tag); if (text !== undefined) n.textContent = text; if (cls) n.className = cls; return n; };
let client = null, demo = false, epoch = 0, overviewEpoch = 0, supportEpoch = 0, factor = null;

function status(text = '', error = false) {
  $('status').textContent = text;
  $('status').className = `status${error ? ' error' : ''}`;
  $('status').hidden = !text;
}
function message(error) {
  if (error instanceof ApiError) {
    if (error.message === 'not_enabled') return 'Yönetim sunucusu henüz etkin değil. Yerel kodun hazır olması canlı erişimin açıldığı anlamına gelmez.';
    if (error.message === 'mfa_required') return 'İki aşamalı giriş gerekiyor. Hesabında kurulu doğrulama yöntemini kullan; yeni yöntem kurulumu bu panelden yapılmaz.';
    if (error.message === 'audit_failed') return 'Erişim günlüğü yazılamadı. Güvenlik gereği hesap bilgisi açılmadı.';
    if (error.status === 401) return 'Oturum doğrulanamadı veya sona erdi. Yeniden giriş yap.';
    if (error.status === 403) return 'Bu görünüm için yetkin yok veya iki aşamalı doğrulama eksik. Yetki sunucuda denetlenir.';
    if (error.status === 404) return 'Bu tam e-posta veya hesap kimliğiyle eşleşen kayıt bulunamadı.';
    if (error.status === 429) return 'İstek sınırına ulaşıldı. Biraz sonra yeniden dene.';
    if (error.status === 503) return 'Sunucu erişimi hazır değil veya geçici olarak kullanılamıyor. Gösterilecek veri doğrulanamadı.';
  }
  if (error?.message === 'invalid_config') return 'Yalnız HTTPS Supabase proje adresi veya yerel 54321 adresi kullanılabilir. Adrese yol ya da sorgu ekleme.';
  if (error?.message === 'publishable_only') return 'Yalnız publishable veya anon istemci anahtarı kullanılabilir. Yönetim anahtarı girme.';
  return 'İşlem doğrulanamadı. Bağlantıyı kontrol edip yeniden dene; önceki hesap bilgisi gösterilmiyor.';
}
function clearOverview() {
  for (const id of ['metrics', 'chart', 'coverage', 'onboarding', 'versions', 'errors', 'sync']) $(id).replaceChildren();
  $('updated').textContent = '';
}
function clearSupport() {
  const box = node('div', undefined, 'empty-state');
  box.append(node('span', '⌕', 'empty-mark'), node('h2', 'Henüz hesap açılmadı'), node('p', 'Bir destek amacı seçip tam e-posta veya hesap kimliğiyle ara.'));
  $('support-result').replaceChildren(box);
}
function leave() {
  epoch++; overviewEpoch++; supportEpoch++;
  client?.clear(); client = null; factor = null; demo = false;
  clearOverview(); clearSupport();
  $('lookup').value = ''; $('reason').value = ''; $('totp').value = '';
  $('password').value = ''; $('email').value = ''; $('publishable').value = ''; $('project').value = '';
  $('workspace').hidden = true; $('entry').hidden = false; $('exit').hidden = true;
  $('login-form').hidden = false; $('mfa-form').hidden = true;
  $('mode-label').textContent = 'BAĞLI DEĞİL'; $('mode-label').className = 'badge';
  status();
}
function enter(isDemo) {
  demo = isDemo;
  $('entry').hidden = true; $('workspace').hidden = false; $('exit').hidden = false;
  $('demo-banner').hidden = !demo;
  $('mode-label').textContent = demo ? 'SENTETİK DEMO' : 'YETKİLİ OTURUM';
  $('mode-label').className = `badge${demo ? ' demo' : ''}`;
  status(); view('overview'); $('view-title').focus?.();
}
function view(which) {
  const overview = which === 'overview';
  $('overview').hidden = !overview; $('support').hidden = overview;
  $('tab-overview').toggleAttribute('aria-current', overview);
  $('tab-support').toggleAttribute('aria-current', !overview);
  if (overview) $('tab-overview').setAttribute('aria-current', 'page');
  else $('tab-support').setAttribute('aria-current', 'page');
  $('view-title').textContent = overview ? 'Ürün özeti' : 'Kullanıcı desteği';
  status();
  if (overview) { supportEpoch++; clearSupport(); $('lookup').value = ''; void refresh(); }
  else overviewEpoch++;
}
function definition(parent, label, value) {
  const row = node('div'); row.append(node('dt', label), node('dd', value)); parent.append(row);
}
function renderOverview(o) {
  const cards = [
    ['Gözlenen hesap', o.coverage.observed_accounts, 'İzinli ölçüm kapsamındaki hesaplar'],
    ['Ziyaret başlangıcı', o.metrics.session_starts, 'Uygulama açılışı veya öne geliş'],
    ['Başlatılan antrenman', o.metrics.workout_starts, 'Rutin veya serbest akış'],
    ['Antrenman kaydı', o.metrics.workout_saves, `${number(o.metrics.workout_saved_accounts)} farklı hesap · canlı / geçmiş kayıt`],
  ];
  $('metrics').replaceChildren(...cards.map(([label, value, hint]) => {
    const card = node('div', undefined, 'metric'); card.append(node('p', label, 'metric-label'), node('div', number(value), 'value'), node('p', hint, 'hint')); return card;
  }));
  $('updated').textContent = `Yanıt zamanı · ${when(o.generated_at)}`;
  const cov = $('coverage'); cov.replaceChildren();
  definition(cov, 'Ölçüm başlangıcı', when(o.coverage.started_at));
  definition(cov, 'Paylaşıma izin veren', `${number(o.coverage.consenting_accounts)} hesap`);
  definition(cov, 'Bu dönemde gözlenen', `${number(o.coverage.observed_accounts)} hesap`);
  definition(cov, 'Gözlenen ziyaret', number(o.coverage.observed_sessions));
  definition(cov, 'Geçmiş kapsamı', 'Yeni ölçümden itibaren');
  renderChart(o.daily);
  const errorLabels = { startup: 'Açılış', ui: 'Arayüz', storage: 'Yerel saklama', network: 'Bağlantı', unknown: 'Diğer' };
  const screens = { app: 'Uygulama', onboarding: 'Kurulum', workout: 'Antrenman', settings: 'Ayarlar', sync: 'Eşitleme' };
  $('errors').replaceChildren(...(o.errors.length ? o.errors.map(e => dataRow(errorLabels[e.code], `${screens[e.screen]} · sabit kod`, e.count)) : [node('p', 'Bu kapsamda bildirilmiş hata yok.', 'empty')]));
  const outcomes = { success: 'Başarılı', unreachable: 'Sunucuya ulaşılamadı', no_session: 'Oturum gerekli', permanent: 'Kalıcı hata', repairable: 'Onarılabilir', unknown: 'Diğer' };
  $('sync').replaceChildren(...(o.sync.length ? o.sync.map(s => dataRow(outcomes[s.outcome], 'Bildirilen deneme', s.count)) : [node('p', 'Henüz eşitleme sonucu bildirilmedi.', 'empty')]));
  const steps = { training: 'Antrenman adımı', nutrition: 'Beslenme adımı', complete: 'Kurulum tamamlandı' };
  $('onboarding').replaceChildren(...(o.onboarding.length ? o.onboarding.map(s => dataRow(steps[s.step], `${number(s.count)} olay · bağımsız erişim`, s.accounts, 'hesap')) : [node('p', 'Henüz kurulum adımı ölçülmedi.', 'empty')]));
  const platforms = { ios: 'iOS', android: 'Android', other: 'Diğer' };
  $('versions').replaceChildren(...(o.versions.length ? o.versions.map(v => dataRow(`${v.version} (${v.build}) · ${platforms[v.platform]} ${v.os_major || '—'}`, `${number(v.accounts)} hesap · gruplar çakışabilir`, v.sessions, 'ziyaret')) : [node('p', 'Henüz sürüm grubu bildirilmedi.', 'empty')]));
}
function dataRow(label, hint, n, unit = '') {
  const row = node('div', undefined, 'data-row'), copy = node('div'); copy.append(node('span', label), node('small', hint)); row.append(copy, node('b', `${number(n)}${unit ? ` ${unit}` : ''}`)); return row;
}
function renderChart(rows) {
  const parent = $('chart'); parent.replaceChildren();
  if (!rows.length) { parent.append(node('p', 'Bu dönemde ölçüm bulunmuyor. Geçmiş kullanım sıfır olarak doldurulmaz.', 'empty')); return; }
  const ns = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(ns, 'svg'); svg.setAttribute('viewBox', '0 0 620 230'); svg.setAttribute('role', 'img'); svg.setAttribute('aria-label', 'Günlere göre gözlenen ziyaret başlangıçları');
  const add = (tag, attrs, text) => { const el = document.createElementNS(ns, tag); for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, String(v)); if (text !== undefined) el.textContent = text; svg.append(el); return el; };
  const max = Math.max(1, ...rows.map(r => r.sessions ?? 0)), width = 580 / rows.length;
  for (const y of [40, 100, 160, 195]) add('line', { x1: 20, x2: 600, y1: y, y2: y, class: 'grid' });
  rows.forEach((r, i) => {
    const x = 25 + i * width, bar = Math.max(3, width * .55), height = (r.sessions ?? 0) / max * 145;
    add('rect', { x, y: 40, width: bar, height: 155, rx: 4, class: 'bar-background' });
    add('rect', { x, y: 195 - height, width: bar, height, rx: 4, class: 'bar' });
    if (rows.length <= 14) add('text', { x: x + bar / 2, y: 184 - height, 'text-anchor': 'middle', class: 'chart-value' }, number(r.sessions));
    if (rows.length <= 7 || i % Math.ceil(rows.length / 7) === 0) add('text', { x: x + bar / 2, y: 222, 'text-anchor': 'middle' }, day(r.day));
  });
  parent.append(svg);
}
async function refresh() {
  const request = ++overviewEpoch, owner = epoch, days = Number($('days').value);
  $('refresh').disabled = true; clearOverview(); status('Ölçüm kapsamı yükleniyor…');
  try {
    const raw = demo ? demoOverview(days) : await client.overview(days);
    if (request !== overviewEpoch || owner !== epoch) return;
    renderOverview(projectOverview(raw)); status();
  } catch (e) { if (request === overviewEpoch && owner === epoch) { clearOverview(); status(message(e), true); } }
  finally { if (request === overviewEpoch) $('refresh').disabled = false; }
}
function renderSupport(s) {
  const parent = $('support-result'); parent.replaceChildren();
  const head = node('div', undefined, 'account-head'), avatar = node('div', 'FP', 'account-avatar'), identity = node('div');
  identity.append(node('h2', s.account.email_masked), node('p', s.account.id)); head.append(avatar, identity); parent.append(head);
  const dl = node('dl', undefined, 'detail-list');
  definition(dl, 'Hesap oluşturuldu', when(s.account.created_at));
  definition(dl, 'E-posta doğrulama', s.account.email_confirmed === null ? 'Bilinmiyor' : s.account.email_confirmed ? 'Doğrulanmış' : 'Doğrulanmamış');
  definition(dl, 'Kurulum', s.account.onboarded === null ? 'Bilinmiyor · profil henüz eşitlenmemiş' : s.account.onboarded ? 'Tamamlanmış' : 'Tamamlanmamış'); parent.append(dl);
  for (const c of s.categories) {
    const section = node('section', undefined, 'category'), h3 = node('h3', CATEGORY_LABELS[c.category]); h3.append(node('b', `${number(c.count)} kayıt`)); section.append(h3);
    for (const [label, value] of [['Son kayıt tarihi', c.latest_record_at], ['Son sunucu değişikliği', c.latest_server_change_at]]) {
      const p = node('p'), t = node('time', when(value)); if (value) t.dateTime = value; p.append(node('span', label), t); section.append(p);
    }
    parent.append(section);
  }
  parent.append(node('p', 'Bu tarihler son uygulama kullanımı değildir. Değerler yalnız sunucuya eşitlenmiş kayıt kapsamını gösterir.', 'notice'));
  parent.append(node('p', demo ? 'Sentetik demo · erişim günlüğü veya kullanıcı sorgusu oluşturulmadı.' : `Denetimli erişim · İstek ${s.request_id ?? 'sunucuda kayıtlı'}`, 'audit-mark'));
}
$('demo').addEventListener('click', () => { leave(); epoch++; enter(true); });
$('exit').addEventListener('click', () => { const ending = client?.signOut(); leave(); if (ending) void ending; });
$('tab-overview').addEventListener('click', () => view('overview'));
$('tab-support').addEventListener('click', () => view('support'));
$('days').addEventListener('change', () => void refresh());
$('refresh').addEventListener('click', () => void refresh());
$('login-form').addEventListener('submit', async e => {
  e.preventDefault(); const button = e.submitter, owner = ++epoch;
  button.disabled = true; status('Oturum doğrulanıyor…');
  try {
    client?.clear(); client = new AdminClient(validateConfig($('project').value.trim(), $('publishable').value.trim()));
    const result = await client.signIn($('email').value.trim(), $('password').value);
    if (owner !== epoch) return;
    $('password').value = ''; $('publishable').value = ''; $('exit').hidden = false;
    if (result.needsMfa) { factor = result.factorId; $('login-form').hidden = true; $('mfa-form').hidden = false; $('totp').focus(); status('İki aşamalı doğrulamayı tamamla.'); }
    else enter(false);
  } catch (error) { if (owner === epoch) { client?.clear(); $('password').value = ''; status(message(error), true); } }
  finally { button.disabled = false; }
});
$('mfa-form').addEventListener('submit', async e => {
  e.preventDefault(); const button = e.submitter, owner = epoch; button.disabled = true; status('Kod doğrulanıyor…');
  try { await client.verifyTotp(factor, $('totp').value.trim()); if (owner === epoch) { $('totp').value = ''; factor = null; enter(false); } }
  catch (error) { if (owner === epoch) { $('totp').value = ''; status(message(error), true); } }
  finally { button.disabled = false; }
});
$('support-form').addEventListener('submit', async e => {
  e.preventDefault(); const button = e.submitter, request = ++supportEpoch, owner = epoch;
  clearSupport(); status();
  const q = exactQuery($('lookup').value), reason = $('reason').value;
  if (!q || !reason) { status('Tam e-posta veya geçerli hesap kimliği ve destek amacı gerekli.', true); return; }
  button.disabled = true; status(demo ? 'Sentetik örnek açılıyor…' : 'Yetki ve erişim günlüğü doğrulanıyor…');
  $('lookup').value = '';
  try {
    const raw = demo ? demoSupport() : await client.support(q, reason, crypto.randomUUID());
    if (request !== supportEpoch || owner !== epoch) return;
    renderSupport(projectSupport(raw)); status();
  } catch (error) { if (request === supportEpoch && owner === epoch) { clearSupport(); status(message(error), true); } }
  finally { button.disabled = false; }
});
window.addEventListener('pagehide', leave);
