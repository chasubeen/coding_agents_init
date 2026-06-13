#!/bin/bash
#
# harness_doctor.sh — 하네스 읽기전용 진단 (migration report)
#
# 프로젝트 루트에서 실행한다. 아무것도 변경하지 않고, 하네스 구성의 드리프트/문제만 리포트한다.
#   bash harness/tools/harness_doctor.sh
#
# 점검: 깨진 hook 경로, 구버전 명령 경로, 누락된 최소 팩, references 끊긴 참조,
#       중복 handoff, feature_list 규율(in_progress 1개·거짓 passing), JSON 유효성.
# 종료코드: 0=문제없음/경고만, 1=FAIL 존재.
#

ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "경로 없음: $ROOT"; exit 1; }

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; N='\033[0m'
ok(){   echo -e "  ${G}[OK]${N}   $1"; }
warn(){ echo -e "  ${Y}[WARN]${N} $1"; WARN=$((WARN+1)); }
fail(){ echo -e "  ${R}[FAIL]${N} $1"; FAIL=$((FAIL+1)); }
WARN=0; FAIL=0

echo -e "${B}═══ harness doctor — $(realpath "$ROOT") ═══${N}"

# ── 1. 최소 필수 팩 ───────────────────────────────────────
echo -e "${B}[1] 최소 필수 팩${N}"
for f in CLAUDE.md AGENTS.md harness/init.sh harness/claude-progress.md harness/feature_list.json; do
    [ -f "$f" ] && ok "$f 존재" || warn "$f 없음 (→ /harness init 또는 update.sh)"
done

# ── 2. settings.local.json ────────────────────────────────
echo -e "${B}[2] .claude/settings.local.json${N}"
S=".claude/settings.local.json"
if [ ! -f "$S" ]; then
    warn "$S 없음"
else
    # JSON 유효성
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import json,sys; json.load(open('$S'))" 2>/dev/null && ok "JSON 유효" || fail "JSON 파싱 실패 — 구문 오류"
    fi
    # 구버전 명령 경로
    if grep -q "python -m orchestrator " "$S" 2>/dev/null; then
        fail "구버전 명령 'python -m orchestrator' 발견 → 'python -m harness.orchestrator' 로 갱신 필요"
    else
        ok "orchestrator 명령 경로 최신"
    fi
    # hook 스크립트 경로 실재 확인
    MISS=0
    while IFS= read -r hp; do
        [ -z "$hp" ] && continue
        if [ ! -f "$hp" ]; then fail "hook 경로 깨짐: $hp"; MISS=1; fi
    done < <(grep -oE 'bash [^"]*hooks/[A-Za-z0-9_-]+\.sh' "$S" 2>/dev/null | sed 's/^bash //')
    [ "$MISS" -eq 0 ] && ok "hook 경로 모두 실재"
    # statusLine 경로
    SL=$(grep -oE 'bash [^"]*statusline\.sh' "$S" 2>/dev/null | sed 's/^bash //' | head -1)
    if [ -n "$SL" ]; then [ -f "$SL" ] && ok "statusLine 경로 실재" || fail "statusLine 경로 깨짐: $SL"; fi
fi

# ── 3. references 끊긴 참조 ────────────────────────────────
echo -e "${B}[3] 스킬→references 참조 무결성${N}"
if [ -d .claude/skills ]; then
    BROKEN=0
    while IFS= read -r ref; do
        [ -f "$ref" ] || { fail "참조 대상 없음: $ref"; BROKEN=1; }
    done < <(grep -rhoE 'harness/references/[A-Za-z0-9_-]+\.md' .claude/skills 2>/dev/null | sort -u)
    [ "$BROKEN" -eq 0 ] && ok "references 참조 모두 실재"
else
    warn ".claude/skills 없음"
fi

# ── 4. 중복/혼란 파일 ─────────────────────────────────────
echo -e "${B}[4] 중복/혼란${N}"
if [ -f harness/handoff.md ] && [ -f harness/HANDOFF.md ]; then
    warn "handoff.md 와 HANDOFF.md 공존 — 어느 쪽이 source-of-truth인지 명확히"
else ok "handoff 단일"; fi

# ── 5. feature_list 규율 ──────────────────────────────────
echo -e "${B}[5] feature_list 규율${N}"
FL="harness/feature_list.json"
if [ -f "$FL" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "$FL" <<'PY'
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception as e: print("PARSEFAIL"); sys.exit(0)
feats=d.get("features",[])
ip=[f for f in feats if f.get("status")=="in_progress"]
print("INPROG", len(ip))
bad=[f.get("id","?") for f in feats if f.get("status")=="passing" and not (f.get("evidence") or "").strip()]
print("NOEVID", ",".join(bad))
PY
fi 2>/dev/null | while read -r tag val rest; do
    case "$tag" in
        INPROG) [ "$val" -le 1 ] && ok "in_progress ${val}개 (≤1)" || warn "in_progress ${val}개 — 한 번에 하나만 권장" ;;
        NOEVID) [ -z "$val" ] && ok "passing 항목 모두 evidence 보유" || fail "evidence 없는 passing: $val (거짓 passing)" ;;
        PARSEFAIL) fail "feature_list.json 파싱 실패" ;;
    esac
done

# ── 6. orchestrator 패키지 ────────────────────────────────
echo -e "${B}[6] orchestrator${N}"
if [ -d harness/orchestrator ]; then
    [ -f harness/__init__.py ] && ok "harness 패키지 마커 존재 (python -m harness.orchestrator)" \
        || warn "harness/__init__.py 없음 → 'python -m harness.orchestrator' 불가"
else ok "orchestrator 미사용"; fi

# ── 요약 ──────────────────────────────────────────────────
echo -e "${B}═══ 요약: FAIL ${FAIL} · WARN ${WARN} ═══${N}"
if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${Y}권고:${N} 템플릿 기계 부품 드리프트는 안전 업데이트로 정리 — sudo bash update.sh <preset> ."
    exit 1
fi
echo -e "  ${G}치명적 문제 없음.${N}"
exit 0
