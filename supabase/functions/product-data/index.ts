import { createClient } from 'npm:@supabase/supabase-js@2.99.1';
import { createHandler } from './handler.ts';

// Same server-side Supabase Auth pattern as ask-route. Secrets never enter the
// app/browser. No user_metadata claim is used for authorization.
const url = Deno.env.get('SUPABASE_URL')!;
function platformKey(modern: string, legacy: string): string {
  try {
    const value = JSON.parse(Deno.env.get(modern) ?? '{}').default;
    if (typeof value === 'string' && value) return value;
  } catch { /* Legacy projects have the scalar environment variable. */ }
  const key = Deno.env.get(legacy);
  if (!key) throw new Error('Platform key unavailable');
  return key;
}
const server = createClient(url, platformKey('SUPABASE_SECRET_KEYS', 'SUPABASE_SERVICE_ROLE_KEY'), { auth: { persistSession: false, autoRefreshToken: false } });
const auth = createClient(url, platformKey('SUPABASE_PUBLISHABLE_KEYS', 'SUPABASE_ANON_KEY'), { auth: { persistSession: false, autoRefreshToken: false } });
Deno.serve(createHandler({
  dataEnabled: () => Deno.env.get('PRODUCT_DATA_ENABLED') === 'true',
  adminEnabled: () => Deno.env.get('PRODUCT_ADMIN_ENABLED') === 'true',
  allowedOrigins: () => (Deno.env.get('PRODUCT_ADMIN_ORIGINS') ?? '').split(',').map(s => s.trim()).filter(Boolean),
  authenticate: async (jwt) => {
    // Online getUser also rejects a deleted account whose JWT has not expired.
    const { data, error } = await auth.auth.getUser(jwt);
    if (error || !data.user) return null;
    try {
      // Parsed only AFTER getUser verified this exact JWT. The DB checks the
      // live admin allowlist every time; JWT roles are not trusted/cached.
      const claims = JSON.parse(atob(jwt.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
      if (claims.sub !== data.user.id) return null;
      return { id: data.user.id, aal: claims.aal === 'aal2' ? 'aal2' : 'aal1' };
    } catch { return null; }
  },
  rpc: async (name, args) => {
    const { data, error } = await server.rpc(name, args);
    if (error) throw error;
    return data;
  },
}));
