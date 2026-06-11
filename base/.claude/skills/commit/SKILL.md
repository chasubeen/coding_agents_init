---
name: commit
description: 변경사항을 분석해 Conventional Commits 형식의 커밋을 생성한다. 선택적으로 push와 PR 생성까지. 의미 단위로 쪼개 커밋하며, 커밋 전 검증을 권장.
user-invocable: true
argument-hint: "[ (없음) | push | pr | <메시지 힌트> ]"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# /commit — 구조화된 커밋

변경사항을 분석해 **Conventional Commits** 형식으로 커밋한다. 참고: anthropics/claude-code `commit-commands`.

모드: $ARGUMENTS  (없으면 커밋만)

---

## 1. 사전 점검

```bash
git status --short
git diff --stat
```

- 변경이 없으면 알리고 중단.
- 커밋 전 권장: `/verify`(빌드·테스트)와, 비자명한 변경이면 `/cross-check`(Codex 교차검증)를 먼저 제안.
  (사용자가 생략을 원하면 진행)

## 2. 변경 분석 & 의미 단위 분리

- `git diff`(스테이징 + 작업트리)를 읽고 **논리적으로 묶이는 단위**를 식별.
- 서로 무관한 변경이 섞여 있으면 **여러 커밋으로 분리** 제안 (한 커밋 = 한 의도).
- 분리 시 `git add <path>`로 해당 단위만 스테이징.

## 3. 커밋 메시지 작성 (Conventional Commits)

형식:
```
<type>(<scope>): <subject>

<body — 무엇을, 왜 (어떻게는 코드가 설명)>
```

type: `feat` | `fix` | `refactor` | `perf` | `test` | `docs` | `build` | `chore` | `exp`(실험)

규칙:
- subject는 명령형·소문자·마침표 없음, 50자 이내 권장
- body는 *왜* 바꿨는지 중심 (선택)
- 이슈/실험 연결 시 `Refs: #123` 또는 `Refs: skill_graph/experiments/...`
- **추측 금지** — 실제 diff에 근거해서만 작성
- 시크릿/대용량 산출물이 스테이징에 포함됐는지 확인 (`.env`, 데이터, 체크포인트 등 제외)

작성한 메시지를 사용자에게 보여주고 확인을 받는다.

## 4. 커밋

```bash
git commit -m "<type>(<scope>): <subject>" -m "<body>"
```

## 5. (모드별 추가)

### `push`
현재 브랜치를 push. main/master면 보호 차원에서 한 번 더 확인.
```bash
git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
```

### `pr`
push 후 PR 생성 (gh CLI 필요).
```bash
command -v gh >/dev/null 2>&1 || { echo "gh CLI 미설치 — PR 생성 생략"; }
git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill   # 또는 --title/--body 로 상세 작성
```
PR 본문에는 변경 요약 + 검증 결과(/verify, /cross-check)를 포함.

## 규칙

- feature branch 작업 권장 — main/master에 직접 커밋하려 하면 브랜치 분리를 제안.
- 커밋은 의미 단위로 작게. 거대한 한 방 커밋 지양.
- 커밋 메시지는 사용자 승인 후 실행.
- `feature_list.json`/`claude-progress.md`를 갱신했다면 같은 흐름에서 함께 커밋.
