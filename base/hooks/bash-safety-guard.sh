#!/bin/bash
#
# Bash Safety Guard Hook  (PreToolUse: Bash)
# 참고: anthropics/claude-code examples/hooks/bash_command_validator
#
# Bash 도구로 실행하려는 명령을 가로채, 위험도에 따라 차단/경고한다.
#  - 치명적(복구 불가) 패턴: exit 2 로 차단 (stderr가 Claude에게 전달됨)
#  - 위험하지만 정당할 수 있는 패턴: 경고만 (exit 0, 비차단)
#
# PreToolUse hook 규약: exit 2 = 차단, exit 0 = 허용(stderr는 컨텍스트로 표시).
#

# stdin으로 들어온 도구 입력(JSON)을 통째로 받는다. command 필드가 이 안에 포함됨.
INPUT=$(cat)

# ── 1. 치명적 패턴: 즉시 차단 ───────────────────────────────
# 루트/홈 전체 삭제, fork bomb, 디스크 포맷/덮어쓰기, 루트 권한 일괄 변경 등
if echo "$INPUT" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]*\b[[:space:]]*)*-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+(/|/\*|~|\$HOME)([[:space:]]|"|$)'; then
    echo "[BLOCKED] 루트/홈 디렉터리 전체를 삭제하려는 명령으로 보입니다. 차단합니다." >&2
    echo "  의도한 것이라면 더 구체적인 경로로 한정하거나 사용자가 직접 실행하세요." >&2
    exit 2
fi
if echo "$INPUT" | grep -Eq ':\(\)\{[[:space:]]*:\|:&[[:space:]]*\};:'; then
    echo "[BLOCKED] fork bomb 패턴이 감지되었습니다. 차단합니다." >&2
    exit 2
fi
if echo "$INPUT" | grep -Eq '\bmkfs(\.[a-z0-9]+)?\b|\bdd\b[^|]*\bof=/dev/(sd|nvme|disk)|>[[:space:]]*/dev/(sd|nvme|disk)'; then
    echo "[BLOCKED] 디스크를 포맷/덮어쓰는 명령으로 보입니다. 차단합니다." >&2
    exit 2
fi
if echo "$INPUT" | grep -Eq 'chmod[[:space:]]+(-[a-zA-Z]*[Rr][a-zA-Z]*[[:space:]]+)*777[[:space:]]+/([[:space:]]|"|$)'; then
    echo "[BLOCKED] 루트('/')에 chmod 777 -R 을 적용하려는 명령입니다. 차단합니다." >&2
    exit 2
fi
# main/master 브랜치로의 강제 푸시는 히스토리 파괴 위험 → 차단
if echo "$INPUT" | grep -Eq 'git[[:space:]]+push[^|&;]*(--force|[[:space:]]-f\b)[^|&;]*(main|master)|git[[:space:]]+push[^|&;]*(main|master)[^|&;]*(--force|[[:space:]]-f\b)'; then
    echo "[BLOCKED] main/master 브랜치 강제 푸시는 히스토리를 파괴할 수 있습니다. 차단합니다." >&2
    echo "  정말 필요하면 사용자가 직접, --force-with-lease 로 검토 후 실행하세요." >&2
    exit 2
fi

# ── 2. 위험하지만 정당할 수 있는 패턴: 경고만(비차단) ────────
if echo "$INPUT" | grep -Eq '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(bash|sh)\b'; then
    echo "[WARN] 원격 스크립트를 받아 바로 실행(curl|bash)하려 합니다. 출처를 신뢰할 수 있는지 확인하세요." >&2
fi
if echo "$INPUT" | grep -Eq 'git[[:space:]]+push[^|&;]*(--force\b|--force-with-lease\b|[[:space:]]-f\b)'; then
    echo "[WARN] 강제 푸시(force push)입니다. 원격 히스토리를 덮어쓸 수 있으니 브랜치를 확인하세요." >&2
fi
if echo "$INPUT" | grep -Eq '\bsudo[[:space:]]+rm\b|\bchmod[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*777\b'; then
    echo "[WARN] 광범위한 권한/삭제 명령입니다. 대상 경로가 맞는지 한 번 더 확인하세요." >&2
fi

# 허용 (stdin 전달)
echo "$INPUT"
exit 0
