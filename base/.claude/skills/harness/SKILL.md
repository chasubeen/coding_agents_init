---
name: harness
description: 프로젝트의 하네스(실행 환경 설계)를 점검·부트스트랩·개선·진화시킨다. 5개 핵심 서브시스템(지침/상태/검증/범위/세션 라이프사이클)을 기준으로 평가하고 최소 필수 팩을 갖춘다. Harness Engineering 방법론 기반.
user-invocable: true
argument-hint: "[audit | init | improve | evolve]"
---

# /harness — 하네스 점검·부트스트랩·개선

저장소 자체를 **system of record**로 만들어, 세션이 끊겨도 저장소만으로 이어갈 수 있는 닫힌 루프 작업 시스템을 구축한다.
방법론: <https://walkinglabs.github.io/learn-harness-engineering/ko/> (공식 `harness-creator` 스킬: `npx skills add walkinglabs/learn-harness-engineering --skill harness-creator`).

대상/모드: $ARGUMENTS  (없으면 `audit`)

---

## 5개 핵심 서브시스템 (평가 축)

| # | 서브시스템 | 핵심 질문 | 주요 산출물 |
|---|-----------|-----------|------------|
| 1 | **Instructions (지침)** | 에이전트가 시작 시 무엇을 읽는가? 완료의 정의가 있는가? | `CLAUDE.md`, `AGENTS.md`, `harness/contexts/` |
| 2 | **State (상태)** | 세션 간 진행/결정이 어디에 남는가? | `harness/claude-progress.md`, `MEMORY.md`, `skill_graph/` |
| 3 | **Verification (검증)** | 완료를 증거로 증명하는가? | `harness/init.sh`(VERIFY), `/verify`, `harness/feature_list.json`의 evidence |
| 4 | **Scope (범위)** | 한 번에 한 기능만? 범위 이탈을 막는가? | `harness/feature_list.json`(in_progress 1개), `harness/plan.md` |
| 5 | **Session lifecycle (세션 라이프사이클)** | 초기화·인계·클린 종료가 절차화됐는가? | `harness/init.sh`, `harness/handoff.md`, `clean-state-checklist.md` |

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

- `harness/init.sh` — `harness/templates/init.sh` 기반. INSTALL/VERIFY/START를 프로젝트에 맞게 채울 것
- `harness/claude-progress.md` — `harness/templates/claude-progress.md` 기반. "현재 검증된 상태"를 실제 값으로 채움
- `harness/feature_list.json` — `harness/templates/feature_list.json` 기반. 첫 기능들을 등록
- `CLAUDE.md` / `AGENTS.md` — 없으면 생성, 있으면 완료의 정의·시작 워크플로우 보강

생성 후 `bash harness/init.sh`로 기준선(실행·검증 가능)을 실제로 확인한다. 실패하면 기준선부터 고친다.

## 모드: `improve`

`audit` 결과에서 가장 약한 1~2개 축을 골라 구체적으로 개선한다. 한 번에 전부 고치지 말고 우선순위 순으로. 각 개선 후 `audit`로 재점검.

## 모드: `evolve`

**초기 하네스 ↔ 실제로 진화한 프로젝트** 사이의 드리프트(delta)를 감지해, 하네스를 현실에 맞게 따라잡힌다. setup.sh가 깔아준 *초안*은 프로젝트가 자라면서 낡는다 — 이 모드가 그 격차를 메운다.

1. **드리프트 감지** — 아래를 실제 코드/이력과 대조한다:
   - `CLAUDE.md`의 Commands/Architecture/Conventions가 현재 코드와 맞는가? (빌드·테스트 명령이 바뀌지 않았나, 새 모듈/디렉토리가 문서에 없나)
   - `harness/init.sh`의 INSTALL/VERIFY/START가 여전히 동작하는가?
   - `harness/feature_list.json`이 실제 구현 상태와 일치하는가? (거짓 `passing`, 누락된 신규 기능)
   - `tasks/lessons.md`에 반복 등장한 교훈이 `CLAUDE.md`/스킬/규약으로 승격됐는가? (`git log`·lessons에서 반복 패턴 탐지)
   - 새로 굳어진 관례(네이밍, 디렉토리, 테스트 방식)가 어디에도 기록되지 않았나?
2. **델타 제시** — 발견한 격차를 "현재 문서 vs 실제" 대조표로 보고. 추측 금지, 증거(파일·커밋) 명시.
3. **승격·갱신 제안** — 각 델타에 대해 구체적 갱신안:
   - 반복된 교훈 → `CLAUDE.md` 규약 또는 새 스킬로 승격 (`skill-authoring-guide.md` 참고)
   - 낡은 Commands/Architecture → 갱신
   - 실제 아키텍처 패턴 → `CLAUDE.md` 반영
4. **적용** — 사용자 승인 후 갱신. 큰 변경은 `harness/decision-log.md`에 기록.

출력:
```
HARNESS EVOLVE — 드리프트 N건
1. [Instructions] CLAUDE.md Commands 'npm test' → 실제 'pytest -q' (evidence: ...)  → 갱신 제안
2. [State] lessons.md에 "시드 고정" 3회 반복 → CLAUDE.md 규약 승격 제안
...
```

> 이것이 하네스를 "한 번 만들고 끝"이 아니라 **살아 있는 시스템**으로 만든다. 큰 마일스톤 후나 "문서가 코드랑 안 맞는다" 싶을 때 실행.

---

## 7가지 프로덕션 패턴 (개선 시 참고)

| 패턴 | 이 템플릿에서의 위치 |
|------|---------------------|
| Memory Persistence | `MEMORY.md`, `harness/claude-progress.md` |
| Skill Runtime | `.claude/skills/` |
| Context Engineering (예산·JIT 로딩) | `CLAUDE.md` Context Engineering, `harness/contexts/` |
| Tool Registry (안전성·동시성) | `.claude/settings.local.json`(권한), `.locks/`(dev) |
| Multi-Agent Coordination | `/cross-check`(Codex 교차검증), `/orchestrate`(병렬) |
| Lifecycle & Bootstrap | `harness/init.sh`, `harness/hooks/`, `harness/handoff.md` |
| Gotchas (비자명 실패) | `tasks/lessons.md`, `skill_graph/analysis/_lessons.md` |

## 규칙

- **거짓 충족 금지** — 파일만 있고 내용이 비면 충족 아님. 실제 내용·실행 가능성으로 판정.
- **한 번에 하나** — `improve`는 가장 약한 축부터. 과잉 설계 금지.
- 비대화형 환경이 아니면 파일 생성/수정 전 핵심 변경은 사용자에게 알린다.
- 완료의 정의: validation 통과 + 증거 기록 + 범위 준수 + 재시작 후 유지 + 저장소만으로 인계 가능.
