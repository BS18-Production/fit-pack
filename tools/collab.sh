#!/usr/bin/env bash
# Claude ↔ Codex yazışması. Her mesaj ve cevap ana klasördeki
# collab/threads/<konu>.md dosyasına yazılır (worktree'den çağrılsa da tek
# merkez); Samet bu dosyayı okuyarak ya da `watch` ile izler. Karşı taraf
# SALT OKUMA modunda, çağrının yapıldığı çalışma kopyasında çalışır.
#
#   tools/collab.sh new    <konu> "<başlık>"   yeni yazışma dosyası
#   tools/collab.sh codex  <konu> "<mesaj>"    Claude → Codex (cevap dosyaya)
#   tools/collab.sh claude <konu> "<mesaj>"    Codex → Claude (cevap dosyaya)
#   tools/collab.sh watch  <konu>              dosyayı canlı izle (Samet)
#   tools/collab.sh list                       yazışmaları listele
#   tools/collab.sh ui                         izleme ekranı (tarayıcıda)
#
# Mesaj "-" ise stdin'den okunur. Kurallar: collab/README.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"   # çağrılan çalışma kopyası
MAIN="$(dirname "$(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir)")"
DIR="$MAIN/collab/threads"
mkdir -p "$DIR"

now() { date '+%Y-%m-%d %H:%M'; }
die() { echo "hata: $*" >&2; exit 1; }

thread_file() {
  [[ "$1" =~ ^[a-z0-9-]+$ ]] || die "konu adı yalnız küçük harf, rakam, tire: $1"
  echo "$DIR/$1.md"
}

read_msg() { if [[ "$1" == "-" ]]; then cat; else printf '%s' "$1"; fi; }

append() { # dosya, gönderen, alıcı, metin
  printf '\n### %s → %s · %s\n\n%s\n' "$2" "$3" "$(now)" "$4" >>"$1"
}
status() { printf '\n> _%s · %s_\n' "$2" "$(now)" >>"$1"; log_event status "" "" "$2"; }

# İzleme ekranı için makinece okunur kayıt: .<konu>.events.jsonl (saniye
# hassasiyeti + oturum kimlikleri; ekran bunlarla iki tarafın oturum
# kayıtlarından okunan dosyaları, aramaları ve komutları eşler).
EVENTS=""
log_event() { # tür, gönderen, alıcı, metin, [çağıran oturum], [cevaplayan oturum]
  [[ -n "$EVENTS" ]] || return 0
  python3 -I -c 'import json,sys,datetime
k,f,t,x,cs,rs=sys.argv[1:7]
print(json.dumps({"ts":datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
  "kind":k,"from":f,"to":t,"text":x,"caller_session":cs,"responder_session":rs},ensure_ascii=False))' \
    "$1" "$2" "$3" "$4" "${5:-}" "${6:-}" >>"$EVENTS"
}
caller_session() { # gönderen
  if [[ "$1" == Claude ]]; then echo "${CLAUDE_CODE_SESSION_ID:-}"; else echo "${CODEX_THREAD_ID:-}"; fi
}

# Karşı tarafa giden her mesajın başına eklenen sabit bağlam.
preamble() { # gönderen, dosya
  cat <<EOF
[Fit Pack ortak yazışma — $1 yazıyor]
Yazışmanın tamamı: $2 (önceki turları oradan okuyabilirsin).
Kurallar: collab/README.md. Salt okuma modundasın; dosya değiştirme.
Yeni collab.sh çağrısı başlatma; yalnız bu mesaja cevap ver — kaydı çağıran
betik yapar. Kısa ve madde madde yaz. Karar Samet'indir; karar gerekiyorsa
cevabının sonuna "Samet'e soru:" başlığıyla ekle.
EOF
}

# Konu başına tek çağrı: mesaj eklenmeden önce kilit alınır.
TMP=""; LOCK=""; THREAD=""; DONE=0; CHILD=""
cleanup() {
  local rc=$?
  if [[ -n "$CHILD" ]] && kill -0 "$CHILD" 2>/dev/null; then
    kill -TERM "$CHILD" 2>/dev/null; wait "$CHILD" 2>/dev/null || true
  fi
  [[ -n "$TMP" ]] && rm -rf "$TMP"
  if [[ -n "$THREAD" && $DONE -eq 0 ]]; then
    if [[ $rc -eq 130 || $rc -eq 143 ]]; then status "$THREAD" "iptal edildi"
    else status "$THREAD" "başarısız (çıkış $rc)"; fi
  fi
  [[ -n "$LOCK" ]] && rmdir "$LOCK" 2>/dev/null
  exit $rc
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Alt süreç arka planda + wait: sinyal hemen işlenir, cleanup onu sonlandırır.
run() { # çıktı dosyası, komut...
  local out="$1"; shift
  "$@" </dev/null >"$out" 2>"$out.err" & CHILD=$!
  local rc=0; wait "$CHILD" || rc=$?
  CHILD=""; return $rc
}

begin() { # konu, gönderen, alıcı, mesaj
  local f; f="$(thread_file "$1")"
  [[ -e "$f" ]] || die "önce: new $1 \"<başlık>\""
  mkdir "$DIR/.$1.lock" 2>/dev/null || die "bu konuda süren bir çağrı var ($DIR/.$1.lock)"
  LOCK="$DIR/.$1.lock"
  TMP="$(mktemp -d)"
  THREAD="$f"; EVENTS="$DIR/.$1.events.jsonl"
  append "$f" "$2" "$3" "$4"
  log_event message "$2" "$3" "$4" "$(caller_session "$2")"
  [[ "$ROOT" != "$MAIN" ]] && status "$f" "çalışma kopyası: $ROOT"
  return 0
}

finish() { # dosya, gönderen, alıcı, cevap, cevaplayan oturum
  [[ -n "$4" ]] || die "$2 boş cevap verdi"
  append "$1" "$2" "$3" "$4"
  log_event message "$2" "$3" "$4" "" "${5:-}"
  DONE=1
  printf '%s\n' "$4"
}

# Codex hatasının sebebini (ör. kullanım limiti) yazışmaya ve ekrana taşı.
codex_fail() {
  local why
  why="$(grep -h -o -E 'You.ve hit your usage limit[^"]*|"message":"[^"]{1,200}' \
    "$TMP/log" "$TMP/log.err" 2>/dev/null | tail -1)"
  why="${why#\"message\":\"}"
  tail -5 "$TMP/log.err" >&2
  [[ -n "$why" ]] && status "$THREAD" "Codex hatası: $why"
  die "codex başarısız${why:+: $why}"
}

save_sid() { # dosya, kimlik — atomik
  [[ "$2" =~ ^[0-9a-f-]{36}$ ]] || die "geçersiz oturum kimliği: $2"
  printf '%s\n' "$2" >"$1.tmp" && mv "$1.tmp" "$1"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  new)
    [[ $# -ge 2 ]] || die "kullanım: new <konu> \"<başlık>\""
    f="$(thread_file "$1")"
    # noclobber: eşzamanlı iki new aynı dosyayı ezemez
    ( set -o noclobber
      printf '# %s\n\n- Başlangıç: %s\n- Katılanlar: Claude Code, Codex · izleyen/karar: Samet\n' \
        "$2" "$(now)" >"$f" ) 2>/dev/null || die "zaten var: $f"
    EVENTS="$DIR/.$1.events.jsonl"; log_event created "" "" "$2"
    echo "$f"
    ;;

  codex) # Claude → Codex
    [[ $# -ge 2 ]] || die "kullanım: codex <konu> \"<mesaj>\""
    msg="$(read_msg "$2")"
    begin "$1" Claude Codex "$msg"
    sid_file="$DIR/.$1.codex-session"
    prompt="$(preamble Claude "$THREAD")"$'\n\n'"$msg"
    cd "$ROOT"
    common=(-c approval_policy='"never"' -o "$TMP/last")
    if [[ -s "$sid_file" ]]; then
      run "$TMP/log" codex exec resume "$(cat "$sid_file")" -c sandbox_mode='"read-only"' \
        "${common[@]}" "$prompt" \
        || codex_fail
    else
      run "$TMP/log" codex exec -s read-only -C "$ROOT" --add-dir "$DIR" --json \
        "${common[@]}" "$prompt" || codex_fail
      sid="$(python3 -I -c 'import json,sys
for l in open(sys.argv[1]):
    try: e=json.loads(l)
    except ValueError: continue
    if e.get("type")=="thread.started": print(e["thread_id"]); break' "$TMP/log")"
      save_sid "$sid_file" "$sid"
    fi
    finish "$THREAD" Codex Claude "$(cat "$TMP/last" 2>/dev/null)" "$(cat "$sid_file")"
    ;;

  claude) # Codex → Claude
    [[ $# -ge 2 ]] || die "kullanım: claude <konu> \"<mesaj>\""
    msg="$(read_msg "$2")"
    begin "$1" Codex Claude "$msg"
    sid_file="$DIR/.$1.claude-session"
    prompt="$(preamble Codex "$THREAD")"$'\n\n'"$msg"
    cd "$ROOT"
    # Salt okuma: yalnız okuma araçları, MCP sunucusu yok; iç içe çağrı izni.
    ro=(--tools "Read,Glob,Grep" --strict-mcp-config --add-dir "$DIR"
        --permission-mode plan --output-format json)
    if [[ -s "$sid_file" ]]; then
      run "$TMP/out" env -u CLAUDECODE claude -p --resume "$(cat "$sid_file")" \
        "${ro[@]}" "$prompt" || { tail -20 "$TMP/out.err" >&2; die "claude başarısız"; }
    else
      sid="$(uuidgen | tr 'A-Z' 'a-z')"
      run "$TMP/out" env -u CLAUDECODE claude -p --session-id "$sid" \
        "${ro[@]}" "$prompt" || { tail -20 "$TMP/out.err" >&2; die "claude başarısız"; }
      save_sid "$sid_file" "$sid"
    fi
    reply="$(python3 -I -c 'import json,sys
d=json.load(open(sys.argv[1]))
if d.get("is_error"): sys.exit("claude hata: "+str(d.get("result")))
print(d.get("result",""))' "$TMP/out")" || die "claude cevabı okunamadı"
    finish "$THREAD" Claude Codex "$reply" "$(cat "$sid_file")"
    ;;

  watch)
    [[ $# -ge 1 ]] || die "kullanım: watch <konu>"
    tail -n +1 -f "$(thread_file "$1")"
    ;;

  list)
    shopt -s nullglob
    files=("$DIR"/*.md)
    [[ ${#files[@]} -eq 0 ]] && { echo "(yazışma yok)"; exit 0; }
    ls -1t "${files[@]}" | while read -r p; do
      printf '%-32s %s\n' "$(basename "$p" .md)" "$(head -1 "$p" | sed 's/^# //')"
    done
    ;;

  ui)
    exec python3 -I "$ROOT/tools/collab_viewer/server.py" --threads "$DIR" "$@"
    ;;

  *)
    sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
