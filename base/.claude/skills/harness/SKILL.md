---
name: harness
description: 프로젝트의 하네스(실행 환경 설계)를 점검·부트스트랩·개선한다. 5개 핵심 서브시스템(지침/상태/검증/범위/세션 라이프사이클)을 기준으로 평가하고 최소 필수 팩을 갖춘다. Harness Engineering 방법론 기반.
user-invocable: true
argument-hint: "[audit | init | improve]"
---

# /harness — 하네스 점검·부트스트랩·개선

저장소 자체를 **system of record**로 만들어, 세션이 끊겨도 저장소만으로 이어갈 수 있는 닫힌 루프 작업 시스템을 구축한다.
방법론: <https://walkinglabs.github.io/learn-harness-engineering/ko/> (공식 `harness-creator` 스킬: `npx skills add walkinglabs/learn-harness-engineering --skill harness-creator`).

대상/모드: $ARGUMENTS  (없으면 `audit`)

---

## 5개 핵심 서브시스템 (평가 축)

| # | 서브시스템 | 핵심 질문 | 주요 산출물 |
|---|-----------|-----------|------------|
| 1 | **Instructions (지침)** | 에이전트가 시작 시 무엇을 읽는가? 완료의 정의가 있는가? | `CLAUDE.md`, `AGENTS.md`, `contexts/` |
| 2 | **State (상태)** | 세션 간 진행/결정이 어디에 남는가? | `claude-progress.md`, `MEMORY.md`, `skill_graph/` |
| 3 | **Verification (검증)** | 완료를 증거로 증명하는가? | `init.sh`(VERIFY), `/verify`, `feature_list.json`의 evidence |
| 4 | **Scope (범위)** | 한 번에 한 기능만? 범위 이탈을 막는가? | `feature_list.json`(in_progress 1개), `plan.md` |
| 5 | **Session lifecycle (세션 라이프사이클)** | 초기화·인계·클린 종료가 절차화됐는가? | `init.sh`, `handoff.md`, `clean-state-checklist.md` |

---

## 모드: `audit` (기본)

현재 저장소를 5개 서브시스템 기준으로 점검한다.

1. 각 서브시스템의 산출물 존재/품질을 Read·Glob으로 확인
2. 각 축을 0~2점 채점 (0 없음 / 1 부분 / 2 충족)
3. 가장 취약한 축부터 우선순위화

출력:
```
HARNESS AUDIT
=============
1. Instructions       [0/1/2] — <근거 / 빠진 것>
2. State              [0/1/2] — ...
3. Verification       [0/1/2] — ...
4. Scope              [0/1/2] — ...
5. Session lifecycle  [0/1/2] — ...
─────────────────────────────
총점: N/10

가장 약한 축: <축> → 권고 액션: <구체적 다음 수정>
```

## 모드: `init`

최소 필수 팩을 갖춘다 (없는 것만 생성, 기존 파일 보존):

- `init.sh` — `templates/init.sh` 기반. INSTALL/VERIFY/START를 프로젝트에 맞게 채울 것
- `claude-progress.md` — `templates/claude-progress.md` 기반. "현재 검증된 상태"를 실제 값으로 채움
- `feature_list.json` — `templates/feature_list.json` 기반. 첫 기능들을 등록
- `CLAUDE.md` / `AGENTS.md` — 없으면 생성, 있으면 완료의 정의·시작 워크플로우 보강

생성 후 `bash init.sh`로 기준선(실행·검증 가능)을 실제로 확인한다. 실패하면 기준선부터 고친다.

## 모드: `improve`

`audit` 결과에서 가장 약한 1~2개 축을 골라 구체적으로 개선한다. 한 번에 전부 고치지 말고 우선순위 순으로. 각 개선 후 `audit`로 재점검.

---

## 7가지 프로덕션 패턴 (개선 시 참고)

| 패턴 | 이 템플릿에서의 위치 |
|------|---------------------|
| Memory Persistence | `MEMORY.md`, `claude-progress.md` |
| Skill Runtime | `.claude/skills/` |
| Context Engineering (예산·JIT 로딩) | `CLAUDE.md` Context Engineering, `contexts/` |
| Tool Registry (안전성·동시성) | `.claude/settings.local.json`(권한), `.locks/`(dev) |
| Multi-Agent Coordination | `/cross-check`(Codex 교차검증), `/orchestrate`(병렬) |
| Lifecycle & Bootstrap | `init.sh`, `hooks/`, `handoff.md` |
| Gotchas (비자명 실패) | `tasks/lessons.md`, `skill_graph/analysis/_lessons.md` |

## 규칙

- **거짓 충족 금지** — 파일만 있고 내용이 비면 충족 아님. 실제 내용·실행 가능성으로 판정.
- **한 번에 하나** — `improve`는 가장 약한 축부터. 과잉 설계 금지.
- 비대화형 환경이 아니면 파일 생성/수정 전 핵심 변경은 사용자에게 알린다.
- 완료의 정의: validation 통과 + 증거 기록 + 범위 준수 + 재시작 후 유지 + 저장소만으로 인계 가능.
