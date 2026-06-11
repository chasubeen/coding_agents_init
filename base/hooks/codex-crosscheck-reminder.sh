#!/bin/bash
#
# Codex Cross-Check Reminder Hook  (Model B: Claude 제안 → 사용자 승인)
# PreToolUse (Bash) 에서 실행 — 중요 시점(commit/push)에 "교차검증 제안"을 Claude에게 nudge
#
# 이 훅은 Codex를 직접 실행하지 않는다(비차단). 단지 비자명한 변경을 커밋/푸시하려는
# 순간에, Claude가 사용자에게 `/cross-check`(Codex 교차검증)를 *제안하도록* 상기시킨다.
# 최종 실행 결정은 항상 사용자 승인에 달려 있다.
#
# 환경변수:
#   CROSSCHECK_MIN_LINES — 교차검증을 제안할 최소 변경 라인 수 (기본: 30)
#

INPUT=$(cat)
MIN_LINES="${CROSSCHECK_MIN_LINES:-30}"

# git commit 또는 git push 의도가 감지될 때만 동작
if echo "$INPUT" | grep -qE "git (commit|push)"; then
    # 변경 규모 측정 (작업트리 + 스테이징, HEAD 대비)
    CHANGED=$(git diff HEAD --numstat 2>/dev/null | awk '{a+=$1; d+=$2} END {print a+d+0}')

    if [ "${CHANGED:-0}" -ge "$MIN_LINES" ]; then
        echo "[Cross-Check] ${CHANGED}줄 변경 — 커밋/푸시 전 Codex 교차검증을 사용자에게 제안하세요." >&2
        echo "  사용자 승인 시 실행: /cross-check diff" >&2
        echo "  (Codex가 Claude의 사각지대·버그·설계 대안을 독립 검토. 이미 했거나 자명하면 생략)" >&2
    fi
fi

# stdin 전달 (비차단)
echo "$INPUT"
