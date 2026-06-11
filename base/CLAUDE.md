# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Principle

<!-- 프로젝트의 핵심 철학. Claude가 모든 판단의 기준으로 삼을 원칙. -->
**[여기에 프로젝트의 핵심 원칙을 작성하세요]**

## Project Summary

<!-- 프로젝트를 한 문단으로 설명. Claude가 맥락을 빠르게 파악하는 데 사용. -->

## Context Engineering

<!-- 프롬프트는 "지금 이렇게 말할지"의 문제, Context는 "무엇을 같이 읽힐지"의 문제 -->

이 프로젝트에서 Claude의 행동을 결정하는 것은 단일 프롬프트가 아니라 **문맥의 조합**이다:

- **CLAUDE.md** — 프로젝트 규칙과 구조 (헌법)
- **rules/** — 경로별·스코프별 세부 규칙
- **harness/hooks/** — 자동 실행 품질 관리
- **harness/templates/** — 산출물 구조 표준
- **harness/contexts/** — 세션 모드별 행동 지침

### Context Sandwich 패턴
프롬프트 구성 시 아래 순서를 따른다:
1. **글로벌 규칙** (CLAUDE.md, settings.json) — 앞에
2. **작업 문맥** (현재 파일, harness/plan.md, 관련 context) — 가운데
3. **제약조건** (approval gate, guardrail, stop rule) — 뒤에

### Harness Engineering
모델의 행동은 프롬프트만이 아니라 **실행 환경 자체의 설계**로 제어한다:
- `settings.json` — 권한, 허용 명령, plugin 제한
- `harness/hooks/` — 이벤트 기반 자동 개입
- approval gate — 고위험 작업 전 사람 승인
- sandbox — 격리 실행 환경

## Commands

```bash
# 프로젝트 빌드/실행/테스트 명령어
# python main.py --config configs/default.yaml
```

## Architecture

### Pipeline / Data Flow

```
<!-- 프로젝트의 핵심 흐름을 간결하게 도식화 -->
Input → Processing → Output
```

### Key Modules

<!-- 주요 파일/모듈과 역할 -->
- `src/main.py` — 진입점
- `src/models/` — 모델 정의
- `src/utils/` — 유틸리티
- `configs/` — 설정 파일

### Conventions

<!-- 프로젝트 고유 규약 (import 방식, 네이밍, score 해석 등) -->
-

## Dependencies

<!-- 런타임 의존성 + 환경 특이사항 -->

---

## Cowork File Structure

긴 작업이나 멀티 세션 작업은 **파일 기반 작업면**으로 관리한다. 세션이 바뀌어도 맥락이 유지된다.

```
project/
├── harness/plan.md                    # 현재 작업 계획 — 제약, 할 일, 입출력
├── harness/handoff.md                 # 인수인계 상태 — 어디까지 했는지, 다음 액션
├── harness/feature_list.json          # 크로스-세션 기능 추적 (기능별 status + validation)
├── harness/outputs/                   # 최종 산출물
├── harness/decision-log.md            # 의사결정 기록 (선택)
└── harness/work-log.md                # 작업 이력 (선택)
```

**규칙:**
- 3단계 이상 작업은 `harness/plan.md` 먼저 작성
- 세션 종료 전 `harness/handoff.md` 갱신 + `harness/templates/clean-state-checklist.md` 실행 필수
- `harness/feature_list.json` — 한 번에 하나만 `in_progress`, `passing` 전환은 validation 전체 통과 + evidence 기록 필수 (거짓 passing 금지)
- 사람이 최종 승인하는 결정은 `harness/decision-log.md`에 기록
- 템플릿: `harness/templates/` 디렉토리 참조

---

## Agents

프로젝트에서 활용 가능한 전문 에이전트. `harness/agents/` 디렉토리에 정의.

| 에이전트 | 모델 | 용도 | 활성화 시점 |
|---------|------|------|-----------|
| planner | opus | 구현 계획 수립, 제약·범위 정의 | 3단계+ 작업, 아키텍처 결정 |
| builder | sonnet | harness/plan.md 기반 구현 수행 | planner 계획 확정 후 |
| reviewer | sonnet | 결과물 검증, 판별 | builder 작업 완료 후 |
| code-reviewer | sonnet | 코드 품질/보안 리뷰 | 코드 변경 후 |

에이전트 호출: Subagent Strategy에 따라 서브에이전트로 실행하거나 참조 문서로 활용.

### Planner / Builder / Reviewer 프로토콜

멀티에이전트 작업 시 역할 분리로 충돌을 방지한다:

1. **planner**는 `harness/plan.md`에 변위, 현재 기준, 제약 범위를 잡아 적는다
2. **builder**는 `harness/plan.md`만 기준으로 작업하고 변경 내용을 `harness/implementation-notes.md`에 남긴다
3. **reviewer**는 결과물 + 검증 기준만 읽고 `harness/review-findings.md`에 판별만 적는다
4. 세 역할이 같은 파일을 동시에 편집하지 않는다
5. 마지막 판단은 사람이 `harness/decision-log.md`에 남긴다

**멀티에이전트 오케스트레이션**: 3개 이상 독립 파일에 걸친 *대규모* 작업은 `/orchestrate` 스킬로 Codex CLI 에이전트에 병렬 분배 가능 (고급 옵션). `harness/orchestrator/` 모듈이 세션 관리, 에이전트 실행, 브랜치 머지를 처리한다. 상세는 `AGENTS.md` 참조.

---

## Codex 교차검증 (보조 에이전트) ★

이 프로젝트의 역할 분담:

- **Claude Code = 메인 에이전트** — 이해·계획·구현·검증을 주도한다.
- **Codex = 보조 에이전트** — Claude와 다른 모델·다른 추론 경로를 가진 *독립적인 제2의 눈*. Claude가 놓친 **버그·엣지케이스·보안 구멍**을 잡고, **설계·접근 대안**을 제시한다.

### 제어 모델: Claude 제안 → 사용자 승인 (Human in the Loop)

Codex는 자동으로 돌지 않는다. **Claude가 "여기는 제2의 눈이 필요하다"고 판단하면 사용자에게 먼저 제안하고, 승인을 받은 뒤에만** `/cross-check`로 Codex를 호출한다.

교차검증을 *제안*해야 하는 시점:
- 비자명한 로직/알고리즘을 새로 작성했거나 크게 바꿨을 때
- 커밋/PR 직전 (git-push-reminder·codex-crosscheck-reminder 훅이 nudge)
- 보안·동시성·수치 안정성처럼 실수의 비용이 큰 영역을 건드릴 때
- Claude 스스로 확신이 낮거나, 막혀서 다른 관점이 필요할 때
- ML/DL: 데이터 누수·split 오염·재현성·지표 해석이 결과 신뢰성을 좌우할 때

### 교차검증 루프 (`/cross-check`)

1. Claude가 범위(diff/staged/파일/plan)를 정해 사용자에게 교차검증을 제안
2. 승인 시 Codex를 **read-only**로 실행 (Codex는 읽고 비평만, 수정은 하지 않음)
3. **Claude가 Codex의 각 finding을 직접 검증** — ✅동의 / ⚠️부분동의 / ❌오탐(근거 명시). Codex 출력은 결론이 아니라 입력이다.
4. 동의한 항목만 Claude가 수정. 설계 대안은 trade-off를 정리해 사용자 판단 요청.
5. 확정된 실제 버그는 `tasks/lessons.md` 승격 후보로 기록.

> Codex가 직접 코드를 수정하게 하는 자율 구현(병렬)은 `/orchestrate`의 영역이며, 교차검증과는 구분한다.

## Context Modes

세션 중 작업 모드 전환. `harness/contexts/` 디렉토리의 모드 파일 참조.

| 모드 | 파일 | 포커스 |
|------|------|--------|
| dev | `harness/contexts/dev.md` | 구현 집중 — 코드 먼저, 설명 후 |
| research | `harness/contexts/research.md` | 탐색 집중 — 이해 먼저, 코드 후 |
| review | `harness/contexts/review.md` | 리뷰 집중 — 품질, 보안, 유지보수성 |
| cowork | `harness/contexts/cowork.md` | 파일 기반 협업 — harness/plan.md/handoff.md/outputs/ 구조 |
| autoresearch | `harness/contexts/autoresearch.md` | 자율 실험 루프 — harness/program.md 기반 무한 반복 실험 |

활성화: "이 세션은 [모드] 모드로 진행합니다" 또는 해당 파일 참조 요청.

## Hooks

자동 실행되는 품질 관리 훅. `.claude/settings.local.json`에 설정.

| 훅 | 이벤트 | 동작 |
|----|--------|------|
| bash-safety-guard | PreToolUse (Bash) | 치명적 명령(rm -rf /, fork bomb, main 강제푸시 등) 차단 + 위험 명령 경고 |
| security-scan | PreToolUse (Edit/Write) | 편집 내용의 위험 패턴(eval/pickle/os.system/시크릿) 경고(비차단) |
| suggest-compact | PreToolUse (Edit/Write) | 도구 호출 50회+ 시 전략적 /compact 제안 |
| git-push-reminder | PreToolUse (Bash) | git push 전 리뷰 리마인더 |
| codex-crosscheck-reminder | PreToolUse (Bash) | commit/push 전 비자명한 변경 시 Codex 교차검증 제안(nudge) |
| lessons-reminder | Stop | 세션 중 교훈 기록 리마인더 |

---

## Workflow Orchestration

### 1. Plan Node Default
- 3단계 이상이거나 아키텍처 결정이 필요한 작업은 **반드시 plan mode 먼저**
- 작업 중 예상치 못한 문제가 생기면 STOP → 즉시 재계획. 억지로 밀어붙이지 말 것
- 구현뿐 아니라 **검증 단계**에도 plan mode 활용

### 2. Subagent Strategy
- 메인 컨텍스트 윈도우를 깨끗하게 유지하기 위해 **서브에이전트를 적극 활용**
- 리서치, 탐색, 병렬 분석은 서브에이전트에 오프로드
- 서브에이전트 하나에 한 가지 작업만 (focused execution)

### 3. Self-Improvement Loop
- **사용자의 수정/지적이 있을 때마다**: `tasks/lessons.md`에 해당 패턴을 기록
- 세션 시작 시 `tasks/lessons.md`를 먼저 확인하여 과거 교훈 리뷰
- 반복 검증된 패턴은 `skill_graph/analysis/{주제}/_lessons.md`로 승격

### 4. Verification Before Done (3-Stage Exit Check)
- **작동을 증명하지 않은 채 완료 처리 금지**
- 완료 선언 전 아래 3단계를 순서대로 통과할 것:
  1. **정적 분석**: lint, type check 통과
  2. **런타임 검증**: 실제 실행 후 로그/출력 확인
  3. **시스템 확인**: 엔드투엔드 흐름 또는 통합 테스트 통과
- "시니어 엔지니어가 이 코드를 승인할 것인가?" 자문
- 완료 전 `harness/templates/clean-state-checklist.md` 체크리스트 실행

### 5. Demand Elegance (Balanced)
- 비자명한 변경에는 "더 우아한 방법이 있지 않은가?" 자문
- 수정이 hacky하게 느껴지면 우아한 해결책으로 재구현
- 단순·명백한 수정에는 생략 — 과잉 설계 금지

### 6. Autonomous Bug Fixing
- 버그 리포트가 주어지면: **그냥 고친다**. 손을 잡아달라고 하지 말 것
- 로그, 에러, 실패 테스트를 직접 분석하여 해결

---

## Task Management

1. **Plan First**: 구현 시작 전 `tasks/todo.md`에 체크리스트 형태로 계획 작성
2. **Verify Plan**: 구현 착수 전 계획 확인
3. **Track Progress**: 진행하면서 완료 항목에 체크
4. **Explain Changes**: 각 단계마다 고수준 요약 제공
5. **Document Results**: 완료 후 `tasks/todo.md`에 결과 섹션 추가
6. **Capture Lessons**: 수정/지적 발생 시 즉시 `tasks/lessons.md` 업데이트

```
tasks/
├── todo.md        # 현재 세션 계획·진행·결과 (세션마다 갱신)
└── lessons.md     # 수정·지적으로부터 추출한 누적 교훈 (영속적)
```

---

## Update Notes

유의미한 작업 시 반드시 `skill_graph/` 아래에 `.md` 파일로 기록한다.

```
skill_graph/
├── experiments/
│   ├── _TEMPLATE.md              # 실험/작업 보고서 템플릿
│   └── YYYY-MM-DD_작업명/
│       └── report.md
├── analysis/
│   └── 주제명/
│       ├── YYYY-MM-DD_설명.md
│       └── _lessons.md           # tasks/lessons.md에서 승격된 검증 패턴
├── bugfix/
│   └── YYYY-MM-DD_설명.md
└── ideas/
    └── YYYY-MM-DD_설명.md
```

**스킬 그래프:**
- 노트 간 `## 관련 노트` 섹션에 상대 경로로 링크
- 반복 패턴은 `analysis/{주제}/_lessons.md`로 승격

---

## Harness Engineering Pack

이 프로젝트의 하네스(실행 환경 설계)는 Harness Engineering 방법론을 따른다 — <https://walkinglabs.github.io/learn-harness-engineering/ko/>. 저장소 자체를 **system of record**로 삼아, 세션이 끊겨도 저장소만으로 이어갈 수 있게 한다.

### 최소 필수 팩 (Minimum Pack)

| 파일 | 역할 |
|------|------|
| `CLAUDE.md` / `AGENTS.md` | 루트 지침 — 시작 워크플로우, 작업 규칙, **완료의 정의** |
| `harness/init.sh` | 부트스트랩 — 의존성 설치 + 검증으로 **실행·검증 가능한 기준선** 확보 (작업 전 먼저) |
| `harness/claude-progress.md` | 진행 로그 — "현재 검증된 상태" + 세션 레코드. 다음 세션의 출발점 |
| `harness/feature_list.json` | 기능 추적 — 한 번에 하나만 `in_progress`, `passing`은 검증+증거 필수 |

권장: `harness/handoff.md`, `clean-state-checklist.md`, `evaluator-rubric.md` · 선택: `quality-document.md` (템플릿은 `harness/templates/` 참조).

### 핵심 규율

1. **초기화는 별도 단계** — 새 환경/세션 시작 시 `harness/init.sh`로 기준선부터 확인. 실패하면 다른 작업 전에 기준선 수정.
2. **거대 단일 지시 파일 지양** — 규칙은 CLAUDE.md(루트) + harness/contexts/ + skills/로 분산.
3. **완료의 정의 (Definition of Done)** — validation 통과 + **증거 기록** + 범위 준수 + 재시작 후 유지 + 저장소만으로 인계 가능. 의도만으로 완료 선언 금지.
4. **기능 목록이 기본 단위** — 작업은 `harness/feature_list.json`의 기능 단위로. 거짓 `passing` 금지.
5. **관측 가능성 (Observability)** — 비자명한 실행은 증거(로그/지표/출력)를 남겨 진단 가능하게. 증거 위치를 `harness/claude-progress.md`·`harness/feature_list.json`의 evidence에 기록.
6. **클린 상태로 종료** — 세션 종료 전 `clean-state-checklist.md` 실행. "나중에 정리"는 정리하지 않는 것.

## Governance (거버넌스)

### 고위험 작업 등급표

| 등급 | 예시 | 승인 방식 |
|------|------|----------|
| 낮음 | 파일 읽기, 내부 초안 작성, 테스트 추가 | 자동 실행 가능 |
| 중간 | 고객용 초안 작성, 주기 보고서, 코드 리팩터링 | 사람 검토 후 실행 |
| 높음 | 프로덕션 배포, 고객 발송, 권한 변경, 민감 데이터 조회 | 사람 승인 없이 실행 금지 |

### 최소 감사 흔적 (Auditability)

모든 비자명한 작업은 아래 최소 흔적을 남긴다:
1. `harness/outputs/` — 산출물
2. `harness/work-log.md` — 무엇을 언제 실행했는지
3. `harness/approval-log.md` — 누가 언제 승인했는지 (고위험 작업)
4. `harness/handoff.md` — 남은 일과 다음 단계
5. `harness/decision-log.md` — 무엇을 왜 그렇게 결정했는지

### 자동화 게이트 (Automation Gate)

자동화를 붙이기 전 아래를 확인한다:
- **Before run**: 입력 폴더가 맞는지? 정의된 출력 경로가 있는지? low-confidence 핸들링이 정의되어 있는지?
- **Before send or deploy**: 사람이 초안을 리뷰했는지? 위험한 주장이 체크됐는지? rollback 지점이 존재하는지?
- **After run**: 출력이 맞는 폴더에 저장됐는지? work log가 갱신됐는지? 미해결 이슈가 별도 리스트됐는지?

### 거버넌스 정책 템플릿

상세 정책은 `harness/templates/governance-policy.md` 참조.

---

## Core Principles

- **Simplicity First**: 모든 변경은 가능한 한 단순하게. 최소한의 코드에만 영향을 줄 것
- **No Laziness**: 근본 원인을 찾아라. 임시방편 금지. 시니어 개발자 기준을 적용
- **Minimal Impact**: 변경은 필요한 것만. 불필요한 버그 유입 방지
- **Auditability**: 비자명한 작업은 흔적을 남긴다. 다시 실행할 수 있는 상태를 유지한다
- **Human in the Loop**: 고위험 작업은 사람 승인 없이 실행하지 않는다
