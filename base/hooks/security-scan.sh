#!/bin/bash
#
# Security Scan Hook  (PreToolUse: Edit|Write)
# 참고: anthropics/claude-code plugins/security-guidance
#
# 파일을 쓰거나 고치기 직전, 새 내용에 위험한 코드 패턴이 있으면 경고한다(비차단).
# 차단하지 않고 경고만 하므로(exit 0), 정당한 사용일 때 흐름을 막지 않는다.
# ML/DL 환경을 고려해 pickle/torch.load(역직렬화 RCE) 등을 포함.
#

INPUT=$(cat)

# 편집 본문(Edit: new_string / Write: content)을 JSON에서 추출한다.
# raw JSON을 직접 grep하면 따옴표가 \" 로 escape되어 패턴이 어긋나므로,
# python3로 파싱해 실제 텍스트를 얻은 뒤 검사한다.
CONTENT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input", d) if isinstance(d, dict) else {}
print(ti.get("new_string") or ti.get("content") or "")
' 2>/dev/null)

# 파싱 실패/빈 내용이면 종료
[ -z "$CONTENT" ] && { echo "$INPUT"; exit 0; }

WARN=()

# 임의 코드 실행
echo "$CONTENT" | grep -Eq '\beval\(|\bexec\(' && \
    WARN+=("eval()/exec() — 임의 코드 실행 위험. 입력이 신뢰 가능한지 확인")
echo "$CONTENT" | grep -Eq '\bos\.system\(|subprocess\.[A-Za-z_]+\([^)]*shell[[:space:]]*=[[:space:]]*True' && \
    WARN+=("os.system()/shell=True — 셸 인젝션 위험. 인자를 리스트로 전달하고 shell=False 권장")

# 안전하지 않은 역직렬화 (ML에서 특히 빈번)
echo "$CONTENT" | grep -Eq '\bpickle\.loads?\(|\bcPickle\.|\btorch\.load\(' && \
    WARN+=("pickle.load/torch.load — 신뢰할 수 없는 파일은 RCE 위험. torch.load는 weights_only=True 사용")
echo "$CONTENT" | grep -Eq '\byaml\.load\(' && \
    ! echo "$CONTENT" | grep -Eq 'yaml\.load\([^)]*Safe' && \
    WARN+=("yaml.load() — SafeLoader 없이 사용 시 임의 객체 생성 위험. yaml.safe_load() 권장")

# 하드코딩된 시크릿
echo "$CONTENT" | grep -Eiq '(api_?key|secret|password|passwd|token)[[:space:]]*[:=][[:space:]]*["'\''][^"'\'' ]{6,}["'\'']' && \
    WARN+=("하드코딩된 시크릿으로 보이는 값 — 환경변수/시크릿 매니저로 분리 권장")
echo "$CONTENT" | grep -Eq 'AKIA[0-9A-Z]{16}' && \
    WARN+=("AWS Access Key로 보이는 문자열 — 커밋 금지, 즉시 폐기/교체")

# 경고 출력 (비차단)
if [ ${#WARN[@]} -gt 0 ]; then
    echo "[Security] 편집 내용에서 점검할 패턴이 발견되었습니다:" >&2
    for w in "${WARN[@]}"; do
        echo "  - $w" >&2
    done
    echo "  의도된 사용이면 무시하고 진행하세요. (이 훅은 차단하지 않습니다)" >&2
fi

# 통과 (stdin 전달)
echo "$INPUT"
exit 0
