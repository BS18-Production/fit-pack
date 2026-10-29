import { exactQuery, REASONS, uuid } from './model.mjs';
export class ApiError extends Error {
  constructor(status, code = 'request_failed') { super(code); this.status = status; }
}
/** Mevcut Supabase Auth oturumu kullanılır; parola/anahtar/tokens diske yazılmaz. */
export class AdminClient {
  #fetch; #config; #token = null; #generation = 0;
  constructor(config, fetcher = globalThis.fetch.bind(globalThis)) { this.#config = config; this.#fetch = fetcher; }
  async #request(path, body, authenticated = true, method = 'POST') {
    if (authenticated && !this.#token) throw new ApiError(401);
    const headers = { apikey: this.#config.key, 'content-type': 'application/json' };
    if (authenticated) headers.authorization = `Bearer ${this.#token}`;
    const res = await this.#fetch(`${this.#config.url}${path}`, { method, headers, cache: 'no-store', credentials: 'omit', referrerPolicy: 'no-referrer', signal: AbortSignal.timeout(15000), ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
    if (!res.ok) {
      let code = 'request_failed';
      try { const b = await res.json(); if (['not_enabled', 'unauthorized', 'forbidden', 'mfa_required', 'audit_failed', 'not_found', 'invalid_request', 'unavailable', 'rate_limited'].includes(b.error)) code = b.error; } catch { /* Yanıt metni gösterilmez. */ }
      if (res.status === 401) this.clear();
      throw new ApiError(res.status, code);
    }
    if (res.status === 204) return null;
    return res.json();
  }
  async signIn(email, password) {
    this.clear();
    const generation = this.#generation;
    const data = await this.#request('/auth/v1/token?grant_type=password', { email, password }, false);
    if (generation !== this.#generation) throw new ApiError(401);
    if (typeof data.access_token !== 'string') throw new ApiError(401);
    this.#token = data.access_token;
    try {
      const user = await this.#request('/auth/v1/user', undefined, true, 'GET');
      const factor = user.factors?.find(f => f.status === 'verified' && f.factor_type === 'totp' && uuid(f.id));
      return { needsMfa: !!factor, factorId: factor?.id ?? null };
    } catch (e) { this.clear(); throw e; }
  }
  async verifyTotp(factorId, code) {
    const generation = this.#generation;
    if (!uuid(factorId) || !/^\d{6}$/.test(code)) throw new ApiError(400, 'invalid_request');
    const challenge = await this.#request(`/auth/v1/factors/${factorId}/challenge`, {});
    if (generation !== this.#generation) throw new ApiError(401);
    if (!uuid(challenge.id)) throw new ApiError(400, 'invalid_request');
    const data = await this.#request(`/auth/v1/factors/${factorId}/verify`, { challenge_id: challenge.id, code });
    if (generation !== this.#generation) throw new ApiError(401);
    if (typeof data.access_token !== 'string') throw new ApiError(401);
    this.#token = data.access_token;
  }
  overview(days) {
    if (![7, 14, 30].includes(days)) throw new ApiError(400, 'invalid_request');
    return this.#request('/functions/v1/product-data', { action: 'overview', days });
  }
  support(query, reason, caseId) {
    const q = exactQuery(query);
    if (!q || !Object.hasOwn(REASONS, reason) || !uuid(caseId)) throw new ApiError(400, 'invalid_request');
    return this.#request('/functions/v1/product-data', { action: 'support', query: q, reason, case_id: caseId });
  }
  async signOut() {
    try { if (this.#token) await this.#request('/auth/v1/logout?scope=local', {}); } catch { /* Bellek yine de temizlenir. */ } finally { this.clear(); }
  }
  clear() { this.#generation++; this.#token = null; }
}
