// Pure request boundary: testable without network, secrets, or the Deno runtime.
export const POLICY_VERSION = 'phase1-v1';
export const MAX_BODY_BYTES = 32 * 1024;
export const MAX_BATCH = 50;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ISO_UTC = /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,6})?Z$/;
type Obj = Record<string, unknown>;
export interface Identity { id: string; aal: 'aal1' | 'aal2' }
export interface Dependencies {
  dataEnabled: () => boolean;
  adminEnabled: () => boolean;
  allowedOrigins: () => string[];
  authenticate: (jwt: string) => Promise<Identity | null>;
  rpc: (name: string, args: Obj) => Promise<unknown>;
  uuid?: () => string;
  now?: () => number;
}
const obj = (v: unknown): v is Obj => v !== null && typeof v === 'object' && !Array.isArray(v);
const exact = (v: Obj, keys: string[]) => Object.keys(v).length === keys.length && keys.every(k => Object.hasOwn(v, k));
const oneOf = (v: unknown, values: string[]) => typeof v === 'string' && values.includes(v);
const int = (v: unknown, max = Number.MAX_SAFE_INTEGER) => typeof v === 'number' && Number.isSafeInteger(v) && v >= 0 && v <= max;
const uuid = (v: unknown): v is string => typeof v === 'string' && UUID.test(v);
export const PROPERTY_RULES: Record<string, Record<string, string[]>> = {
  session_started: { reason: ['cold_start', 'foreground'] },
  session_ended: { duration_bucket: ['under_1m', '1_5m', '5_15m', '15_60m', 'over_60m'] },
  onboarding_step_completed: { step: ['training', 'nutrition', 'complete'] },
  workout_started: { mode: ['routine', 'free'] },
  workout_saved: { mode: ['routine', 'free'], source: ['live', 'historical'] },
  app_error: { code: ['startup', 'ui', 'storage', 'network', 'unknown'], screen: ['app', 'onboarding', 'workout', 'settings', 'sync'] },
  sync_cycle_result: {
    direction: ['push', 'pull'], outcome: ['success', 'unreachable', 'no_session', 'permanent', 'repairable', 'unknown'],
    pending_bucket: ['zero', '1_10', '11_100', 'over_100'], duration_bucket: ['under_1s', '1_5s', '5_30s', 'over_30s'],
  },
};
export function validEvent(e: unknown, now = Date.now()): boolean {
  if (!obj(e) || !exact(e, ['event_id', 'occurred_at', 'session_id', 'name', 'properties', 'context']) || !uuid(e.event_id) || !uuid(e.session_id)) return false;
  if (typeof e.occurred_at !== 'string' || !ISO_UTC.test(e.occurred_at)) return false;
  const at = Date.parse(e.occurred_at);
  if (!Number.isFinite(at) || at < now - 7 * 86400_000 || at > now + 300_000) return false;
  if (typeof e.name !== 'string' || !Object.hasOwn(PROPERTY_RULES, e.name) || !obj(e.properties) || !obj(e.context)) return false;
  const rules = PROPERTY_RULES[e.name];
  if (!exact(e.properties, Object.keys(rules)) || !Object.entries(rules).every(([k, vs]) => oneOf((e.properties as Obj)[k], vs))) return false;
  const c = e.context;
  return exact(c, ['version', 'build', 'platform', 'os_major', 'environment'])
    && typeof c.version === 'string' && /^\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(c.version)
    && typeof c.build === 'string' && /^\d{1,10}$/.test(c.build)
    && oneOf(c.platform, ['ios', 'android', 'other']) && int(c.os_major, 99)
    && oneOf(c.environment, ['production', 'development', 'test']);
}
async function readJson(request: Request): Promise<unknown> {
  const len = request.headers.get('content-length');
  if (len !== null && Number(len) > MAX_BODY_BYTES) throw new Error('too_large');
  if (!request.body) throw new Error('invalid_request');
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = []; let size = 0;
  try {
    while (true) {
      const part = await reader.read(); if (part.done) break;
      size += part.value.byteLength;
      if (size > MAX_BODY_BYTES) { await reader.cancel(); throw new Error('too_large'); }
      chunks.push(part.value);
    }
    const bytes = new Uint8Array(size); let at = 0;
    for (const part of chunks) { bytes.set(part, at); at += part.byteLength; }
    return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
  } finally { reader.releaseLock(); }
}
function errorOf(e: unknown): string {
  // Never send DB details, query text, constraints, or exception messages.
  const code = obj(e) && typeof e.message === 'string' ? e.message : e instanceof Error ? e.message : '';
  return ['stale_consent', 'request_conflict', 'rate_limited', 'invalid_request'].includes(code) ? code : 'unavailable';
}
export function createHandler(deps: Dependencies) {
  return async (request: Request): Promise<Response> => {
    const origin = request.headers.get('origin');
    const permitted = origin !== null && deps.allowedOrigins().includes(origin);
    const headers: Record<string, string> = { 'content-type': 'application/json', 'cache-control': 'no-store', vary: 'Origin' };
    if (permitted) {
      headers['access-control-allow-origin'] = origin;
      headers['access-control-allow-headers'] = 'authorization, apikey, content-type, x-client-info';
      headers['access-control-allow-methods'] = 'POST, OPTIONS';
    }
    const reply = (status: number, data: unknown) => new Response(status === 204 ? null : JSON.stringify(data), { status, headers });
    if (origin !== null && !permitted) return reply(403, { error: 'origin_denied' });
    if (request.method === 'OPTIONS') return reply(204, null);
    if (request.method !== 'POST') return reply(405, { error: 'method_not_allowed' });
    let body: unknown;
    try { body = await readJson(request); } catch (e) { return reply(e instanceof Error && e.message === 'too_large' ? 413 : 400, { error: 'invalid_request' }); }
    if (!obj(body) || typeof body.action !== 'string') return reply(400, { error: 'invalid_request' });
    const adminAction = ['overview', 'support'].includes(body.action);
    // A rollout kill switch stops collection/opt-ins, never the user's ability
    // to inspect or withdraw an existing preference after rollback.
    const preferenceMaintenance = body.action === 'consent_status' || (body.action === 'consent' && body.enabled === false);
    if (adminAction ? !deps.adminEnabled() : !deps.dataEnabled() && !preferenceMaintenance) return reply(503, { error: 'not_enabled' });
    const match = /^Bearer ([^\s]{1,8192})$/.exec(request.headers.get('authorization') ?? '');
    if (!match) return reply(401, { error: 'unauthorized' });
    let actor: Identity | null;
    try { actor = await deps.authenticate(match[1]); } catch { actor = null; }
    if (!actor || !uuid(actor.id)) return reply(401, { error: 'unauthorized' });
    let name: string; let args: Obj = { p_actor: actor.id };
    switch (body.action) {
      case 'consent_status':
        if (!exact(body, ['action'])) return reply(400, { error: 'invalid_request' });
        name = 'phase1_consent_status'; break;
      case 'consent':
        if (!exact(body, ['action', 'enabled', 'expected_generation', 'request_id', 'policy_version'])
          || typeof body.enabled !== 'boolean' || !int(body.expected_generation) || !uuid(body.request_id) || body.policy_version !== POLICY_VERSION) return reply(400, { error: 'invalid_request' });
        name = 'phase1_set_consent'; args = { ...args, p_enabled: body.enabled, p_expected_generation: body.expected_generation, p_request_id: body.request_id, p_policy_version: body.policy_version }; break;
      case 'ingest':
        if (!exact(body, ['action', 'generation', 'events']) || !int(body.generation) || !Array.isArray(body.events)
          || body.events.length < 1 || body.events.length > MAX_BATCH || !body.events.every(e => validEvent(e, deps.now?.() ?? Date.now()))) return reply(400, { error: 'invalid_request' });
        name = 'phase1_ingest'; args = { ...args, p_generation: body.generation, p_events: body.events }; break;
      case 'overview':
        if (!exact(body, ['action', 'days']) || ![7, 14, 30].includes(body.days as number)) return reply(400, { error: 'invalid_request' });
        name = 'phase1_admin_overview'; args = { ...args, p_aal: actor.aal, p_days: body.days, p_request_id: deps.uuid?.() ?? crypto.randomUUID() }; break;
      case 'support':
        if (!exact(body, ['action', 'query', 'reason', 'case_id']) || typeof body.query !== 'string' || body.query.length > 254
          || !(UUID.test(body.query) || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.query))
          || !oneOf(body.reason, ['account_setup', 'sync_issue', 'missing_records']) || !uuid(body.case_id)) return reply(400, { error: 'invalid_request' });
        name = 'phase1_admin_support'; args = { ...args, p_aal: actor.aal, p_query: body.query, p_reason: body.reason, p_case_id: body.case_id, p_request_id: deps.uuid?.() ?? crypto.randomUUID() }; break;
      default: return reply(400, { error: 'invalid_request' });
    }
    try {
      const data = await deps.rpc(name, args);
      if (obj(data) && typeof data.error === 'string') {
        if (data.error === 'forbidden') return reply(403, { error: 'forbidden' });
        if (data.error === 'not_found') return reply(404, { error: 'not_found' });
        return reply(503, { error: 'unavailable' });
      }
      if (!obj(data)) return reply(503, { error: 'unavailable' });
      return reply(200, data);
    } catch (e) {
      const error = errorOf(e);
      return reply(error === 'stale_consent' || error === 'request_conflict' ? 409 : error === 'rate_limited' ? 429 : error === 'invalid_request' ? 400 : 503, { error });
    }
  };
}
