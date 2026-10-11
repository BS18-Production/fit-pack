import frozen from "./frozen_router.json" with { type: "json" };

type Route = {
  query: string;
  period: string;
  exercise: string;
  multi_intent: boolean;
  advice: boolean;
  wants_interpretation: boolean;
  ambiguous: boolean;
  alternatives: string[];
};
type Reservation = { allowed: boolean; error?: string; reset_at?: string };
export type Dependencies = {
  authenticate: (jwt: string) => Promise<string | null>;
  reserve: (owner: string, request: string) => Promise<Reservation>;
  generate: (question: string) => Promise<unknown>;
  enabled: () => boolean;
};
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const keys = Object.keys(frozen.schema.properties);
const properties = frozen.schema.properties;
export function validRoute(a: unknown): a is Route {
  if (!a || typeof a !== "object" || Array.isArray(a)) return false;
  const j = a as Record<string, unknown>;
  return Object.keys(j).length === keys.length && keys.every((k) => k in j) &&
    properties.query.enum.includes(j.query as string) &&
    properties.period.enum.includes(j.period as string) &&
    properties.exercise.enum.includes(j.exercise as string) &&
    ["multi_intent", "advice", "wants_interpretation", "ambiguous"].every((k) =>
      typeof j[k] === "boolean"
    ) &&
    Array.isArray(j.alternatives) && j.alternatives.length <= 2 &&
    j.alternatives.every((v) => properties.query.enum.includes(v));
}
export function geminiRequest(question: string) {
  return {
    model: frozen.model,
    store: false,
    system_instruction: frozen.system_instruction,
    input: `<user_question>${question}</user_question>`,
    response_format: {
      type: "text",
      mime_type: "application/json",
      schema: frozen.schema,
    },
    generation_config: frozen.generation_config,
  };
}
// Savunma: istemci atlanırsa aynı kesin süzgeçler sunucuda da uygulanır.
export function blocked(question: string): boolean {
  const t = question.toLowerCase();
  return [
    /[{}]/u,
    /\b(query|period|confidence|exercise|criteria|noul|choice)\s*[=:]/u,
    /\b[a-z]+_[a-z_]+\b/u,
    /^\s*(sistem|system|yönetici|admin|developer|geliştirici)\b[^\n]{0,20}[:：]/u,
    /(talimat|kural|komut|instruction|rule)[\p{L}\p{N}_]*[^\p{L}\p{N}_]+([\p{L}\p{N}_]+[^\p{L}\p{N}_]+){0,3}(unut|boşver|yok say|görmezden|ignore|forget)/u,
    /(unut|boşver|yok say|görmezden gel|ignore|forget)[\p{L}\p{N}_]*[^\p{L}\p{N}_]+([\p{L}\p{N}_]+[^\p{L}\p{N}_]+){0,3}(talimat|kural|instruction|rule)/u,
    /\b(prompt|jailbreak)\b/u,
    /[\w.+-]+@[\w.-]+\.[a-z]{2,}/u,
    /(?:\+?\d[\s()-]*){10,}/u,
    /(?<![\p{L}\p{N}_])(hiv|aids|diyabet|diabetes|kanser|cancer|hamile|pregnan|depresyon|depression|hastal|sakat|injur|diagnos|teşhis|ilac|ilaç)[\p{L}]*/u,
    /\d+(?:[.,]\d+)?\s*(?:kg|kilo|cm|kcal|kalori|gram|mg)\b/u,
  ].some((r) => r.test(t));
}
const headers = {
  "content-type": "application/json",
  "cache-control": "no-store",
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, apikey, content-type, x-client-info",
};
function response(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers });
}
export function createHandler(deps: Dependencies) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== "POST") {
      return response(405, { error: "invalid_request" });
    }
    const match = /^Bearer (\S+)$/i.exec(
      request.headers.get("authorization") ?? "",
    );
    if (!match) return response(401, { error: "unauthorized" });
    let owner: string | null;
    try {
      owner = await deps.authenticate(match[1]);
    } catch {
      return response(401, { error: "unauthorized" });
    }
    if (!owner) return response(401, { error: "unauthorized" });
    if (!deps.enabled()) return response(503, { error: "disabled" });
    let j: Record<string, unknown>;
    try {
      // Akış sınırı: Content-Length olmadan da en çok 4 KiB okunur.
      const reader = request.body?.getReader();
      if (!reader) return response(400, { error: "invalid_request" });
      let bytes = 0;
      const chunks: Uint8Array[] = [];
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        bytes += value.length;
        if (bytes > 4096) {
          await reader.cancel();
          return response(413, { error: "invalid_request" });
        }
        chunks.push(value);
      }
      const body = new Uint8Array(bytes);
      let offset = 0;
      for (const c of chunks) {
        body.set(c, offset);
        offset += c.length;
      }
      j = JSON.parse(new TextDecoder().decode(body));
    } catch {
      return response(400, { error: "invalid_request" });
    }
    if (
      !j || typeof j !== "object" || Array.isArray(j) ||
      Object.keys(j).length !== 3 ||
      j.contract_version !== 2 || typeof j.question !== "string" ||
      !j.question.trim() ||
      [...j.question].length > 500 || typeof j.request_id !== "string" ||
      !uuid.test(j.request_id)
    ) return response(400, { error: "invalid_request" });
    if (blocked(j.question)) return response(400, { error: "invalid_request" });
    let reservation: Reservation;
    try {
      reservation = await deps.reserve(owner, j.request_id);
    } catch {
      return response(503, { error: "unavailable" });
    }
    if (!reservation.allowed) {
      return response(reservation.error === "duplicate_request" ? 409 : 429, {
        error: reservation.error ?? "unavailable",
        reset_at: reservation.reset_at,
      });
    }
    const start = performance.now();
    let raw: unknown;
    try {
      raw = await deps.generate(j.question);
    } catch (e) {
      const code = e instanceof Error ? e.message : "";
      return response(
        code === "provider_quota" ? 429 : code === "timeout" ? 504 : 502,
        {
          error: code === "provider_quota" || code === "timeout"
            ? code
            : "unavailable",
        },
      );
    }
    try {
      const r = raw as {
        status: string;
        steps?: { type: string; content?: { type: string; text: string }[] }[];
        usage?: Record<string, number>;
      };
      if (r.status !== "completed") {
        return response(502, { error: "invalid_response" });
      }
      const text = r.steps?.filter((s) => s.type === "model_output").flatMap(
        (s) => s.content ?? [],
      ).find((c) => c.type === "text")?.text;
      const route = text ? JSON.parse(text) : null;
      if (!validRoute(route)) {
        return response(502, { error: "invalid_response" });
      }
      const token = (key: string) =>
        Number.isSafeInteger(r.usage?.[key]) && r.usage![key] >= 0
          ? r.usage![key]
          : null;
      return response(200, {
        request_id: j.request_id,
        contract_version: 2,
        model: frozen.model,
        fingerprint: frozen.fingerprint,
        route,
        latency_ms: Math.round(performance.now() - start),
        input_tokens: token("total_input_tokens"),
        output_tokens: token("total_output_tokens"),
      });
    } catch {
      return response(502, { error: "invalid_response" });
    }
  };
}
