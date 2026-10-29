/** Yönetim görünümü için alan seçimi. Gelen nesne hiçbir zaman doğrudan render edilmez. */
export const REASONS = Object.freeze({ account_setup: 'Hesap kurulumu', sync_issue: 'Eşitleme sorunu', missing_records: 'Eksik kayıt bildirimi' });
export const CATEGORY_LABELS = Object.freeze({ workouts: 'Antrenman', nutrition: 'Beslenme', body: 'Ölçüm' });
export const clean = (v, max = 120) => typeof v === 'string' ? v.replace(/[\u0000-\u001f\u007f]/g, '').slice(0, max) : '';
export const count = (v) => Number.isSafeInteger(v) && v >= 0 ? v : null;
export const date = (v) => typeof v === 'string' && Number.isFinite(Date.parse(v)) ? new Date(v).toISOString() : null;
export const uuid = (v) => typeof v === 'string' && /^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i.test(v);
export function exactQuery(v) {
  const q = clean(v, 255).trim();
  return uuid(q) || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(q) ? q : null;
}
export function maskedEmail(v) {
  const raw = clean(v, 255);
  const at = raw.lastIndexOf('@');
  if (at < 1) return 'Gizli';
  // Sunucu yanlışlıkla tam adres döndürse bile arayüz tam adresi göstermez.
  const domain = raw.slice(at + 1);
  if (!/^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(domain)) return 'Gizli';
  return `${raw[0]}***@${domain}`;
}
export function projectOverview(raw) {
  if (!raw || typeof raw !== 'object' || !raw.coverage || !raw.metrics) throw new Error('invalid_response');
  const c = raw.coverage, m = raw.metrics;
  return {
    generated_at: date(raw.generated_at), window_days: [7, 14, 30].includes(raw.window_days) ? raw.window_days : 7,
    coverage: { started_at: date(c.started_at), consenting_accounts: count(c.consenting_accounts), observed_accounts: count(c.observed_accounts), observed_sessions: count(c.observed_sessions), missing_history: c.missing_history !== false },
    metrics: { session_starts: count(m.session_starts), workout_starts: count(m.workout_starts), workout_saves: count(m.workout_saves), workout_saved_accounts: count(m.workout_saved_accounts) },
    daily: Array.isArray(raw.daily) ? raw.daily.slice(-30).filter(d => date(d.day)).map(d => ({ day: date(d.day), sessions: count(d.sessions), workout_saves: count(d.workout_saves) })) : [],
    errors: Array.isArray(raw.errors) ? raw.errors.slice(0, 20).filter(e => ['startup', 'ui', 'storage', 'network', 'unknown'].includes(e.code) && ['app', 'onboarding', 'workout', 'settings', 'sync'].includes(e.screen)).map(e => ({ code: e.code, screen: e.screen, count: count(e.count) })) : [],
    sync: Array.isArray(raw.sync) ? raw.sync.slice(0, 12).filter(s => ['success', 'unreachable', 'no_session', 'permanent', 'repairable', 'unknown'].includes(s.outcome)).map(s => ({ outcome: s.outcome, count: count(s.count) })) : [],
    onboarding: Array.isArray(raw.onboarding) ? raw.onboarding.slice(0, 3).filter(s => ['training', 'nutrition', 'complete'].includes(s.step)).map(s => ({ step: s.step, count: count(s.count), accounts: count(s.accounts) })) : [],
    versions: Array.isArray(raw.versions) ? raw.versions.slice(0, 30).filter(v => typeof v.version === 'string' && /^\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(v.version) && typeof v.build === 'string' && /^\d{1,10}$/.test(v.build) && ['ios', 'android', 'other'].includes(v.platform) && Number.isInteger(v.os_major) && v.os_major >= 0 && v.os_major <= 99).map(v => ({ version: v.version, build: v.build, platform: v.platform, os_major: v.os_major, sessions: count(v.sessions), accounts: count(v.accounts) })) : [],
  };
}
export function projectSupport(raw) {
  if (!raw || !raw.account || !uuid(raw.account.id) || !Array.isArray(raw.categories)) throw new Error('invalid_response');
  const a = raw.account;
  return { account: { id: a.id, email_masked: maskedEmail(a.email_masked), created_at: date(a.created_at), email_confirmed: typeof a.email_confirmed === 'boolean' ? a.email_confirmed : null, onboarded: typeof a.onboarded === 'boolean' ? a.onboarded : null },
    categories: raw.categories.filter(c => Object.hasOwn(CATEGORY_LABELS, c.category)).slice(0, 3).map(c => ({ category: c.category, count: count(c.count), latest_record_at: date(c.latest_record_at), latest_server_change_at: date(c.latest_server_change_at) })),
    request_id: uuid(raw.request_id) ? raw.request_id : null };
}
export function validateConfig(origin, key) {
  const u = new URL(origin);
  const official = u.protocol === 'https:' && /^[a-z0-9-]+\.supabase\.co$/.test(u.hostname);
  const local = u.protocol === 'http:' && ['127.0.0.1', 'localhost'].includes(u.hostname) && u.port === '54321';
  if ((!official && !local) || u.username || u.password || u.pathname !== '/' || u.search || u.hash) throw new Error('invalid_config');
  if (typeof key !== 'string' || !key || key.startsWith('sb_secret_')) throw new Error('publishable_only');
  if (!/^sb_publishable_[A-Za-z0-9_-]+$/.test(key)) {
    try {
      const payload = JSON.parse(atob(key.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
      if (key.split('.').length !== 3 || payload.role !== 'anon') throw new Error();
    } catch { throw new Error('publishable_only'); }
  }
  return Object.freeze({ url: u.origin, key });
}
