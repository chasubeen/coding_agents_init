#!/bin/bash
#
# Claude Code Status Line
# settings.local.json 의 "statusLine" 에서 호출된다.
# Claude Code가 세션 정보(JSON)를 stdin으로 전달하면, 한 줄짜리 상태 표시를 출력한다.
# 표시 내용: 모델명 | git 브랜치 | 현재 디렉터리명
#
# 참고: anthropics/claude-code (statusLine 설정)
#

# stdin의 JSON에서 모델명과 작업 디렉터리를 추출 (python3로 안전하게 파싱).
# 모델명에 공백이 있으므로(예: "Opus 4.8") 탭(\t)으로 구분해 읽는다.
INPUT=$(cat)
IFS=$'\t' read -r MODEL CWD <<EOF
$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print("Claude\t.")
    sys.exit(0)
model = (d.get("model") or {}).get("display_name") or "Claude"
ws = d.get("workspace") or {}
cwd = ws.get("current_dir") or d.get("cwd") or "."
print(f"{model}\t{cwd}")
' 2>/dev/null)
EOF

# 현재 디렉터리 basename
DIR_NAME=$(basename "${CWD:-$PWD}")

# git 브랜치 (git repo가 아니면 생략). --show-current는 커밋 전(unborn)에도 브랜치명 반환.
BRANCH=$(git -C "${CWD:-$PWD}" branch --show-current 2>/dev/null)

# 출력 조립
LINE="${MODEL:-Claude}"
[ -n "$BRANCH" ] && LINE="$LINE | ⎇ $BRANCH"
LINE="$LINE | $DIR_NAME"

printf '%s' "$LINE"
