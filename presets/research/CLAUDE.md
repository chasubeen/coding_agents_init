# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Research Principle (연구 철칙)

**단순한 성능 향상이 목표가 아니다.** 연구로서 가치가 있으며 동시에 성능을 향상시킬 수 있는 **novelty 있는 방법론을 제안**하는 것이 최종 목표다. 모든 실험과 방법론 설계는 "왜 이 방법이 학술적으로 의미가 있는가?"를 먼저 답할 수 있어야 한다. Trick 나열이 아닌, 명확한 insight와 원리에 기반한 방법론을 추구한다.

추가로 모든 연구 작업은 아래 4가지를 동시에 만족하도록 설계한다.
- **Claim**: 무엇을 주장하는가
- **Evidence**: 그 주장을 어떤 실험/분석으로 지지하는가
- **Boundary**: 어디까지 성립하고 어디서 깨지는가
- **Positioning**: 기존 방법 대비 어떤 차별성이 있는가

## Project Summary

<!-- 연구 프로젝트 한 문단 요약 -->

## Commands

```bash
# 실험 실행
# python main.py --config configs/default.yaml

# Config override
# python main.py --config configs/default.yaml DATASET.shot=4 MODEL.backbone=resnet50

# Baseline 실행
# python main.py EXPANSION.use=false

# 전체 실험 스위트
# bash scripts/run_experiments.sh
```

No test suite exists. Validation is done by running experiments and checking metrics.

## Architecture

### Pipeline Flow

```
<!-- 연구 파이프라인 도식화 -->
Training: Data → Feature Extraction → Model Fitting
Testing:  Data → Features → [Core Method] → Scoring → Metrics
```

### Key Modules

<!-- 주요 모듈과 역할 -->
- `main.py` — 진입점, 실험 오케스트레이션
- `models/` — 모델 정의
- `utils/` — 유틸리티 (metrics, visualization 등)
- `configs/` — 실험 설정 (YAML)
- `data_provider/` — 데이터 로더

### Score Convention

<!-- 점수 해석 규약 명시 (혼동 방지) -->
<!-- 예: "Higher score = anomaly" 또는 "Lower score = more normal" -->

### Registry / Extension Pattern

<!-- 새 모듈 추가 시 따라야 할 패턴 -->

## Data Layout

```
<!-- 데이터 디렉토리 구조 -->
{data_path}/{dataset_name}/{category}/train/
{data_path}/{dataset_name}/{category}/test/
```

## Dependencies

<!-- 런타임 의존성 -->

## Config Parameter Tags

`[TUNE]` = 자주 튜닝하는 하이퍼파라미터
`[ARCH]` = 아키텍처 선택 (덜 변경)
`[DEPRECATED]` = 호환성 유지용 (미사용)
`[ABLATION]` = 논문 ablation에서 독립 변수로 다룰 항목
`[REPRO]` = 재현성에 직접 영향 주는 항목 (seed, split, eval protocol 등)

---

## Context Engineering

연구 프로젝트에서 Claude의 행동을 결정하는 문맥 조합:
- **CLAUDE.md** — 연구 원칙, 실험 프로세스, 워크플로우 규칙
- **harness/contexts/** — 세션 모드별 행동 지침
- **harness/templates/** — 산출물·거버넌스 템플릿
- **harness/hooks/** — 자동 실행 품질 관리

### Cowork File Structure
```
project/
├── harness/plan.md          # 실험/구현 계획
├── harness/handoff.md       # 인수인계 상태
├── harness/outputs/         # 산출물 (논문 figure, 실험 결과 등)
└── harness/decision-log.md  # 방법론 결정 기록
```

---

## Agents

프로젝트에서 활용 가능한 전문 에이전트. `harness/agents/` 디렉토리에 정의.

| 에이전트 | 모델 | 용도 | 활성화 시점 |
|---------|------|------|-----------|
| planner | opus | 실험/구현 계획 수립, 제약·범위 정의 | 3단계+ 작업, 방법론 설계 |
| builder | sonnet | harness/plan.md 기반 구현, 변경 기록 | planner 계획 확정 후 |
| reviewer | sonnet | 결과물 검증, 판별 | builder 작업 완료 후 |
| code-reviewer | sonnet | 코드 품질/보안 리뷰 | 코드 변경 후 |

에이전트 호출: Subagent Strategy에 따라 서브에이전트로 실행하거나 참조 문서로 활용.

### Planner / Builder / Reviewer 프로토콜
1. **planner** → `harness/plan.md` 작성 (실험 설계, 가설, 성공 기준)
2. **builder** → `harness/plan.md` 기준 구현, `harness/implementation-notes.md` 기록
3. **reviewer** → `harness/review-findings.md`에 실험 결과 검증
4. **human** → `harness/decision-log.md`에 방법론 결정

## Codex 교차검증 (보조 에이전트) ★

- **Claude Code = 메인 에이전트**: 이해·계획·구현·검증 주도.
- **Codex = 보조 에이전트**: 다른 모델·다른 추론 경로의 *독립적 제2의 눈*. Claude가 놓친 **버그·엣지케이스·보안**을 잡고 **설계·접근 대안**을 제시.

**제어 모델 (Human in the Loop)**: Codex는 자동 실행하지 않는다. Claude가 "제2의 눈이 필요하다" 판단 시 **사용자에게 먼저 제안 → 승인 후** `/cross-check`로 호출한다.

**제안 시점**: 비자명한 로직 작성/대규모 변경 후, 커밋·PR 직전, 보안·수치 안정성 영역, 확신이 낮거나 막혔을 때. 특히 ML/DL에서 **데이터 누수·train/eval split 오염·재현성·지표/손실 해석**처럼 결과 신뢰성이 걸린 지점.

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
| autoresearch | `harness/contexts/autoresearch.md` | 자율 실험 루프 — harness/program.md 기반 무한 반복 |

활성화: "이 세션은 [모드] 모드로 진행합니다" 또는 해당 파일 참조 요청.

### AutoResearch 연동

`/autoresearch`는 Karpathy의 자율 실험 패턴을 구현합니다. 6단계 실험 프로세스와 병행:
- **autoresearch** = 탐색 단계 (빠른 반복 ~5분/실험, 넓은 범위)
- **6단계 프로세스** = 검증 단계 (깊은 분석, 논문 기여도 판단)

`harness/program.md`에 연구 목표, 수정 가능 파일, 판정 기준을 정의하면 에이전트가 자율적으로 실험을 반복합니다.

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
- 스펙을 앞에서 상세히 작성해 모호함을 최소화

### 2. Subagent Strategy
- 메인 컨텍스트 윈도우를 깨끗하게 유지하기 위해 **서브에이전트를 적극 활용**
- 리서치, 탐색, 병렬 분석은 서브에이전트에 오프로드
- 복잡한 문제일수록 서브에이전트를 통해 컴퓨팅을 더 투입
- 서브에이전트 하나에 한 가지 작업만 (focused execution)

### 3. Self-Improvement Loop
- **사용자의 수정/지적이 있을 때마다**: `tasks/lessons.md`에 해당 패턴을 기록
- 같은 실수를 반복하지 않도록 스스로 규칙을 작성
- 세션 시작 시 `tasks/lessons.md`를 먼저 확인하여 과거 교훈 리뷰
- 반복 검증된 패턴은 `skill_graph/analysis/{주제}/_lessons.md`로 승격

### 4. Verification Before Done
- **작동을 증명하지 않은 채 완료 처리 금지**
- 변경 사항이 있을 때: main 동작과 diff하여 확인
- "시니어 엔지니어가 이 코드를 승인할 것인가?" 자문
- **관찰되지 않음 ≠ 없음**: 미확인 정보(지표·상태·결과)는 추측하지 말고 `unknown`으로 명시. 중단조건·검증관점 등 상세는 `harness/references/harness-principles.md`
- 테스트 실행, 로그 확인, 정확성 시연 후 완료
- 연구 작업은 추가로 "이 결과가 논문 figure/table/claim에 들어갈 수 있는가?"까지 확인

### 5. Demand Elegance (Balanced)
- 비자명한 변경에는 "더 우아한 방법이 있지 않은가?" 자문
- 수정이 hacky하게 느껴지면: "지금 알고 있는 모든 것을 감안해 우아한 해결책을 구현"
- 단순·명백한 수정에는 생략 — 과잉 설계 금지

### 6. Autonomous Bug Fixing
- 버그 리포트가 주어지면: **그냥 고친다**. 손을 잡아달라고 하지 말 것
- 로그, 에러, 실패 테스트를 직접 분석하여 해결
- 사용자의 컨텍스트 전환 없이 처리

---

## Research Decision Rules

### 1. Novelty Gate
- 새 아이디어 제안 전 반드시 아래를 한 줄씩 답한다.
  - 기존 방법의 핵심 한계는 무엇인가?
  - 제안 방법이 건드리는 메커니즘은 무엇인가?
  - 이 차이가 논문 contribution 한 줄로 요약 가능한가?
- 위 질문에 답하지 못하면 구현보다 **문제 재정의 또는 related work 조사**를 우선한다

### 2. Claim-Evidence Discipline
- claim 하나당 최소 하나의 직접 증거를 연결한다
- 성능 주장은 평균 성능만이 아니라 **분산, seed 민감도, category별 편차**를 함께 본다
- "개선됨"이라는 표현은 baseline, 비교군, metric, split이 명시될 때만 사용
- 증거 없는 직관 서술은 `가설`, 검증 완료된 서술은 `결론`으로 명확히 구분한다

### 3. Baseline and Ablation First
- 새 방법은 반드시 **강한 baseline**과 비교한다. 약한 baseline을 이긴 것만으로 기여를 주장하지 않는다
- 성능이 좋아도 ablation 없이 핵심 모듈 기여를 주장하지 않는다
- ablation은 가능한 한 one-factor change로 설계한다
- 부가 모듈이 많아질수록 "없어도 되는 것"을 제거하는 ablation을 우선한다

### 4. Reproducibility Minimum Bar
- 최소 기록 항목: commit hash, config diff, seed, 데이터 split, 체크포인트/로그 경로
- 재현 불가능한 결과는 좋은 결과가 아니라 **미완료 결과**로 취급한다
- 평가 스크립트와 학습 스크립트의 metric 정의가 다를 가능성을 항상 점검한다

### 5. Negative Results Are Assets
- 실패 실험도 버리지 않는다. 왜 실패했는지까지 기록해야 탐색 공간이 줄어든다
- "안 됨"이 아니라 "어떤 조건에서 왜 안 됨"으로 정리한다
- 반복 실패 패턴은 `_lessons.md`로 승격해 이후 탐색 비용을 줄인다

### 6. Paper-Oriented Prioritization
- 구현 난이도보다 **논문 메시지 밀도**가 높은 실험을 우선한다
- 결과가 좋아도 설명이 약하면 후순위, 결과가 약간 부족해도 설명력이 강하면 보존한다
- 최종적으로는 contribution, figure, table, related work 문단으로 재사용 가능한 형태를 선호한다

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

## Experiment Process

실험은 반드시 아래 **6단계 프로세스**를 따른다. 템플릿: `skill_graph/experiments/_TEMPLATE.md`

```
1. 문제 분석 (Problem Analysis)  → 현상 + 원인 추정 + 관련 선행 노트
2. 가설 설정 (Hypothesis)        → "X하면 Y 개선" + 근거 + 예상 수치
3. 실험 설정 (Experiment Design) → 대조군/실험군 + config diff + 실행 커맨드
4. 결과 (Results)                → 정량 결과표 + 로그 경로
5. 결과 분석 (Analysis)          → 가설 검증 (✅/❌/⚠️) + 상세 분석 + 부수 발견
6. 피드백 (Feedback)             → 교훈 + 다음 실험 제안 + _lessons.md 승격 여부
```

**실험 진행 규칙:**
- 실험 시작 전 1~3단계 먼저 작성 후 실행
- 실험 완료 후 4~6단계 기록
- 가설 검증 결과가 반복 활용 가능하면 `analysis/{주제}/_lessons.md`로 승격
- `## 관련 노트`로 실험 간 연쇄 추적
- 모든 실험은 가능한 경우 baseline 대비 **단일 주장 검증(single claim test)** 형태로 쪼갠다
- 메인 결과 표에 들어갈 후보 실험은 seed, confidence interval 또는 반복 측정 여부를 표시한다
- 성능 향상 실험과 별도로 실패 사례, category 편차, calibration/robustness를 보는 분석 실험을 분리한다

**실험 디렉토리 구조:**
```
skill_graph/experiments/YYYY-MM-DD_실험명/
├── report.md            # 6단계 프로세스 전체 기록
├── config_diff.yaml     # baseline 대비 변경된 config
└── logs/                # 실험 로그
```

## Update Notes

```
skill_graph/
├── experiments/
│   ├── _TEMPLATE.md              # 실험 보고서 템플릿 (6단계 프로세스)
│   └── YYYY-MM-DD_실험명/
├── papers/
│   ├── _TEMPLATE.md              # 관련 논문/선행연구 요약
│   └── YYYY-MM-DD_논문명.md
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
- 노트 간 `## 관련 노트`로 상대 경로 링크
- 실험 → 분석 → 아이디어 → 논문 포지셔닝 → 후속 실험 흐름 추적
- 반복되는 패턴이나 검증된 기법은 `analysis/{주제}/_lessons.md`로 승격

---

## Core Principles

- **Research Over Tricks**: 성능 숫자보다 연구 메시지와 메커니즘 설명을 우선한다
- **Strong Baselines Only**: 약한 비교군 위의 승리는 기여가 아니다
- **One Claim, One Test**: 한 실험이 여러 주장을 동시에 떠안지 않게 설계한다
- **Evidence Before Narrative**: 서사는 결과 뒤에 온다. 먼저 증거를 만든다
- **Reproducibility Is Part of Quality**: 재현성 없는 결과는 미완성으로 본다

- **Simplicity First**: 모든 변경은 가능한 한 단순하게. 최소한의 코드에만 영향을 줄 것
- **No Laziness**: 근본 원인을 찾아라. 임시방편 금지. 시니어 개발자 기준을 적용
- **Minimal Impact**: 변경은 필요한 것만. 불필요한 버그 유입 방지
- **모듈화 필수**: 새롭게 추가하는 모든 모듈/기능은 config에서 `enable: true/false`로 on/off 가능하게 구현. 과거 실험을 config만으로 정확히 재현할 수 있어야 한다.
- **Reproducibility**: seed 고정, config 기록, 환경 명시
- **Ablation-friendly**: 각 컴포넌트를 독립적으로 on/off 가능하게 설계

## Important Conventions

<!-- 프로젝트 고유 규약 -->
-
