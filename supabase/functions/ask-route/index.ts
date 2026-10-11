import { createClient } from "npm:@supabase/supabase-js@2.99.1";
import { createHandler, geminiRequest } from "./handler.ts";

// Jeton çevrimiçi doğrulanır: silinmiş kullanıcı JWT süresi dolmasa da reddedilir.
const url = Deno.env.get("SUPABASE_URL")!;
function platformKey(modern: string, legacy: string): string {
  try {
    const value = JSON.parse(Deno.env.get(modern) ?? "{}").default;
    if (typeof value === "string" && value) return value;
  } catch {
    /* Eski projelerde JSON secret yok; uyumlu yedek anahtar kullanılır. */
  }
  const value = Deno.env.get(legacy);
  if (!value) throw new Error("Platform key unavailable");
  return value;
}
const admin = createClient(
  url,
  platformKey("SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY"),
  {
    auth: { persistSession: false, autoRefreshToken: false },
  },
);
const auth = createClient(
  url,
  platformKey("SUPABASE_PUBLISHABLE_KEYS", "SUPABASE_ANON_KEY"),
  {
    auth: { persistSession: false, autoRefreshToken: false },
  },
);
Deno.serve(createHandler({
  enabled: () =>
    Deno.env.get("ASSISTANT_ENABLED") === "true" &&
    !!Deno.env.get("GEMINI_API_KEY"),
  authenticate: async (jwt) => {
    const { data, error } = await auth.auth.getUser(jwt);
    return error ? null : data.user?.id ?? null;
  },
  reserve: async (owner, request) => {
    const { data, error } = await admin.rpc("assistant_reserve", {
      p_owner: owner,
      p_request: request,
    });
    if (error || !data || typeof data.allowed !== "boolean") {
      throw new Error("quota");
    }
    return data;
  },
  generate: async (question) => {
    let response: Response;
    try {
      response = await fetch(
        "https://generativelanguage.googleapis.com/v1beta/interactions",
        {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-goog-api-key": Deno.env.get("GEMINI_API_KEY")!,
          },
          body: JSON.stringify(geminiRequest(question)),
          signal: AbortSignal.timeout(6000),
        },
      );
    } catch (e) {
      if (
        e instanceof DOMException &&
        (e.name === "TimeoutError" || e.name === "AbortError")
      ) throw new Error("timeout");
      throw new Error("unavailable");
    }
    if (response.status === 429) {
      await response.body?.cancel();
      throw new Error("provider_quota");
    }
    if (!response.ok) {
      await response.body?.cancel();
      throw new Error("unavailable");
    }
    return response.json();
  },
}));
