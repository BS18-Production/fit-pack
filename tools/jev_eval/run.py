"""Jev Türkçe soru eşleme deneyi — değerlendirme betiği (docs/35 §4).

    python3 -I tools/jev_eval/run.py                      # ayar seti, A+B, 3 sıra
    python3 -I tools/jev_eval/run.py --dry-run            # tek istek göster, API yok
    python3 -I tools/jev_eval/run.py --set holdout_set.jsonl --variants B --orders 1 \
        --freeze frozen.json                              # kabul ölçümü (dondurulmuş eşik)

Anahtar: TYPESAFE_API_KEY ortam değişkeni ya da ~/.config/fitpack/typesafe.env.
Her cevap .cache/ altında tam isteğin özetiyle saklanır; yeniden çalıştırmak
ücret doğurmaz. Çıktı: report.md + results.jsonl (bu klasörde).
"""

from __future__ import annotations

import argparse
import concurrent.futures as cf
import hashlib
import json
import math
import os
import random
import re
import sys
import time
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
API = "https://api.typesafe.ai/v1/systemone"
PRICE_PER_TOKEN = 0.042 / 1_000_000  # $ / girdi token (TypeSafe Models, 2026-10)
CONTRACT = 1

# ---------------------------------------------------------------- sözleşme

QUERIES = {
    "workout_summary": (
        "Antrenman sayısı, set, hacim, süre gibi antrenman özeti",
        "Workout summary: number of sessions, sets, volume, duration"),
    "plan_adherence": (
        "Plana/programa uyum: planlanan antrenman günlerinin ne kadarı yapıldı",
        "Plan adherence: how many planned workout days were completed"),
    "strength_progress": (
        "Genel güç gelişimi: hangi hareketlerde ilerleme/güçlenme oldu",
        "Overall strength progress: which exercises improved"),
    "exercise_history": (
        "Belirli bir hareketteki ağırlık/güç gelişimi",
        "Progress history of one specific exercise (weight/strength)"),
    "nutrition_summary": (
        "Beslenme özeti: ortalama kalori/protein, kaç gün yemek kaydı girildi",
        "Nutrition summary: average calories/protein, number of days with food logs"),
    "protein_goal": (
        "Protein hedefinin tutturulduğu günler",
        "Days on which the protein goal was reached"),
    "weight_trend": (
        "Vücut ağırlığı (kilo, tartı) değişimi ve hedefe göre yönü",
        "Body weight change (scale) and direction relative to goal"),
    "muscle_balance": (
        "Kas gruplarına göre set dağılımı, hangi bölge ne kadar çalışıldı",
        "Sets per muscle group, which body part was trained how much"),
    "streak": (
        "Kaç haftadır düzenli/aralıksız antrenman yapıldığı (seri)",
        "Streak: how many consecutive weeks of regular training"),
    "out_of_scope": (
        "Diğer seçeneklerin hiçbiri: tavsiye, program yazma, tıbbi/sakatlık sorusu, kayıt silme/değiştirme, form, sohbet, ya da uygulamada olmayan veri",
        "None of the other options: advice, writing a program, medical/injury question, deleting or editing records, form tips, chit-chat, or data the app does not have"),
}
PERIODS = {
    "this_week": ("Bu hafta", "This week"),
    "last_week": ("Geçen hafta", "Last week"),
    "last_30_days": ("Son 30 gün, son 1 ay, son 4 hafta", "Last 30 days, last month, last 4 weeks"),
    "this_month": ("Bu ay (takvim ayı, ayın 1'inden bugüne)", "This calendar month (from the 1st until today)"),
    "last_month": ("Geçen ay (bir önceki takvim ayı)", "Last calendar month"),
    "all_time": ("Tüm zamanlar, baştan beri, ilk kayıttan bu yana", "All time, since the first record"),
    "unspecified": (
        "Zaman belirtilmemiş, belirsiz ya da diğer seçeneklerden biri değil (yazdan beri, son zamanlarda, geçen yıl)",
        "No time given, vague, or none of the other options (since summer, lately, last year)"),
}
INSTR = {
    "query": ("Kullanıcının `user_question` sorusu, kişisel fitness verisiyle cevaplanabilecek hangi hazır sorguya karşılık geliyor?",
              "Which predefined query, answerable from the user's own fitness data, does `user_question` ask for?"),
    "period": ("`user_question` hangi zaman dilimini kastediyor?",
               "Which time period does `user_question` refer to?"),
    "exercise": ("`user_question` belirli bir hareketten söz ediyorsa hangisi?",
                 "If `user_question` mentions a specific exercise, which one?"),
    "multi_intent": ("`user_question` birden fazla ayrı şey mi soruyor?",
                     "Does `user_question` ask for more than one separate thing?"),
    "advice": ("`user_question` kendi geçmiş kayıtlarının bir özetini değil; tavsiye, tahmin, tıbbi görüş, program ya da bir işlem (silme, değiştirme) mi istiyor?",
               "Instead of a summary of the user's own past records, does `user_question` ask for advice, a prediction, a medical opinion, a program, or an action (delete, edit)?"),
}
NONE_EX = ("Hareket geçmiyor, listede olmayan hareket ya da olumsuzlanmış hareket",
           "No exercise mentioned, an exercise not in the list, or a negated exercise")
PERIOD_QUERIES = {"workout_summary", "plan_adherence", "strength_progress", "exercise_history",
                  "nutrition_summary", "protein_goal", "weight_trend", "muscle_balance"}
IN_SCOPE = set(QUERIES) - {"out_of_scope"}
# Uygulama hareketin ölçüm tipini bilir: süre/mesafe hareketinde e1RM yok (docs/35 §1).
TIME_BASED = {e["id"] for e in json.loads((HERE / "exercises.json").read_text())["exercises"]
              if e.get("measurement") != "weight_reps"}
CRITICAL = {"claude-24", "codex-25", "codex-26", "codex-29"}  # tıbbi, silme, enjeksiyon


def exercise_options(lang: int) -> dict[str, str]:
    data = json.loads((HERE / "exercises.json").read_text())
    opts = {"none": NONE_EX[lang]}
    for e in data["exercises"]:
        opts[e["id"]] = f"{e['name']} — {e['aliases']}"
    for f in data["families"]:
        opts[f["id"]] = f["aliases"]
    return opts


def build_request(q: str, variant: str, order_seed: str, model: str) -> dict:
    lang = 0 if variant == "A" else 1
    rnd = random.Random(order_seed)

    def shuffled(d: dict[str, str]) -> dict[str, str]:
        keys = list(d)
        rnd.shuffle(keys)
        return {k: d[k] for k in keys}

    return {
        "model": model,
        "state": {"user_question": q},
        "questions": {
            "query": {"type": "choice", "instructions": INSTR["query"][lang],
                      "criteria": shuffled({k: v[lang] for k, v in QUERIES.items()})},
            "period": {"type": "choice", "instructions": INSTR["period"][lang],
                       "criteria": shuffled({k: v[lang] for k, v in PERIODS.items()})},
            "exercise": {"type": "choice", "instructions": INSTR["exercise"][lang],
                         "criteria": shuffled(exercise_options(lang))},
            "multi_intent": {"type": "noul", "instructions": INSTR["multi_intent"][lang]},
            "advice": {"type": "noul", "instructions": INSTR["advice"][lang]},
        },
    }


# ------------------------------------------------------------------ API

def api_key() -> str:
    key = os.environ.get("TYPESAFE_API_KEY")
    if not key:
        p = Path.home() / ".config" / "fitpack" / "typesafe.env"
        if p.exists():
            m = re.search(r"^TYPESAFE_API_KEY=(\S+)$", p.read_text(), re.M)
            key = m.group(1) if m else None
    if not key:
        sys.exit("hata: TYPESAFE_API_KEY yok (ortam ya da ~/.config/fitpack/typesafe.env)")
    return key


def call(req: dict, key: str, cache: Path) -> dict:
    body = json.dumps(req, ensure_ascii=False, sort_keys=False).encode()
    h = hashlib.sha256(body).hexdigest()[:24]
    cf_path = cache / f"{h}.json"
    if cf_path.exists():
        return {**json.loads(cf_path.read_text()), "cached": True}
    for attempt in range(5):
        t0 = time.monotonic()
        r = urllib.request.Request(API, data=body, method="POST", headers={
            "Authorization": f"Bearer {key}", "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(r, timeout=60) as resp:
                out = {"response": json.loads(resp.read()), "latency_s": round(time.monotonic() - t0, 3)}
                cf_path.write_text(json.dumps(out, ensure_ascii=False))
                return out
        except urllib.error.HTTPError as e:
            if e.code in (429, 529) and attempt < 4:
                time.sleep(2 ** attempt)
                continue
            raise SystemExit(f"API hatası HTTP {e.code}: {e.read()[:300].decode(errors='replace')}")
    raise SystemExit("API: yeniden deneme sınırı")


# ------------------------------------------------------------ değerlendirme

def predictions(resp: dict) -> dict:
    a = resp["answers"]
    top2 = sorted(a["query"]["probabilities"].items(), key=lambda kv: -kv[1])[:3]
    return {
        "query": a["query"]["choice"], "q_conf": a["query"]["confidence"], "q_top": top2,
        "period": a["period"]["choice"], "p_conf": a["period"]["confidence"],
        "exercise": a["exercise"]["choice"], "e_conf": a["exercise"]["confidence"],
        "multi": a["multi_intent"]["noul"],
        "advice": a["advice"]["noul"],
    }


def decide(p: dict, Y: float, Yp: float, Ye: float, M: float, G: float = 1.01) -> str:
    """Uygulamanın kararı (docs/35 §3): auto | clarify | fallback."""
    if p["query"] == "out_of_scope" or p["q_conf"] < Y or p["multi"] >= M or p["advice"] >= G:
        return "fallback"
    if p["query"] in PERIOD_QUERIES and (p["period"] == "unspecified" or p["p_conf"] < Yp):
        return "clarify"
    if p["query"] == "exercise_history" and (p["exercise"] == "none" or p["e_conf"] < Ye):
        return "clarify"
    if p["query"] == "exercise_history" and p["exercise"] in TIME_BASED:
        return "fallback"  # yerel kural: "süre takibi henüz yok"
    return "auto"


def auto_correct(row: dict, p: dict) -> bool:
    if row["query"] not in IN_SCOPE or p["query"] != row["query"]:
        return False
    if row["query"] in PERIOD_QUERIES and p["period"] != row["period"]:
        return False
    if row["query"] == "exercise_history" and p["exercise"] != row["exercise"]:
        return False
    return True


def complete(row: dict) -> bool:
    """Kapsam içi ve gerekli bilgisi tam (geri dönüş oranının paydası)."""
    if row["query"] not in IN_SCOPE:
        return False
    if row["query"] in PERIOD_QUERIES and row["period"] == "unspecified":
        return False
    if row["query"] == "exercise_history" and row["exercise"] == "none":
        return False
    return True


def upper95(k: int, n: int) -> float:
    """Clopper–Pearson tek taraflı %95 üst sınır (k hata / n)."""
    if n == 0:
        return 1.0
    if k >= n:
        return 1.0
    lo, hi = k / n, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        cdf = sum(math.comb(n, i) * mid ** i * (1 - mid) ** (n - i) for i in range(k + 1))
        lo, hi = (mid, hi) if cdf > 0.05 else (lo, mid)
    return hi


def metrics(obs: list[tuple[dict, dict]], Y, Yp, Ye, M, G=1.01) -> dict:
    auto = wrong = 0
    comp = comp_fb = 0
    oos = oos_rej = 0
    crit_wrong = 0
    clar = 0
    oos_by_clarify = 0
    for row, p in obs:
        d = decide(p, Y, Yp, Ye, M, G)
        if d == "auto":
            auto += 1
            if not auto_correct(row, p):
                wrong += 1
                if row["id"] in CRITICAL:
                    crit_wrong += 1
        if d == "clarify":
            clar += 1
        if complete(row):
            comp += 1
            if d != "auto":
                comp_fb += 1
        if row["query"] == "out_of_scope":
            oos += 1
            if d != "auto":
                oos_rej += 1
            if d == "clarify":
                oos_by_clarify += 1
    return {"Y": Y, "Yp": Yp, "Ye": Ye, "M": M, "G": G, "oos_by_clarify": oos_by_clarify, "auto": auto, "wrong": wrong,
            "wrong_rate": wrong / auto if auto else 0.0, "wrong_up95": upper95(wrong, auto),
            "fallback_rate": comp_fb / comp if comp else 0.0, "complete": comp,
            "oos_reject": oos_rej / oos if oos else 1.0, "oos": oos, "critical_wrong": crit_wrong,
            "clarify": clar}


def passes(m: dict) -> bool:
    return m["wrong_rate"] <= 0.03 and m["fallback_rate"] <= 0.30 and m["oos_reject"] >= 0.95 and m["critical_wrong"] == 0


GRID_Y = [x / 100 for x in range(0, 100, 5)] + [0.97, 0.99]
GRID_P = [0.0, 0.2, 0.4, 0.6]
GRID_M = [0.5, 0.7, 0.9, 1.01]
GRID_G = [0.3, 0.5, 0.7, 0.9, 1.01]


def best_thresholds(obs) -> tuple[dict | None, list[dict]]:
    allm = [metrics(obs, Y, Yp, Ye, M, G) for Y in GRID_Y for Yp in GRID_P for Ye in GRID_P for M in GRID_M for G in GRID_G]
    ok = [m for m in allm if passes(m)]
    # Kapsam dışı sorunun "hangi dönem?" diye netleştirmeye düşmesi kötü deneyim:
    # eşitlikte bunu az yapan eşik seçilir.
    pick = min(ok, key=lambda m: (m["fallback_rate"], m["oos_by_clarify"], m["wrong_rate"])) if ok else None
    # Kabul ölçütü sağlanmıyorsa: hata ≤ %3 iken en düşük geri dönüş (bilgi için)
    alt = [m for m in allm if m["wrong_rate"] <= 0.03 and m["critical_wrong"] == 0]
    if not alt:  # kritik 0 hiç sağlanmıyorsa onu gevşet, nedenini rapor gösterir
        alt = [m for m in allm if m["wrong_rate"] <= 0.03] or allm
    near = sorted(alt, key=lambda m: (m["critical_wrong"], m["fallback_rate"], -m["oos_reject"]))[:5]
    return pick, near


# ------------------------------------------------------------------- rapor

def pct(x: float) -> str:
    return f"%{x * 100:.1f}"


def report(rows, results, args, cost, latencies) -> str:
    out = [f"# Jev deneyi raporu — {Path(args.set).name}", "",
           f"- Model: `{args.model}` · sözleşme v{CONTRACT} · biçimler: {', '.join(args.variants)} · "
           f"sıra tekrarı: {args.orders} · tohum: `{args.seed}`",
           f"- Soru: {len(rows)} · çağrı: {sum(len(v) for v in results.values())} · "
           f"toplam girdi token: {cost[0]:,} (çağrı başına ~{cost[0] // max(1, sum(len(v) for v in results.values()))}) · "
           f"bu çalıştırmada harcanan: ${cost[1] * PRICE_PER_TOKEN:.4f} · tümü önbelleksiz: ${cost[0] * PRICE_PER_TOKEN:.4f}",
           f"- Gecikme (önbelleksiz çağrılar, n={len(latencies)}): "
           + (f"medyan {sorted(latencies)[len(latencies) // 2]:.2f} sn · en kötü {max(latencies):.2f} sn" if latencies else "hepsi önbellekten"),
           "- Not: aynı sorunun farklı sıralı tekrarları bağımsız gözlem değildir; üst sınırlar iyimserdir. "
           "Kabul kararı yalnız kabul setinde verilir (docs/35 §5).", ""]
    for v in args.variants:
        obs = results[v]
        n = len(obs)
        q_ok = sum((p["query"] in r["multi"]) if r["query"] == "multi" else p["query"] == r["query"] for r, p in obs)
        ins = [(r, p) for r, p in obs if r["query"] in IN_SCOPE]
        oos = [(r, p) for r, p in obs if r["query"] == "out_of_scope"]
        per_ok = sum(p["period"] == r["period"] for r, p in obs)
        exr = [(r, p) for r, p in obs if r["exercise"] != "none"]
        ex_ok = sum(p["exercise"] == r["exercise"] for r, p in exr)
        allreq = sum(auto_correct(r, p) for r, p in ins)
        multi = [(r, p) for r, p in obs if r["query"] == "multi"]
        pick_for_multi = best_thresholds(obs)[0]
        def multi_ok(r, p, m=pick_for_multi):
            """Çoklu soru başarısı: otomatik cevap yok, 'cevaplayamıyorum' değil,
            gösterilen ilk 3 seçenek beklenen niyetlerin hepsini kapsıyor."""
            if not m:
                return False
            d = decide(p, m["Y"], m["Yp"], m["Ye"], m["M"], m["G"])
            top = {k for k, _ in p["q_top"]}
            return d != "auto" and p["query"] != "out_of_scope" and set(r["multi"]) <= top
        by_q = defaultdict(list)
        for r, p in obs:
            by_q[r["id"]].append(p["query"])
        stable = sum(len(set(v2)) == 1 for v2 in by_q.values())
        title = "A — açıklamalar Türkçe" if v == "A" else "B — açıklamalar İngilizce"
        out += [f"## Biçim {title}", "",
                "| Ölçü | Değer |", "|---|---|",
                f"| Sorgu doğruluğu (tümü) | {pct(q_ok / n)} ({q_ok}/{n}) |",
                f"| Sorgu doğruluğu — kapsam içi | {pct(sum(p['query'] == r['query'] for r, p in ins) / len(ins))} |",
                f"| Sorgu doğruluğu — kapsam dışı | {pct(sum(p['query'] == 'out_of_scope' for r, p in oos) / len(oos)) if oos else '—'} |",
                f"| Dönem doğruluğu | {pct(per_ok / n)} |",
                f"| Hareket doğruluğu (hareketli sorular) | {pct(ex_ok / len(exr)) if exr else '—'} ({ex_ok}/{len(exr)}) |",
                f"| Gerekli alanların hepsi doğru (kapsam içi) | {pct(allreq / len(ins))} |",
                f"| Çoklu niyet noul ≥ 0,5 | {pct(sum(p['multi'] >= 0.5 for r, p in multi) / len(multi)) if multi else '—'} · kapsam içi tekli sorularda yanlış alarm {pct(sum(p['multi'] >= 0.5 for r, p in ins) / len(ins))} |",
                f"| Çoklu niyet: seçilen eşikte doğru ele alınan (oto. cevap yok + ilk 3 seçenek iki niyeti de kapsıyor) | {pct(sum(multi_ok(r, p) for r, p in multi) / len(multi)) if multi else '—'} ({sum(multi_ok(r, p) for r, p in multi)}/{len(multi)}) |",
                f"| Sıra değişince sorgu cevabı aynı kalan soru | {pct(stable / len(by_q))} ({stable}/{len(by_q)}) |", ""]
        pick, near = best_thresholds(obs)
        out += ["### Eşik seçimi (ayar)", ""]
        hdr = "| Y | Yp | Ye | M | G | otomatik | yanlış | yanlış üst %95 | geri dönüş | kapsam dışı reddi | …netleştirmeyle | kritik |"
        sep = "|---|---|---|---|---|---|---|---|---|---|---|---|"
        fmt = lambda m: (f"| {m['Y']:.2f} | {m['Yp']:.1f} | {m['Ye']:.1f} | {m['M']:.2f} | {m['G']:.2f} | {m['auto']} | "
                         f"{pct(m['wrong_rate'])} ({m['wrong']}) | {pct(m['wrong_up95'])} | {pct(m['fallback_rate'])} | "
                         f"{pct(m['oos_reject'])} | {m['oos_by_clarify']}/{m['oos']} | {m['critical_wrong']} |")
        if pick:
            out += ["Ölçütü (%3 / %30 / %95 / kritik 0) sağlayan, geri dönüşü en düşük eşik:", "", hdr, sep, fmt(pick), ""]
        else:
            out += ["**Hiçbir eşik ölçütü birlikte sağlamıyor.** En yakın 5 (önce kritik hata, sonra geri dönüş):", "", hdr, sep] + [fmt(m) for m in near] + [""]
        # Karışıklık: yanlış sorgular
        conf = Counter((r["query"], p["query"]) for r, p in obs if r["query"] != "multi" and p["query"] != r["query"])
        if conf:
            out += ["### En sık sorgu karışıklıkları", "", "| Beklenen | Jev | Kez |", "|---|---|---|"]
            out += [f"| {a} | {b} | {c} |" for (a, b), c in conf.most_common(10)] + [""]
        errs = []
        for r, p in obs:
            bad = []
            exp_q = r["query"]
            if exp_q == "multi":
                if p["multi"] < 0.5:
                    bad.append(f"çoklu niyet kaçtı (noul {p['multi']:.2f})")
            elif p["query"] != exp_q:
                bad.append(f"sorgu {p['query']} ({p['q_conf']:.2f})")
            if r["period"] != p["period"] and exp_q in PERIOD_QUERIES:
                bad.append(f"dönem {p['period']}")
            if r["exercise"] != "none" and p["exercise"] != r["exercise"] or (r["exercise"] == "none" and p["exercise"] != "none" and exp_q == "exercise_history"):
                bad.append(f"hareket {p['exercise']}")
            if bad:
                errs.append(f"| {r['id']} | {r['q']} | {exp_q} · {r['period']} · {r['exercise']} | {'; '.join(bad)} |")
        if errs:
            out += ["### Hatalı tahminler (her sıra tekrarı ayrı satır)", "", "| id | Soru | Beklenen | Jev |", "|---|---|---|---|"]
            out += sorted(set(errs)) + [""]
    return "\n".join(out)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", default=str(HERE / "tuning_set.jsonl"))
    ap.add_argument("--variants", default="A,B")
    ap.add_argument("--orders", type=int, default=3)
    ap.add_argument("--seed", default="fitpack-jev-1")
    ap.add_argument("--model", default="jev-1.13.0")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--out", default=str(HERE / "report.md"))
    args = ap.parse_args()
    args.variants = args.variants.split(",")

    rows = [json.loads(line) for line in open(args.set, encoding="utf-8") if line.strip()]
    if args.limit:
        rows = rows[: args.limit]
    if args.dry_run:
        print(json.dumps(build_request(rows[0]["q"], args.variants[0], f"{args.seed}-0-{rows[0]['id']}", args.model),
                         ensure_ascii=False, indent=2))
        return

    key = api_key()
    cache = HERE / ".cache"
    cache.mkdir(exist_ok=True)
    jobs = [(v, o, r) for v in args.variants for o in range(args.orders) for r in rows]
    results: dict[str, list] = defaultdict(list)
    tokens = spent = 0
    latencies: list[float] = []
    raw = []
    with cf.ThreadPoolExecutor(args.workers) as ex:
        futs = {ex.submit(call, build_request(r["q"], v, f"{args.seed}-{o}-{r['id']}", args.model), key, cache): (v, o, r)
                for v, o, r in jobs}
        for i, fut in enumerate(cf.as_completed(futs), 1):
            v, o, r = futs[fut]
            res = fut.result()
            p = predictions(res["response"])
            results[v].append((r, p))
            used = res["response"].get("usage", {}).get("input_tokens", 0)
            tokens += used
            if not res.get("cached"):
                latencies.append(res["latency_s"])
                spent += used
            raw.append({"variant": v, "order": o, "id": r["id"], "q": r["q"], "label": {k: r[k] for k in ("query", "period", "exercise")},
                        "pred": p, "latency_s": res["latency_s"], "model": res["response"].get("model")})
            if i % 25 == 0 or i == len(jobs):
                print(f"{i}/{len(jobs)}", flush=True)
    for v in results:
        results[v].sort(key=lambda rp: rp[0]["id"])
    raw.sort(key=lambda x: (x["variant"], x["id"], x["order"]))
    (HERE / "results.jsonl").write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in raw))
    text = report(rows, results, args, (tokens, spent), latencies)
    Path(args.out).write_text(text)
    print(f"rapor: {args.out}")


if __name__ == "__main__":
    main()
