// İsteğe bağlı: tek sentetik soru, ücretsiz Gemini; anahtar/ham çıktı yazılmaz.
import {
  geminiRequest,
  validRoute,
} from "../supabase/functions/ask-route/handler.ts";
const key = Deno.env.get("GEMINI_API_KEY");
if (!key) throw new Error("Gemini secret unavailable");
const start = performance.now();
const response = await fetch(
  "https://generativelanguage.googleapis.com/v1beta/interactions",
  {
    method: "POST",
    headers: { "content-type": "application/json", "x-goog-api-key": key },
    body: JSON.stringify(geminiRequest("Bu haftaki antrenmanlarım kaç seans?")),
    signal: AbortSignal.timeout(6000),
  },
);
if (!response.ok) {
  console.log(JSON.stringify({ status: response.status, verified: false }));
  Deno.exit(1);
}
const r = await response.json();
const text = r.steps?.filter((s: { type: string }) => s.type === "model_output")
  .flatMap((s: { content: unknown[] }) => s.content ?? []).find((
    c: { type: string },
  ) => c.type === "text")?.text;
const route = text ? JSON.parse(text) : null;
const valid = r.status === "completed" && validRoute(route) &&
  route.query === "workout_summary" && route.period === "this_week";
console.log(
  JSON.stringify({
    verified: valid,
    status: response.status,
    latency_ms: Math.round(performance.now() - start),
    model: "gemini-3.5-flash-lite",
    store: false,
  }),
);
if (!valid) Deno.exit(1);
