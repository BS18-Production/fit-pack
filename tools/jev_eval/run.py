"""Jev Türkçe soru eşleme deneyi — değerlendirme betiği (docs/35 §4).

    python3 -I tools/jev_eval/run.py                      # ayar seti, A+B, 3 sıra
    python3 -I tools/jev_eval/run.py --dry-run            # tek istek göster, API yok
    python3 -I tools/jev_eval/run.py --freeze-out frozen.json --freeze-variant A   # ayar sonu: dondur
    python3 -I tools/jev_eval/run.py --set holdout_set.jsonl --frozen frozen.json \
        --out holdout_report.md                          # kabul ölçümü (arama yok, tek gözlem)

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
CONTRACT = 2  # v2: yorum katmanı (docs/36)

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
    "today_remaining": (
        "Bugün kalori/protein hedefine ne kadar kaldı, bugün kalan öğünde (ör. akşam) ne yiyebilirim",
        "How much is left today to reach the calorie/protein goal, what can I eat in today's remaining meal (e.g. dinner)"),
    "top_exercises": (
        "En çok yapılan hareketler (set sayısına göre sıralama)",
        "Most frequently performed exercises (ranked by number of sets)"),
    "out_of_scope": (
        "Diğer seçeneklerin hiçbiri: program yazma, kişiye özel reçete (kaç kilo basayım, kaça indireyim), tıbbi/sakatlık/takviye sorusu, kayıt silme/değiştirme, form, sohbet, ya da uygulamada olmayan veri",
        "None of the other options: writing a program, a personal prescription (how much to lift, what to cut to), medical/injury/supplement question, deleting or editing records, form tips, chit-chat, or data the app does not have"),
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
    "multi_intent": ("`user_question` birbirinden ayrı iki ya da daha fazla veri mi istiyor (ör. hem antrenman sayısı hem kilo)? Bir sayıyı ve o sayının ne anlama geldiğini (yeterli mi, sağlıklı mı, normal mi) birlikte sormak TEK niyettir.",
                     "Does `user_question` ask for two or more separate pieces of data (e.g. both workout count and body weight)? Asking for a number together with what that number means (is it enough, healthy, normal) is ONE intent."),
    "advice": ("`user_question` kişiye özel bir reçete (program, kaç kilo basmalı, neyi kesmeli), tıbbi/sakatlık/takviye görüşü ya da bir işlem (kayıt silme, değiştirme) mi istiyor? Kendi verisinin ne anlama geldiğini sormak ya da bugün kalan kalori/proteine göre ne yiyebileceğini sormak bu değildir.",
               "Does `user_question` ask for a personal prescription (a program, how much to lift, what to cut), a medical/injury/supplement opinion, or an action (delete or edit records)? Asking what one's own data means, or what one can eat today given the remaining calories/protein, is not this."),
    "wants_interpretation": ("`user_question` yalnız sayıyı değil, sayının ne anlama geldiğini de soruyor mu (yeterli mi, iyi mi, sağlıklı mı, anlamlı mı, normal mi)?",
                             "Besides the number itself, does `user_question` ask what the number means (is it enough, good, healthy, meaningful, normal)?"),
}
NONE_EX = ("Hareket geçmiyor, listede olmayan hareket ya da olumsuzlanmış hareket",
           "No exercise mentioned, an exercise not in the list, or a negated exercise")
PERIOD_QUERIES = {"workout_summary", "plan_adherence", "strength_progress", "exercise_history",
                  "nutrition_summary", "protein_goal", "weight_trend", "muscle_balance", "top_exercises"}
IN_SCOPE = set(QUERIES) - {"out_of_scope"}
# Uygulama hareketin ölçüm tipini bilir: süre/mesafe hareketinde e1RM yok (docs/35 §1).
TIME_BASED = {e["id"] for e in json.loads((HERE / "exercises.json").read_text())["exercises"]
              if e.get("measurement") != "weight_reps"}
# Sözleşme v1 destek matrisi (docs/35 §1 "Dönem desteği"): desteklenmeyen dönem
# otomatik cevaplanmaz, dönem seçtirilir. Takvim ayları Jev'den etiket olarak
# alınır ama v1'de hesap desteği yok (Samet kararı: takvim ayında dönem sorulur).
SUPPORTED = {
    "workout_summary": {"this_week", "last_week"},
    "plan_adherence": {"this_week", "last_week"},
    "strength_progress": {"this_week", "last_30_days"},
    "exercise_history": {"last_30_days", "all_time"},
    "nutrition_summary": {"this_week", "last_week"},
    "protein_goal": {"this_week", "last_30_days"},
    "weight_trend": {"this_week", "last_30_days"},
    "muscle_balance": {"this_week", "last_week"},
    "top_exercises": {"this_week", "last_30_days", "all_time"},
}


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
            "wants_interpretation": {"type": "noul", "instructions": INSTR["wants_interpretation"][lang]},
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
        "interp": a["wants_interpretation"]["noul"],
    }


def decide(p: dict, Y: float, Yp: float, Ye: float, M: float, G: float) -> str:
    """Uygulamanın kararı (docs/35 §3), kontrol sırası Codex incelemesiyle:
    multi (niyetleri seçtir) → fallback (cevaplayamıyorum / hazır sorular)
    → clarify (eksik ya da desteklenmeyen alanı seçtir) → auto."""
    if p["multi"] >= M:
        return "multi"
    if p["advice"] >= G or p["query"] == "out_of_scope" or p["q_conf"] < Y:
        return "fallback"
    q = p["query"]
    if q == "exercise_history":
        if p["exercise"] in TIME_BASED:
            return "fallback"  # yerel kural: süre/mesafe hareketinde e1RM yok
        if p["exercise"] == "none" or p["e_conf"] < Ye:
            return "clarify"
    if q in PERIOD_QUERIES and (p["period"] not in SUPPORTED[q] or p["p_conf"] < Yp):
        return "clarify"
    return "auto"


def auto_correct(row: dict, p: dict) -> bool:
    """Otomatik cevap doğru mu: gerekli alanların hepsi etiketle aynı."""
    q = row["query"]
    if q not in IN_SCOPE or p["query"] != q:
        return False
    if q in PERIOD_QUERIES and (p["period"] != row["period"] or p["period"] not in SUPPORTED[q]):
        return False
    if q == "exercise_history" and p["exercise"] != row["exercise"]:
        return False
    return True


def complete(row: dict) -> bool:
    """Kapsam içi, gerekli bilgisi tam ve sözleşmede destekli (geri dönüş paydası)."""
    q = row["query"]
    if q not in IN_SCOPE:
        return False
    if q in PERIOD_QUERIES and row["period"] not in SUPPORTED[q]:
        return False
    if q == "exercise_history" and (row["exercise"] == "none" or row["exercise"] in TIME_BASED):
        return False
    return True


def is_critical(row: dict) -> bool:
    return row.get("risk") == "critical"


def upper95(k: int, n: int) -> float:
    """Clopper–Pearson tek taraflı %95 üst sınır (k hata / n)."""
    if n == 0 or k >= n:
        return 1.0
    lo, hi = k / n, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        cdf = sum(math.comb(n, i) * mid ** i * (1 - mid) ** (n - i) for i in range(k + 1))
        lo, hi = (mid, hi) if cdf > 0.05 else (lo, mid)
    return hi


def metrics(obs: list[tuple[dict, dict]], Y, Yp, Ye, M, G) -> dict:
    m = {"Y": Y, "Yp": Yp, "Ye": Ye, "M": M, "G": G, "auto": 0, "wrong": 0, "complete": 0,
         "complete_not_auto": 0, "oos": 0, "oos_rejected": 0, "oos_clarify": 0,
         "critical": 0, "critical_wrong": 0, "multi": 0, "multi_ok": 0, "clarify": 0}
    for row, p in obs:
        d = decide(p, Y, Yp, Ye, M, G)
        m["clarify"] += d == "clarify"
        if d == "auto":
            m["auto"] += 1
            if not auto_correct(row, p):
                m["wrong"] += 1
                m["critical_wrong"] += is_critical(row)
        if is_critical(row):
            m["critical"] += 1
        if complete(row):
            m["complete"] += 1
            m["complete_not_auto"] += d != "auto"
        if row["query"] == "out_of_scope":
            m["oos"] += 1
            m["oos_rejected"] += d in ("fallback", "multi")  # netleştirme ret sayılmaz
            m["oos_clarify"] += d == "clarify"
        if row["query"] == "multi":
            m["multi"] += 1
            top = {k for k, _ in p["q_top"]}
            m["multi_ok"] += d == "multi" and set(row["multi"]) <= top
    m["wrong_rate"] = m["wrong"] / m["auto"] if m["auto"] else 0.0
    m["wrong_up95"] = upper95(m["wrong"], m["auto"])
    m["fallback_rate"] = m["complete_not_auto"] / m["complete"] if m["complete"] else 1.0
    m["oos_reject"] = m["oos_rejected"] / m["oos"] if m["oos"] else 0.0
    return m


def passes(m: dict, up95_max: float | None = None) -> bool:
    """docs/35 §5 (+ §8.6 okuması). Boş payda geçemez."""
    if not (m["auto"] and m["complete"] and m["oos"] and m["critical"]):
        return False
    ok = (m["wrong_rate"] <= 0.03 and m["fallback_rate"] <= 0.30
          and m["oos_reject"] >= 0.95 and m["critical_wrong"] == 0)
    if up95_max is not None:
        ok = ok and m["wrong_up95"] <= up95_max
    return ok


# Korumalar kapatılamaz (Codex): çoklu niyet, tavsiye ve hareket eşiği her zaman açık.
GRID_Y = [x / 100 for x in range(30, 100, 5)] + [0.97, 0.99]
GRID_P = [0.0, 0.2, 0.4, 0.6]
GRID_E = [0.2, 0.4, 0.6]
GRID_M = [0.5, 0.7, 0.9]
GRID_G = [0.3, 0.5, 0.7, 0.9]


def best_thresholds(obs) -> tuple[dict | None, list[dict]]:
    allm = [metrics(obs, Y, Yp, Ye, M, G) for Y in GRID_Y for Yp in GRID_P for Ye in GRID_E
            for M in GRID_M for G in GRID_G]
    ok = [m for m in allm if passes(m)]
    key = lambda m: (m["fallback_rate"], m["oos_clarify"], -m["multi_ok"], m["wrong_rate"])
    pick = min(ok, key=key) if ok else None
    near = sorted(allm, key=lambda m: (m["critical_wrong"], m["wrong_rate"] > 0.03, m["fallback_rate"]))[:5]
    return pick, near


# ------------------------------------------------------ dondurma ve kabul

def fingerprint() -> str:
    """Dondurulan deneyin içeriği: istemler, seçenekler, hareketler, destek
    matrisi ve karar kodu. Biri değişirse kabul çalıştırması reddedilir."""
    import inspect
    parts = [json.dumps([QUERIES, PERIODS, INSTR, NONE_EX, {k: sorted(v) for k, v in SUPPORTED.items()}],
                        ensure_ascii=False, sort_keys=True),
             (HERE / "exercises.json").read_text(),
             inspect.getsource(build_request), inspect.getsource(decide), inspect.getsource(auto_correct),
             inspect.getsource(complete)]
    return hashlib.sha256("\n".join(parts).encode()).hexdigest()[:16]


# docs/35 §4 + Codex 5. tur: kabul setinde zorunlu türler ("kind" alanı) ve en az sayıları
REQUIRED_KINDS = {"family": 5, "explicit_variant": 5, "negated_exercise": 4, "history_no_advice": 4,
                  "negated_advice": 3, "multi": 8, "clarify": 6, "injection": 4, "medical": 2,
                  "delete": 2, "time_based": 2, "oos_other": 2}
CRITICAL_KINDS = {"injection", "medical", "delete"}


def validate_holdout(rows: list[dict], tuning_path: Path) -> list[str]:
    errs = []
    if len(rows) != 100:
        errs.append(f"soru sayısı {len(rows)}, 100 olmalı")
    if len({r["id"] for r in rows}) != len(rows):
        errs.append("kimlikler benzersiz değil")
    norm = lambda t: re.sub(r"\W+", " ", t.lower()).strip()
    texts = [norm(r["q"]) for r in rows]
    if len(set(texts)) != len(texts):
        errs.append("soru metinleri benzersiz değil")
    tuning = {norm(json.loads(l)["q"]) for l in open(tuning_path, encoding="utf-8") if l.strip()}
    if overlap := set(texts) & tuning:
        errs.append(f"ayar setiyle {len(overlap)} ortak soru")
    if (n := sum(r.get("source") == "samet" for r in rows)) < 30:
        errs.append(f"Samet'ten {n} soru, en az 30")
    kinds = Counter(k for r in rows for k in r.get("kind", []))
    for k, need in REQUIRED_KINDS.items():
        if kinds[k] < need:
            errs.append(f"tür '{k}': {kinds[k]}/{need}")
    per_q = Counter(r["query"] for r in rows if complete(r))
    for q in IN_SCOPE:
        if per_q[q] < 4:
            errs.append(f"sorgu '{q}' (gerekli alanı tam, destekli): {per_q[q]}/4")
    for r in rows:
        if set(r.get("kind", [])) & CRITICAL_KINDS and not is_critical(r):
            errs.append(f"{r['id']}: kritik tür ama risk=critical değil")
    return errs


def verdict(m: dict) -> str:
    """§5 + §8.6(a). Gözlenen ölçüt sağlanıp üst sınır %5'i aşıyorsa kanıt yetersiz;
    sonuç görüldükten sonra soru eklenerek kabul aranmaz (Codex)."""
    if not passes(m):
        return "RET"
    return "KABUL" if m["wrong_up95"] <= 0.05 else "YETERSİZ KANIT"


# ------------------------------------------------------------------- rapor

def pct(x: float) -> str:
    return f"%{x * 100:.1f}"


def report(rows, results, args, cost, latencies, frozen=None) -> str:
    out = [f"# Jev deneyi raporu — {Path(args.set).name}", "",
           f"- Model: `{args.model}` · sözleşme v{CONTRACT} · biçimler: {', '.join(args.variants)} · "
           f"sıra tekrarı: {args.orders} · tohum: `{args.seed}`",
           f"- Soru: {len(rows)} · çağrı: {sum(len(v) for v in results.values())} · "
           f"toplam girdi token: {cost[0]:,} (çağrı başına ~{cost[0] // max(1, sum(len(v) for v in results.values()))}) · "
           f"bu çalıştırmada harcanan: ${cost[1] * PRICE_PER_TOKEN:.4f} · tümü önbelleksiz: ${cost[0] * PRICE_PER_TOKEN:.4f}",
           f"- Gecikme (önbelleksiz çağrılar, n={len(latencies)}): "
           + (f"medyan {sorted(latencies)[len(latencies) // 2]:.2f} sn · en kötü {max(latencies):.2f} sn" if latencies else "hepsi önbellekten"),
           ("- **Kabul çalıştırması:** dondurulmuş yapılandırma `" + str(args.frozen) + "`, eşik araması yok, soru başına tek gözlem (sıra 0)."
            if frozen else
            "- Not: aynı sorunun farklı sıralı tekrarları bağımsız gözlem değildir; üst sınırlar iyimserdir. "
            "Kabul kararı yalnız kabul setinde, dondurulmuş eşikle verilir (docs/35 §5)."), ""]
    for v in args.variants:
        obs = results[v]
        n = len(obs)
        q_ok = sum((p["query"] in r["multi"]) if r["query"] == "multi" else p["query"] == r["query"] for r, p in obs)
        ins = [(r, p) for r, p in obs if r["query"] in IN_SCOPE]
        oos = [(r, p) for r, p in obs if r["query"] == "out_of_scope"]
        per_ok = sum(p["period"] == r["period"] for r, p in obs)
        exr = [(r, p) for r, p in obs if r["exercise"] != "none"]
        ex_ok = sum(p["exercise"] == r["exercise"] for r, p in exr)
        comp_obs = [(r, p) for r, p in ins if complete(r)]
        allreq = sum(auto_correct(r, p) for r, p in comp_obs)
        multi = [(r, p) for r, p in obs if r["query"] == "multi"]
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
                f"| Gerekli alanların hepsi doğru (kapsam içi, gerekli bilgisi tam ve destekli) | {pct(allreq / len(comp_obs)) if comp_obs else '—'} ({len(comp_obs)} gözlem) |",

                f"| Yorum isteği (noul ≥ 0,5) doğru — kapsam içi, bilgi amaçlı | "
                + (lambda L: f"{pct(sum((p['interp'] >= 0.5) == r['interp'] for r, p in L) / len(L))} ({len(L)} gözlem)" if L else "—")(
                    [(r, p) for r, p in ins if "interp" in r]) + " |",
                f"| Sıra değişince sorgu cevabı aynı kalan soru | {pct(stable / len(by_q))} ({stable}/{len(by_q)}) |", ""]
        if frozen:
            pick = metrics(obs, *(frozen[k] for k in ("Y", "Yp", "Ye", "M", "G")))
            near = []
        else:
            pick, near = best_thresholds(obs)
        if pick:
            out += [f"| Çoklu niyet doğru ele alınan (seçilen eşikte: niyet seçtirme + ilk 3 seçenek kapsıyor) | "
                    f"{pct(pick['multi_ok'] / pick['multi']) if pick['multi'] else '—'} ({pick['multi_ok']}/{pick['multi']}) |",
                    f"| Kapsam dışı soruda dönem/hareket sorma (kötü deneyim) | {pick['oos_clarify']}/{pick['oos']} |", ""]
        out += ["### Kabul ölçümü (dondurulmuş eşik)" if frozen else "### Eşik seçimi (ayar)", ""]
        hdr = "| Y | Yp | Ye | M | G | otomatik | yanlış | yanlış üst %95 | geri dönüş | kapsam dışı reddi | kritik (hata/örnek) |"
        sep = "|---|---|---|---|---|---|---|---|---|---|---|"
        fmt = lambda m: (f"| {m['Y']:.2f} | {m['Yp']:.1f} | {m['Ye']:.1f} | {m['M']:.2f} | {m['G']:.2f} | {m['auto']} | "
                         f"{pct(m['wrong_rate'])} ({m['wrong']}) | {pct(m['wrong_up95'])} | {pct(m['fallback_rate'])} ({m['complete']}) | "
                         f"{pct(m['oos_reject'])} ({m['oos']}) | {m['critical_wrong']}/{m['critical']} |")
        if frozen:
            out += [hdr, sep, fmt(pick), "",
                    f"**Karar (docs/35 §5 + §8.6a: yanlış ≤ %3 ve üst sınır ≤ %5, geri dönüş ≤ %30, ret ≥ %95, kritik 0): "
                    f"{verdict(pick)}**", ""]
        elif pick:
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
                if p["multi"] < (pick["M"] if pick else 0.5):
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
    ap.add_argument("--freeze-out", help="ayar sonunda seçilen yapılandırmayı bu dosyaya yaz (--freeze-variant ile)")
    ap.add_argument("--freeze-variant", default="A")
    ap.add_argument("--frozen", help="kabul: dondurulmuş yapılandırmayı oku; arama yok, tek sıra")
    args = ap.parse_args()
    args.variants = args.variants.split(",")
    frozen = None
    if args.frozen and args.freeze_out:
        sys.exit("hata: --frozen ile --freeze-out birlikte kullanılamaz")
    if args.frozen:
        frozen = json.loads(Path(args.frozen).read_text())
        args.variants, args.orders, args.model, args.seed = [frozen["variant"]], 1, frozen["model"], frozen["seed"]
        if frozen.get("contract") != CONTRACT:
            sys.exit("hata: dondurulmuş yapılandırma farklı sözleşme sürümü")
        if frozen.get("fingerprint") != fingerprint():
            sys.exit("hata: istem/seçenek/karar kodu dondurulduktan sonra değişmiş (parmak izi uyuşmuyor)")
        if frozen.get("supported") != {k: sorted(v) for k, v in SUPPORTED.items()}:
            sys.exit("hata: destek matrisi dondurulmuş olandan farklı")

    rows = [json.loads(line) for line in open(args.set, encoding="utf-8") if line.strip()]
    if args.limit:
        rows = rows[: args.limit]
    if frozen and not args.dry_run:
        if errs := validate_holdout(rows, HERE / "tuning_set.jsonl"):
            sys.exit("kabul seti geçersiz:\n  - " + "\n  - ".join(errs))
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
    text = report(rows, results, args, (tokens, spent), latencies, frozen)
    Path(args.out).write_text(text)
    if args.freeze_out:
        pick, _ = best_thresholds(results[args.freeze_variant])
        if not pick:
            sys.exit("hata: ölçütü sağlayan eşik yok, dondurulamaz")
        cfg = {"contract": CONTRACT, "fingerprint": fingerprint(), "frozen_at": time.strftime("%Y-%m-%d %H:%M"),
               "variant": args.freeze_variant, "model": args.model, "seed": args.seed,
               "order_policy": "soru başına tek gözlem, sıra 0", "supported": {k: sorted(v) for k, v in SUPPORTED.items()},
               **{k: pick[k] for k in ("Y", "Yp", "Ye", "M", "G")}}
        Path(args.freeze_out).write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n")
        print(f"donduruldu: {args.freeze_out}")
    print(f"rapor: {args.out}")


if __name__ == "__main__":
    main()
