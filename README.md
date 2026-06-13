# Coding Agents Init

코딩 에이전트(**Claude Code** + **Codex**) 기반 프로젝트의 초기 설정을 명령어 한 줄로 끝내는 템플릿입니다.

Claude Code를 메인 코딩 에이전트로, Codex를 독립적인 보조 검토자(second reviewer)로 묶어, 한 에이전트가 놓치는 버그와 관점을 cross-check로 보완합니다. 여기에 [Harness Engineering](https://walkinglabs.github.io/learn-harness-engineering/ko/) 원칙을 더해, 세션이 끊겨도 저장소(repository)만으로 작업을 이어갈 수 있도록 합니다.

## 왜 이 템플릿인가

코딩 에이전트로 프로젝트를 진행할 때마다 매번 비슷한 초기 세팅을 반복하게 됩니다. `CLAUDE.md`/`AGENTS.md` 작성, slash command 구성, 권한·hook 설정, 진행 상황 추적 파일 등. 이 템플릿은 그 반복을 `setup.sh` 한 번으로 끝냅니다.

동시에 두 가지 문제를 구조적으로 다룹니다.

1. **단일 에이전트의 사각지대** — 한 모델에게만 맡기면 그 모델이 못 본 실수가 그대로 남습니다. Claude Code가 작성한 결과를 Codex가 다른 추론 경로로 다시 검토(cross-check)해 버그와 설계 문제를 잡습니다.
2. **세션 간 컨텍스트 손실** — 대화가 길어지거나 세션이 바뀌면 맥락이 흩어집니다. Harness Engineering의 최소 필수 팩(progress log, feature list, bootstrap script)으로 저장소 자체를 *system of record*로 만들어 연속성을 유지합니다.

## 핵심 개념

- **Claude Code (메인)** — 이해·계획·구현·검증을 주도하는 주 인터페이스. 사용자가 직접 대화하는 에이전트입니다.
- **Codex (보조)** — Claude와 다른 모델·다른 추론 경로를 가진 *second pair of eyes*. Claude가 놓친 버그·edge case·보안 문제를 잡고, 설계(approach) 대안을 제시합니다. 기본적으로 **read-only**로 동작해 코드를 직접 고치지 않습니다.
- **Human in the loop** — Codex는 자동 실행되지 않습니다. Claude가 "제2의 눈이 필요하다"고 판단하면 **사용자에게 먼저 제안하고, 승인을 받은 뒤에만** 호출합니다. 최종 결정권은 항상 사용자에게 있습니다.
- **Harness Engineering** — 프롬프트뿐 아니라 실행 환경 자체(권한, hook, 진행 로그, 검증 절차)를 설계해 에이전트가 여러 세션에 걸쳐 일관되게 동작하도록 만드는 방법론입니다.

## 주요 기능

- `setup.sh` 한 줄로 4개 preset 중 하나를 프로젝트에 적용
- Claude Code용 slash command 다수 + Codex용 `AGENTS.md` 지침 동시 구성
- `/cross-check` — Codex read-only cross-check (bug hunting + 설계 대안)
- `/harness` — 프로젝트 harness 점검·bootstrap·개선
- `/orchestrate` — 대규모 작업을 여러 Codex worker에 병렬 분배 (고급)
- Harness 최소 필수 팩(`harness/init.sh`, `harness/claude-progress.md`, `harness/feature_list.json`) 자동 설치
- 커밋·푸시 직전 cross-check를 제안하는 비차단(non-blocking) hook
- 안전 가드 hook — 치명적 bash 명령 차단 + 편집 시 보안 패턴(eval·pickle·시크릿) 경고
- `/commit` — Conventional Commits 커밋, statusLine(모델·브랜치·디렉터리) 표시
- 엔지니어링 워크플로 스킬 — spec / TDD / debugging / security / code-review / doubt (anti-rationalization 장치 내장)
- 도메인 체크리스트·가이드(`harness/references/`) — security · testing · code-review · performance · orchestration-patterns · skill-authoring · harness-principles
- 하네스 고급 원칙 — "관찰되지 않음 ≠ 없음"(unknown 명시) · 중단조건/미지수 · 검증관점 게이트 · `/harness doctor` 진단
- 멀티 에이전트 포터빌리티 — Cursor·Gemini·Copilot 등에서도 동일 스킬 활용 (단일 Markdown 소스)

## 요구사항

| 도구 | 필수 여부 | 확인 |
|------|----------|------|
| Claude Code | 필수 | `claude` |
| git | 필수 | `git --version` |
| Codex CLI | 선택 (`/cross-check`, `/orchestrate`에 필요) | `codex --version` |

Codex가 없어도 Claude Code 기반 기능은 모두 동작합니다. Codex는 cross-check와 병렬 orchestration에만 사용되며, 설치는 사용하는 배포판에 맞게 진행하면 됩니다(예: `npm i -g @openai/codex`).

## 빠른 시작

`setup.sh`는 템플릿 파일을 대상 디렉터리로 복사하고, preset에 맞는 구성과 Harness 최소 팩을 생성합니다. 이미 존재하는 파일은 덮어쓰지 않습니다.

### 새 프로젝트

```bash
# 1. 템플릿을 임시 위치에 clone
git clone https://github.com/chasubeen/coding_agents_init.git /tmp/coding_agents_init

# 2. 새 프로젝트 폴더 생성 및 git 초기화
mkdir my-project && cd my-project && git init

# 3. preset을 골라 적용 (여기서는 research)
bash /tmp/coding_agents_init/setup.sh research .
```

### 기존 프로젝트

```bash
# 1. 템플릿을 임시 위치에 clone
git clone https://github.com/chasubeen/coding_agents_init.git /tmp/coding_agents_init

# 2. 기존 프로젝트 경로를 대상으로 preset 적용 (여기서는 dev)
bash /tmp/coding_agents_init/setup.sh dev /path/to/project
```

설정이 끝나면 해당 디렉터리에서 `claude`를 실행하면 모든 구성이 적용된 상태로 시작됩니다.

## Preset

용도별로 미리 구성된 프로파일입니다. 잘 모르겠으면 `base`로 시작하세요. 모든 preset은 Codex cross-check와 Harness 최소 팩을 공통으로 포함합니다.

| Preset | 용도 | 추가 구성 |
|--------|------|----------|
| `base` | 범용 (기본값) | 5-layer 구조 + Codex cross-check + Harness 최소 팩 + orchestrator |
| `research` | ML/DL 연구 | 6-stage experiment process, 재현성(reproducibility) 추적, claim-evidence 규율, autoresearch 루프 |
| `dev` | 소프트웨어 개발 | 멀티에이전트 file lock, `/feature` `/bugfix` `/quality-gate` |
| `industry-academia` | 산학과제 | milestone·deliverable·회의록 관리, 기업 데이터 보안 |

```bash
bash setup.sh base               # 범용
bash setup.sh research           # ML/DL 연구
bash setup.sh dev                # 소프트웨어 개발
bash setup.sh industry-academia  # 산학과제
```

`setup.sh`는 첫 인자로 preset, 둘째 인자로 대상 디렉터리(기본값 `.`)를 받습니다.

## 작동 방식

### Codex cross-check (`/cross-check`)

Claude가 작성한 변경을 Codex가 read-only로 독립 검토합니다. Codex는 Claude와 다른 모델이기 때문에, Claude가 "맞다"고 확신한 지점에서 다른 문제를 발견할 가능성이 높습니다.

```text
1. Claude가 코드 작성/수정
2. Claude가 사용자에게 cross-check 제안          (Claude 판단)
3. 사용자 승인                                   (사람이 결정)
4. Codex가 read-only로 검토 (수정 없음)
     - A. bug / edge case / 보안 hunting
     - B. 설계 / approach 대안 제시
5. Claude가 각 지적을 검증 (동의 / 오탐 판정)     (Codex도 오탐 가능)
6. 동의한 항목만 Claude가 수정
```

Codex의 출력은 결론이 아니라 입력입니다. Claude가 각 finding을 실제 코드로 다시 검증한 뒤(동의 / 부분 동의 / 오탐), 동의한 항목만 반영합니다. 오탐을 거르는 것도 cross-check의 일부입니다.

직접 호출:

```bash
/cross-check diff      # 커밋 전 변경 전체
/cross-check staged    # 스테이징된 변경만
/cross-check src/x.py  # 특정 파일
/cross-check plan      # 코드 대신 계획/설계 검토
```

cross-check를 제안하기 좋은 시점:

- 비자명한 로직/알고리즘을 새로 작성했거나 크게 바꿨을 때
- 커밋·PR 직전
- 보안·동시성·수치 안정성처럼 실수 비용이 큰 영역
- Claude 스스로 확신이 낮거나 막혔을 때
- (ML/DL) 데이터 누수, train/eval split 오염, 재현성, 지표 해석이 결과 신뢰성을 좌우할 때

커밋·푸시 직전 변경량이 크면 hook이 Claude에게 cross-check를 제안하도록 알립니다(비차단). hook은 Codex를 직접 실행하지 않습니다. 자세한 설계는 [docs/codex-collaboration.md](docs/codex-collaboration.md)를 참고하세요.

대규모 작업을 여러 Codex에 병렬 분배하는 `/orchestrate`는 고급 옵션입니다. cross-check가 정확성을 위한 것이라면 orchestrate는 속도를 위한 것으로, 격리된 git worktree에서 여러 Codex worker가 동시에 구현합니다. 평소에는 `/cross-check`만으로 충분합니다.

### Harness Engineering

세션이 끊겨도 저장소만으로 작업을 이어갈 수 있도록, 최소 필수 팩(minimum pack)을 자동 설치합니다.

| 파일 | 역할 |
|------|------|
| `harness/init.sh` | 의존성 설치 + 검증으로 실행·검증 가능한 baseline 확보 |
| `harness/claude-progress.md` | 진행 로그 — current verified state + 세션 레코드 |
| `harness/feature_list.json` | 기능 추적 — 한 번에 하나만 `in_progress`, `passing`은 검증+evidence 필수 |
| `CLAUDE.md` / `AGENTS.md` | 루트 지침 — 시작 워크플로우 + Definition of Done |

> 루트에는 `CLAUDE.md`·`AGENTS.md`(+숨김 `.claude/`·`.codex/`)와 프로젝트 코드·`skill_graph/`·`tasks/`만 두고, 나머지 하네스 스캐폴딩(hooks·orchestrator·templates·contexts·agents·tools·outputs + init.sh·claude-progress.md·feature_list.json·plan.md·handoff.md 등)은 **`harness/`** 한 곳에서 관리합니다.

`/harness` 스킬로 프로젝트의 harness를 점검·개선할 수 있습니다. 5개 핵심 서브시스템(instructions, state, verification, scope, session lifecycle)을 기준으로 진단합니다.

```bash
/harness audit     # 5개 서브시스템을 점수로 진단
/harness init      # 최소 필수 팩 생성
/harness improve   # 가장 약한 부분부터 개선
/harness evolve    # 초기 하네스 ↔ 실제 프로젝트 드리프트 감지 → 문서·규약 갱신 제안
/harness doctor    # 읽기전용 진단 — 깨진 hook 경로·구버전 설정·끊긴 참조·feature_list 규율 위반 리포트(변경 없음)
```

공식 `harness-creator` 스킬도 사용할 수 있습니다: `npx skills add walkinglabs/learn-harness-engineering --skill harness-creator`

### 5-layer 구조

세션이 바뀌어도 맥락이 유지되도록 5개 층으로 설계되어 있습니다.

| Layer | 파일 | 역할 | 갱신 주기 |
|-------|------|------|----------|
| 1 | `CLAUDE.md` | 프로젝트 규칙·구조 (헌법) | 드물게 |
| 2 | `MEMORY.md` | 영속 메모리 (결과·결정·상태) | 매 세션 |
| 3 | `tasks/`, `harness/claude-progress.md` | 할 일·교훈·진행 로그 | 매 작업 |
| 4 | `skill_graph/` | 누적 지식 wiki | 매 작업 |
| 5 | Cowork 파일 | `harness/plan.md`, `harness/handoff.md`, `harness/outputs/` | 매 세션 |

### 안전장치 (Guardrails)

실행 환경 자체에서 위험을 거르는 hook과 상태 표시를 함께 설치합니다 (anthropics/claude-code 패턴 기반).

| 구성 | 이벤트 | 동작 |
|------|--------|------|
| `bash-safety-guard` | PreToolUse (Bash) | 치명적 명령(`rm -rf /`, fork bomb, 디스크 포맷, main 강제푸시)은 **차단**, 위험 명령(`curl\|bash`, force push, `chmod 777`)은 경고 |
| `security-scan` | PreToolUse (Edit/Write) | 편집 내용의 위험 패턴(`eval`/`exec`, `pickle.load`/`torch.load`, `os.system`/`shell=True`, `yaml.load`, 하드코딩 시크릿, AWS 키) 경고 (비차단) |
| `statusLine` | — | 터미널 하단에 `모델명 ⎇ branch 디렉터리` 형식의 상태 표시 |

차단(`bash-safety-guard`)을 제외한 나머지는 모두 비차단 경고이며 흐름을 막지 않습니다. 임계값·패턴은 `harness/hooks/`의 각 스크립트와 `.claude/settings.local.json`에서 조정할 수 있습니다.

## Slash command

| Command | 설명 |
|---------|------|
| `/cross-check` | Codex cross-check (bug·설계 대안) |
| `/harness` | harness 점검·bootstrap·개선 |
| `/verify` | build·type·lint·test 종합 검증 |
| `/commit` | Conventional Commits 형식 커밋 (선택: push / PR) |
| `/todo` | 할 일 계획·체크 관리 |
| `/lessons`, `/learn` | 교훈 기록 → 지식 승격 |
| `/checkpoint` | git 기반 작업 checkpoint |
| `/compact` | context 정리 시점 안내 |
| `/orchestrate` | (고급) Codex 병렬 작업 분배 |

**엔지니어링 워크플로 스킬** (addyosmani/agent-skills 기반 이식, 한국어):

| Command | 설명 |
|---------|------|
| `/spec-driven-development` | 코드 전 게이트형 스펙 작성 (SPECIFY→PLAN→TASKS→IMPLEMENT) |
| `/test-driven-development` | Red-Green-Refactor, 테스트 피라미드, Prove-It |
| `/debugging-and-error-recovery` | 5단계 triage (reproduce→localize→reduce→fix→guard) |
| `/security-and-hardening` | OWASP/LLM 보안 점검 (+ references 체크리스트) |
| `/code-review-and-quality` | 5축 리뷰 + 심각도 라벨 (Claude 자체 구조화 리뷰) |
| `/doubt-driven-development` | 적대적 자기검증 → 필요 시 `/cross-check`로 교차모델 에스컬레이션 |

각 스킬에는 **Common Rationalizations(변명→반박) · Red Flags · 증거기반 Verification** 섹션이 박혀 있어, "되는 것 같다"는 추측을 차단합니다. 상세 레퍼런스는 `harness/references/`에 있습니다 — security · testing · code-review · performance, 그리고 **orchestration-patterns**(6 패턴 카탈로그 + 깊이≤1 규율)·**skill-authoring-guide**(스킬 작성 표준).

**Preset 전용:**

| Command | 설명 |
|---------|------|
| `/experiment` | (research) 6-stage experiment process |
| `/feature`, `/bugfix` | (dev) 기능 개발 / 버그 수정 |
| `/meeting`, `/deliverable` | (industry-academia) 회의록 / deliverable |

## 다른 코딩 에이전트에서 쓰기

스킬 본문(`.claude/skills/*/SKILL.md`)과 `AGENTS.md`는 **순수 Markdown**이라 Claude Code·Codex 외 다른 에이전트에서도 그대로 활용할 수 있습니다. 핵심 원칙은 **단일 소스, 다중 진입점** — 스킬은 한 벌만 유지하고, 슬래시 커맨드가 없는 에이전트는 `AGENTS.md`의 *Intent → Skill Mapping* 으로 의도를 스킬에 연결합니다.

<details>
<summary><b>에이전트별 적용 위치 / 예시 / 권장 세트 (펼치기)</b></summary>

### 에이전트별 적용 위치

| 에이전트 | 스킬/규칙 위치 | 비고 |
|----------|---------------|------|
| **Claude Code** | `.claude/skills/`, `CLAUDE.md`, `.claude/settings.local.json` | 기본. `setup.sh`가 자동 구성 |
| **Codex** | `AGENTS.md` (루트) | 슬래시 커맨드 없음 → `AGENTS.md`의 Intent 매핑 사용. `.codex/config.toml`의 `crosscheck`/`worker` 프로필 |
| **Cursor** | `.cursor/rules/<skill>.md` 또는 `.cursorrules` | 컨텍스트 한계상 핵심 2~3개만 |
| **Gemini CLI** | `gemini skills install` → `.gemini/skills/`, 또는 `GEMINI.md`에서 `@.claude/skills/...` import | `/plan`은 내부 충돌 → `/planning` 류로 |
| **GitHub Copilot** | 스킬: `.github/skills/<name>/SKILL.md`, 규칙: `.github/copilot-instructions.md` | 페르소나는 `.github/agents/*.agent.md` |
| **Windsurf** | `.windsurfrules` (핵심 스킬 본문 inline) | 2~3개만 |
| **opencode** | `AGENTS.md` + `.claude/skills/` 가 있으면 그대로 동작 | 내장 `skill` 툴 + Intent 매핑 |

### 빠른 적용 예시

```bash
# Cursor — 핵심 스킬만 규칙으로 복사
mkdir -p .cursor/rules
cp .claude/skills/spec-driven-development/SKILL.md .cursor/rules/spec.md
cp .claude/skills/test-driven-development/SKILL.md .cursor/rules/tdd.md
cp .claude/skills/code-review-and-quality/SKILL.md .cursor/rules/review.md
```

```text
# Gemini CLI — GEMINI.md 에서 import
@AGENTS.md
@.claude/skills/spec-driven-development/SKILL.md
```

```bash
# Codex — AGENTS.md를 읽혀 교차검증
codex exec --profile crosscheck --skip-git-repo-check "AGENTS.md를 읽고 이 변경을 교차검증해줘"
```

### 권장 최소 세트 (전부 로드 금지 — 단계별 선택)

- **시작**: `spec-driven-development`
- **개발**: `test-driven-development` (+ `debugging-and-error-recovery`)
- **머지 전**: `code-review-and-quality`, `security-and-hardening`
- **검증이 미심쩍을 때**: `doubt-driven-development` → 필요 시 Codex `/cross-check`

### 한계

- 슬래시 커맨드(`/cross-check` 등)는 Claude Code 전용입니다. 다른 에이전트에서는 해당 `SKILL.md`를 직접 참조해 같은 프로세스를 수행하세요.
- `orchestrator/`(병렬 Codex)와 hook 기반 자동 nudge는 Claude Code 환경을 가정합니다.

> 멀티 에이전트 포터빌리티 패턴은 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)에서 영감을 받았습니다.

</details>

## 프로젝트 구조

`setup.sh` 적용 후 생성되는 구조입니다.

`setup.sh`는 루트를 최소로 유지하고 하네스 스캐폴딩을 `harness/` 한 곳에 모읍니다.

```text
project/
├── CLAUDE.md               # Claude Code 프로젝트 지침 (가장 먼저 채울 파일)   [루트]
├── AGENTS.md               # Codex 운영 지침                                  [루트]
├── .claude/                # slash command + 권한/hook 설정 (Claude Code가 루트에서 로드)
│   ├── settings.local.json #   └ hook은 harness/hooks/, statusLine은 .claude/statusline.sh 참조
│   ├── statusline.sh
│   └── skills/
├── .codex/                 # Codex CLI 설정 (crosscheck / worker 프로필)
├── skill_graph/            # 누적 지식 wiki (experiments / analysis / ideas ...)  [루트]
├── tasks/                  # todo.md, lessons.md                                  [루트]
├── <프로젝트 코드>         # src/, data/, docs/ 등 — 루트 유지
└── harness/                # ── 하네스 스캐폴딩·상태 (한 곳에서 관리) ──
    ├── __init__.py         #   python -m harness.orchestrator 를 위한 패키지 마커
    ├── init.sh             #   bootstrap (의존성 설치 + 검증 baseline)
    ├── claude-progress.md  #   진행 로그
    ├── feature_list.json   #   기능 추적
    ├── plan.md             #   작업 계획
    ├── handoff.md          #   세션 인수인계
    ├── MEMORY_TEMPLATE.md  #   메모리 양식 (참고용)
    ├── contexts/           #   작업 모드 전환 (dev / research / review / cowork / autoresearch)
    ├── orchestrator/       #   Codex 병렬 실행 모듈 (python -m harness.orchestrator)
    ├── hooks/              #   자동 알림/가드 스크립트
    ├── agents/             #   planner / builder / reviewer / code-reviewer
    ├── tools/              #   skill_graph_tool.py 등
    ├── templates/          #   handoff·평가 rubric·decision-log 등 양식
    └── outputs/            #   산출물
```

> 루트에 고정되는 것: `CLAUDE.md`·`AGENTS.md`(에이전트가 루트에서 읽음)와 `.claude/`·`.codex/`(설정), 그리고 `skill_graph/`·`tasks/`·프로젝트 코드. 그 외 하네스 파일은 모두 `harness/`.

## Codex 설정

`.codex/config.toml`은 Codex CLI 프로필 참조 템플릿입니다. Codex는 전역 설정을 `~/.codex/config.toml`에서 읽으므로, 필요한 프로필을 병합하거나 `codex exec --profile <name>`으로 지정해 사용합니다.

| 프로필 | sandbox | 용도 |
|--------|---------|------|
| `crosscheck` | read-only | `/cross-check` 전용. 읽고 비평만, 파일 수정 불가 |
| `worker` | workspace-write | `/orchestrate` 전용. 격리된 worktree에서 자율 구현 |

## 설정 후 할 일

1. `harness/init.sh`의 `INSTALL_CMD` / `VERIFY_CMD` / `START_CMD`를 프로젝트에 맞게 채우고 `bash harness/init.sh`로 baseline 확인
2. `CLAUDE.md`의 주석(`<!-- -->`) 영역을 프로젝트에 맞게 작성 (Project Summary, Architecture, Commands 등)
3. 해당 디렉터리에서 `claude` 실행
4. (선택) `codex --version`으로 Codex CLI 설치 확인 — cross-check를 실제로 사용하려면 필요
5. 작업을 진행하며 `harness/claude-progress.md`와 `harness/feature_list.json`을 매 세션 갱신

## 세션 워크플로우 예시

1. 세션 시작 시 `harness/claude-progress.md`의 current verified state와 `tasks/lessons.md`를 확인
2. 작업을 `harness/feature_list.json`의 기능 단위로 진행 (한 번에 하나만 `in_progress`)
3. 비자명한 변경을 마치면 Claude가 `/cross-check`를 제안 → 승인 시 Codex 검토 → 동의 항목 수정
4. `/verify`로 build·type·lint·test 검증, evidence 기록
5. 세션 종료 전 `harness/templates/clean-state-checklist.md`를 실행하고 `harness/handoff.md`·`harness/claude-progress.md` 갱신

## FAQ

**Codex가 없어도 되나요?**
네. Claude Code 기반 기능은 모두 동작합니다. `/cross-check`와 `/orchestrate`만 Codex가 필요합니다.

**Codex가 코드를 직접 수정하나요?**
cross-check에서 Codex는 read-only로 동작하며 지적만 합니다. 실제 수정은 Claude가 수행합니다. orchestrate에서는 격리된 worktree에서만 수정합니다.

**cross-check가 자동으로 실행되나요?**
아니요. 기본은 Claude 제안 → 사용자 승인입니다. hook은 알림만 제공하며 Codex를 실행하지 않습니다.

**Preset을 잘못 골랐어요.**
다른 preset으로 `setup.sh`를 다시 실행하면 됩니다. 이미 작성된 파일(`CLAUDE.md`, `harness/init.sh` 등)은 덮어쓰지 않습니다.

**MEMORY.md는 어디 있나요?**
`~/.claude/projects/{경로를-대시로-변환}/memory/MEMORY.md`에 있으며, `setup.sh`가 초기화합니다. 예: `/home/user/my-project` → `~/.claude/projects/-home-user-my-project/memory/MEMORY.md`

## Acknowledgements

- [Learn Harness Engineering](https://walkinglabs.github.io/learn-harness-engineering/ko/) — harness 최소 필수 팩, 5개 서브시스템, `harness-creator` 방법론
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) — 멀티에이전트 포터빌리티, 엔지니어링 스킬, anti-rationalization 패턴
- [revfactory/harness](https://github.com/revfactory/harness) — 에이전트 패턴 카탈로그, 스킬 작성 가이드, harness evolve 개념
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Hooks, Context Modes, Strategic Compact, Continuous Learning 개념
