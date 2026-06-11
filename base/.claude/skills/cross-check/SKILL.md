---
name: cross-check
description: Codex를 보조 에이전트로 호출해 Claude의 작업을 독립적으로 교차검증한다. 버그/엣지케이스/보안 헌팅과 설계·접근 대안 제시에 집중. 커밋·PR 전, 비자명한 변경 후, 막혔을 때 사용.
user-invocable: true
argument-hint: "[diff | staged | <파일경로> | plan | <자유 설명>]"
---

# /cross-check — Codex 교차검증

Claude Code(메인 에이전트)가 놓쳤을 수 있는 **버그·사각지대·다른 관점**을, 독립적인 보조 에이전트인 **Codex**에게 검토받는다.
Codex는 Claude와 다른 모델·다른 추론 경로를 갖기 때문에, "제2의 눈"으로서 Claude가 보지 못한 문제를 잡아낼 확률이 높다.

> 핵심 원칙: **Codex는 읽고 비평만 한다(read-only).** 코드를 직접 고치는 것은 Claude의 몫이다. 교차검증은 *판단을 외주 주는 것이 아니라, 더 많은 증거를 모으는 것*이다.

검토 대상: $ARGUMENTS

---

## 0. 사전 점검

```bash
command -v codex >/dev/null 2>&1 && echo "codex OK: $(codex --version 2>/dev/null)" || echo "codex MISSING"
```

`codex MISSING`이면 사용자에게 알리고 중단한다:
> Codex CLI가 설치되어 있지 않습니다. `npm i -g @openai/codex` (또는 사용 중인 배포판)으로 설치 후 다시 시도하세요. 우선은 Claude 자체 검토로 진행할 수 있습니다.

## 1. 검토 범위 결정

`$ARGUMENTS`로 범위를 정한다 (없으면 기본값 = 작업 트리 전체 diff):

| 인자 | 범위 | 수집 명령 |
|------|------|----------|
| (없음) / `diff` | 아직 커밋 안 된 모든 변경 | `git diff HEAD` |
| `staged` | 스테이징된 변경만 | `git diff --cached` |
| `<파일경로>` | 특정 파일/디렉토리 | `git diff HEAD -- <경로>` |
| `plan` | 코드가 아니라 **계획·설계** 검토 | `harness/plan.md` 또는 직전 제안 내용 |
| `<자유 설명>` | 설명된 주제에 대한 검토 | 관련 파일을 Read로 수집 |

먼저 범위에 해당하는 변경/계획을 수집하고, 비어 있으면 사용자에게 "검토할 변경이 없습니다"라고 알린다.

## 2. Codex에 교차검증 요청

수집한 컨텍스트를 임시 파일에 저장한 뒤, **read-only 샌드박스**로 Codex를 실행한다 (Codex가 파일을 고치지 못하게 보장):

```bash
mkdir -p .orchestrator
git diff HEAD > .orchestrator/_crosscheck_diff.patch   # 범위에 맞는 수집 명령으로 대체

codex exec --sandbox read-only --skip-git-repo-check "$(cat <<'PROMPT'
You are an INDEPENDENT reviewer cross-checking another AI agent's work.
Your job is to find what the other agent likely MISSED. Be skeptical and specific.

Review the change described in .orchestrator/_crosscheck_diff.patch together with the
surrounding code in this repository. Focus on TWO axes:

A. BUG HUNTING — correctness bugs, unhandled edge cases, off-by-one, race conditions,
   resource leaks, error/exception paths, security issues (injection, secrets, unsafe
   deserialization, path traversal), and broken assumptions. For ML/DL code also check:
   data leakage, train/eval split contamination, seed/reproducibility, metric/loss
   mismatch, shape/dtype/device bugs, and silent NaN/inf.

B. DESIGN ALTERNATIVES — where the chosen approach is reasonable but a different design,
   algorithm, abstraction, or trade-off would be clearly better. Argue concretely.

Rules:
- Report ONLY substantive findings. Do not invent problems to seem thorough.
- For each finding give: [SEVERITY: CRITICAL|HIGH|MEDIUM|LOW] file:line — problem — why it
  matters — concrete suggestion.
- If you genuinely find nothing in an axis, say "No findings" for that axis.
- Output plain text grouped under "## A. Bugs / Risks" and "## B. Design Alternatives".
PROMPT
)" 2>&1 | tee .orchestrator/_crosscheck_report.txt
```

> 참고: 옵션은 Codex 버전에 따라 다를 수 있다. `--sandbox`/`--skip-git-repo-check`가 거부되면 `.codex/config.toml`의 `crosscheck` 프로필(read-only) 또는 `codex exec --profile crosscheck "..."`를 사용한다. `plan` 검토 시에는 diff 대신 계획 텍스트를 프롬프트에 직접 포함한다.

## 3. Claude의 교차검증 (★ 가장 중요)

Codex의 출력은 **입력이지 결론이 아니다.** Codex 리포트를 Read로 읽고, 각 finding을 Claude가 직접 판정한다:

각 finding에 대해:
1. **검증** — 실제 코드를 Read로 확인. Codex의 주장이 사실인가? (Codex도 틀릴 수 있다. False positive를 걸러낸다.)
2. **판정** — ✅ 동의(실제 문제) / ⚠️ 부분 동의(맥락 필요) / ❌ 반박(오탐, 근거 명시)
3. **조치** — 동의한 항목은 수정안을 제시. 설계 대안은 trade-off를 정리해 사용자 판단 요청.

## 4. 결과 보고

```
CROSS-CHECK (codex) — 범위: <scope>

A. Bugs / Risks
  [CRITICAL] file:line — <요약>
     Codex 주장: ...
     Claude 판정: ✅ 동의 — <검증 근거> → 수정안: ...
  [MEDIUM]  file:line — <요약>
     Claude 판정: ❌ 오탐 — <반박 근거>

B. Design Alternatives
  - <대안> : Codex 제안 vs 현재 접근 trade-off → 권고: ...

요약: 확인된 실제 이슈 N건 / 오탐 M건 / 검토할 설계 대안 K건
다음 액션: <수정 적용 / 사용자 결정 대기 / 추가 검증>
```

## 규칙

- Codex 결과를 **무비판적으로 수용하지 않는다.** Claude가 각 항목을 검증한 뒤에만 반영한다.
- 반대로 Codex가 "문제 없음"이라 해도 Claude가 미심쩍으면 그 부분을 명시한다 (교차검증은 양방향).
- 확정된 실제 버그는 발견 즉시 `tasks/lessons.md` 승격 후보로 기록한다 (`/learn` 연동).
- read-only가 기본. Codex가 파일을 직접 수정하게 하려면 사용자 명시 승인 후 `--full-auto`를 쓰되, 이는 `/orchestrate`의 영역이다.
- `Verification Before Done`의 보조 수단 — `/verify`(정적/런타임 검증)와 함께 쓰면 사각지대가 크게 줄어든다.
