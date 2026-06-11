# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Principle

<!-- 프로젝트의 핵심 철학. Claude가 모든 판단의 기준으로 삼을 원칙. -->
**[여기에 프로젝트의 핵심 원칙을 작성하세요]**

## Project Summary

<!-- 프로젝트를 한 문단으로 설명. Claude가 맥락을 빠르게 파악하는 데 사용. -->

## Commands

```bash
# 개발 서버 실행
npm run dev

# 빌드
npm run build

# 프로덕션 실행
npm start

# 타입 체크
npx tsc --noEmit

# 린트
npm run lint

# 테스트
npm test

# 포매팅
npm run format
```

## Architecture

### Pipeline / Data Flow

```
<!-- 프로젝트의 핵심 흐름을 간결하게 도식화 -->
[Client] ↕ [API/WebSocket] ↕ [Backend] ↕ [Database/External]
```

### Key Modules

<!-- 주요 파일/모듈과 역할 -->
- `src/app/` — Next.js App Router 페이지 및 레이아웃
- `src/components/` — UI 컴포넌트
- `src/server/` — 백엔드 로직
- `src/lib/` — 공유 유틸리티 및 타입

### Conventions

<!-- 프로젝트 고유 규약 -->
- TypeScript strict mode 사용
- 컴포넌트: PascalCase (`ComponentName.tsx`)
- 유틸리티/서버: camelCase (`utilName.ts`)
- API 라우트: Next.js App Router (`src/app/api/`)
- DB 접근: Prisma Client를 통한 타입 안전 쿼리

## Dependencies

### Core
<!-- 프로젝트 핵심 의존성 -->

### Dev Tools
- **TypeScript** — 타입 안전성
- **ESLint + Prettier** — 코드 품질 및 포맷 일관성
- **Tailwind CSS** — 유틸리티 기반 스타일링

---

## Context Engineering

이 프로젝트에서 Claude의 행동을 결정하는 것은 단일 프롬프트가 아니라 **문맥의 조합**이다:
- **CLAUDE.md** — 프로젝트 규칙과 구조
- **rules/** — 경로별·스코프별 세부 규칙
- **harness/hooks/** — 자동 실행 품질 관리
- **harness/templates/** — 산출물 구조 표준
- **harness/contexts/** — 세션 모드별 행동 지침

### Context Sandwich 패턴
1. 글로벌 규칙 (CLAUDE.md, settings.json) — 앞
2. 작업 문맥 (현재 파일, harness/plan.md) — 가운데
3. 제약조건 (approval gate, guardrail) — 뒤

---

## Cowork File Structure

긴 작업이나 멀티 세션 작업은 파일 기반 작업면으로 관리한다.

```
project/
├── harness/plan.md          # 작업 계획 — 제약, 할 일, 성공 기준
├── harness/handoff.md       # 인수인계 상태
├── harness/outputs/         # 산출물
└── harness/decision-log.md  # 의사결정 기록 (선택)
```

---

## Agents

프로젝트에서 활용 가능한 전문 에이전트. `harness/agents/` 디렉토리에 정의.

| 에이전트 | 모델 | 용도 | 활성화 시점 |
|---------|------|------|-----------|
| planner | opus | 구현 계획 수립, 제약·범위 정의 | 3단계+ 작업, 아키텍처 결정 |
| builder | sonnet | harness/plan.md 기반 구현, 변경 기록 | planner 계획 확정 후 |
| reviewer | sonnet | 결과물 검증, 판별 | builder 작업 완료 후 |
| code-reviewer | sonnet | 코드 품질/보안 리뷰 | 코드 변경 후 |
| security-reviewer | sonnet | OWASP Top 10 보안 검토 | 인증/입력/API 코드 변경 후 |
| build-error-resolver | sonnet | 빌드/타입 에러 해결 | 빌드 실패 시 |

에이전트 호출: Subagent Strategy에 따라 서브에이전트로 실행하거나 참조 문서로 활용.

### Planner / Builder / Reviewer 프로토콜
1. **planner** → `harness/plan.md` 작성
2. **builder** → `harness/plan.md` 기준 구현, `harness/implementation-notes.md` 기록
3. **reviewer** → `harness/review-findings.md`에 판별
4. **human** → `harness/decision-log.md`에 최종 판단

## Codex 교차검증 (보조 에이전트) ★

- **Claude Code = 메인 에이전트**: 이해·계획·구현·검증 주도.
- **Codex = 보조 에이전트**: 다른 모델·다른 추론 경로의 *독립적 제2의 눈*. Claude가 놓친 **버그·엣지케이스·보안**을 잡고 **설계·접근 대안**을 제시.

**제어 모델 (Human in the Loop)**: Codex는 자동 실행하지 않는다. Claude가 "제2의 눈이 필요하다" 판단 시 **사용자에게 먼저 제안 → 승인 후** `/cross-check`로 호출한다.

**제안 시점**: 비자명한 로직 작성/대규모 변경 후, 커밋·PR 직전, 인증·입력처리·동시성·외부 API 등 실수 비용이 큰 영역, 확신이 낮거나 막혔을 때.

**교차검증 루프**: ① 범위 지정·제안 → ② 승인 시 Codex **read-only** 실행(읽고 비평만) → ③ **Claude가 각 finding을 직접 검증**(✅동의/⚠️부분/❌오탐) → ④ 동의 항목만 Claude가 수정, 설계 대안은 trade-off 정리 후 사용자 판단 → ⑤ 확정 버그는 `tasks/lessons.md` 승격 후보.

> 대규모 병렬 자율 구현은 `/orchestrate`(Codex worker)의 영역으로 교차검증과 구분한다.

## Context Modes

세션 중 작업 모드 전환. `harness/contexts/` 디렉토리의 모드 파일 참조.

| 모드 | 파일 | 포커스 |
|------|------|--------|
| dev | `harness/contexts/dev.md` | 구현 집중 — 코드 먼저, 설명 후 |
| research | `harness/contexts/research.md` | 탐색 집중 — 이해 먼저, 코드 후 |
| review | `harness/contexts/review.md` | 리뷰 집중 — 품질, 보안, 유지보수성 |
| cowork | `harness/contexts/cowork.md` | 파일 기반 협업 — harness/plan.md/handoff.md/outputs/ |

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

### 4. Verification Before Done
- **작동을 증명하지 않은 채 완료 처리 금지**
- "시니어 엔지니어가 이 코드를 승인할 것인가?" 자문
- 테스트 실행, 로그 확인, 정확성 시연 후 완료

### 5. Demand Elegance (Balanced)
- 비자명한 변경에는 "더 우아한 방법이 있지 않은가?" 자문
- 수정이 hacky하게 느껴지면 우아한 해결책으로 재구현
- 단순·명백한 수정에는 생략 — 과잉 설계 금지

### 6. Autonomous Bug Fixing
- 버그 리포트가 주어지면: **그냥 고친다**. 손을 잡아달라고 하지 말 것
- 로그, 에러, 실패 테스트를 직접 분석하여 해결

---

## Agent Coordination Protocol

멀티에이전트 병렬 작업 시 파일 충돌을 방지하기 위한 규칙.

### 파일 잠금 메커니즘

- 에이전트가 파일 수정 전 `.locks/` 디렉토리에 잠금 파일 생성
- 잠금 파일명: `{파일경로에서 /를 -로 치환}.lock` (예: `src-app-page.tsx.lock`)
- 잠금 파일 내용 (JSON):
  ```json
  {
    "agent_id": "세션ID",
    "file": "대상 파일 경로",
    "lines": "수정 라인 범위 (예: '1-50' 또는 'all')",
    "timestamp": "ISO 8601",
    "description": "작업 설명"
  }
  ```
- 수정 완료 후 즉시 잠금 파일 삭제

### 에이전트 행동 규칙

1. **수정 전**: `.locks/`에 해당 파일의 잠금 존재 여부 확인
2. **잠금 없음** → 잠금 생성 후 수정 진행
3. **잠금 있음** → 라인 범위가 겹치지 않으면 동시 수정 가능, 겹치면 해당 파일 보류 → 다른 작업 선행
4. **수정 완료** → 즉시 잠금 파일 삭제

### Advisor 에이전트 역할

- 상시 존재하며 `.locks/` 상태를 모니터링
- 작업 할당 시 잠금 상태를 고려하여 병목 방지
- 교착(deadlock) 감지 및 해소
- 30분 이상 경과한 좀비 잠금 정리

---

## Memory Management

프로젝트 영속 메모리는 `~/.claude/projects/{project-path}/memory/`에 위치한다.

### 구조
```
memory/
├── MEMORY.md          # 핵심 요약 (매 세션 자동 로드, 200줄 제한)
├── architecture.md    # 아키텍처 상세 결정 및 변경 이력
├── patterns.md        # 코드 패턴, 컨벤션, 반복 사용 스니펫
└── debugging.md       # 디버깅 인사이트, 환경 이슈, 해결책
```

### 규칙
- **MEMORY.md**: 프로젝트 오버뷰, 핵심 결정, 현재 상태만 간결하게 유지 (200줄 이내)
- **토픽 파일**: 상세 내용은 별도 파일로 분리하고 MEMORY.md에서 링크
- **갱신 시점**:
  - 아키텍처/기술 결정 변경 시 → `architecture.md` 갱신
  - 반복 확인된 코드 패턴 → `patterns.md` 갱신
  - 디버깅 해결책 발견 시 → `debugging.md` 갱신
  - 매 세션 종료 전 → `MEMORY.md`의 Current Status 갱신
- **중복 금지**: 새로 쓰기 전에 기존 내용 확인. 업데이트 우선
- **추측 금지**: 검증되지 않은 내용은 기록하지 않음
- `tasks/lessons.md`의 검증된 교훈 중 영속적 가치가 있는 것은 memory로 승격

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
├── features/                     # 신규 기능 구현 기록
│   ├── _TEMPLATE.md
│   └── YYYY-MM-DD_기능명.md
├── bugfix/                       # 버그 수정 기록 (원인 분석 포함)
│   ├── _TEMPLATE.md
│   └── YYYY-MM-DD_설명.md
├── refactor/                     # 리팩토링 기록 (Before/After)
│   ├── _TEMPLATE.md
│   └── YYYY-MM-DD_설명.md
├── devops/                       # 빌드/배포/CI·CD/인프라 변경
│   ├── _TEMPLATE.md
│   └── YYYY-MM-DD_설명.md
└── decisions/                    # 아키텍처/기술 결정 기록 (ADR)
    ├── _TEMPLATE.md
    └── YYYY-MM-DD_결정명.md
```

**노트 연결:**
- 노트 간 `## 관련 노트` 섹션에 상대 경로로 링크
- 반복되는 교훈은 `tasks/lessons.md`에 누적

---

## Governance

### 고위험 작업 등급표
| 등급 | 예시 | 승인 방식 |
|------|------|----------|
| 낮음 | 파일 읽기, 테스트 추가, 내부 초안 | 자동 실행 |
| 중간 | 코드 리팩터링, 보고서 생성 | 사람 검토 후 실행 |
| 높음 | 프로덕션 배포, 고객 발송, 권한 변경 | 사람 승인 필수 |

### 최소 감사 흔적
1. `harness/outputs/` — 산출물
2. `harness/work-log.md` — 실행 이력
3. `harness/handoff.md` — 인수인계 상태
4. `harness/decision-log.md` — 결정 기록

---

## Core Principles

- **Simplicity First**: 모든 변경은 가능한 한 단순하게. 최소한의 코드에만 영향을 줄 것
- **No Laziness**: 근본 원인을 찾아라. 임시방편 금지. 시니어 개발자 기준을 적용
- **Minimal Impact**: 변경은 필요한 것만. 불필요한 버그 유입 방지
- **Auditability**: 비자명한 작업은 흔적을 남긴다
- **Human in the Loop**: 고위험 작업은 사람 승인 없이 실행하지 않는다
