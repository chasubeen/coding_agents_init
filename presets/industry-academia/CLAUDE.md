# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Principle (프로젝트 원칙)

**산학과제는 "연구 성과"와 "실용적 결과물"을 동시에 달성해야 한다.** 학술 논문 투고와 기업 납품물(보고서/PoC/데모) 양쪽의 요구사항을 균형 있게 충족시키되, 기업이 요구하는 일정과 산출물 기준을 최우선으로 관리한다. 연구적 깊이는 납품 일정을 초과하지 않는 범위 내에서 추구한다. 단순한 성능 trick 나열이 아닌, 명확한 insight와 원리에 기반한 방법론을 추구한다.

## Project Summary

<!-- 과제 한 문단 요약 -->
<!-- 예: "비전 기반 제조 결함 검출 시스템. 삼성전기와의 산학과제로, 소수 정상 샘플로 학습하여 실시간 결함 검출을 수행하는 경량 모델을 개발한다." -->

## Stakeholders

| 역할 | 이름/조직 | 주요 관심사 |
|------|----------|------------|
| 지도교수 | | 논문 성과, 연구 방향 |
| 기업 담당자 | | 납품물 품질, 일정 준수, 실환경 성능 |
| 연구원/학생 | | 구현, 실험, 논문 기여 |

## Timeline & Milestones

<!-- 과제 일정 관리. Claude가 우선순위 판단에 활용. -->
| 마일스톤 | 기한 | 산출물 | 상태 |
|---------|------|--------|------|
| 1차 중간보고 | YYYY-MM-DD | 진행 보고서, baseline 결과 | 🔴 |
| 중간 납품 | YYYY-MM-DD | PoC 모델, 성능 리포트, 데모 | 🔴 |
| 최종 납품 | YYYY-MM-DD | 최종 모델, 보고서, 추론 코드 | 🔴 |
| 논문 투고 | YYYY-MM-DD | 학회/저널 제출 | 🔴 |

## Commands

```bash
# 학습 실행
# PYTHONPATH=$(pwd):$PYTHONPATH python main.py --config configs/default.yaml

# Config override (OmegaConf 등)
# python main.py --config configs/default.yaml DATASET.name=custom MODEL.backbone=resnet50

# Baseline 실행
# python main.py MODEL.use_proposed=false

# 전체 실험 스위트
# bash scripts/run_experiments.sh

# Pilot mode (wandb off, 빠른 검증)
# PILOT=true bash scripts/run_experiments.sh

# 데모 실행 (기업 발표용)
# python demo/app.py

# 성능 리포트 생성
# python scripts/generate_report.py --output reports/

# GPU 지정
# CUDA_VISIBLE_DEVICES=0 python main.py --config configs/default.yaml
```

No test suite exists. Validation is done by running experiments and checking metrics.

## Architecture

### Pipeline Flow

```
<!-- DL 파이프라인 도식화 -->
Training: Data → Augmentation → Feature Extraction → Model → Loss → Optimizer
Testing:  Data → Feature Extraction → Model → Scoring → Metrics (AUROC, F1, etc.)
```

### Key Modules

- `main.py` — 실험 진입점, 학습/평가 오케스트레이션
- `models/` — 모델 아키텍처 정의
- `data_provider/` — 데이터 로더 (공개 데이터 + 기업 데이터 포맷 대응)
- `utils/` — metrics, visualization, augmentation 등
- `configs/` — 실험 설정 (YAML)
- `scripts/` — 실험 스위트, 리포트 생성 스크립트
- `demo/` — 기업 데모/발표용 (Gradio/Streamlit 등)
- `reports/` — 자동 생성 성능 리포트

### Score Convention

<!-- 점수 해석 규약 명시 (혼동 방지) -->
<!-- 예: "Lower score = more normal" 또는 "Higher anomaly_score = more anomalous" -->

### Extension Pattern

<!-- 새 모듈 추가 시 따라야 할 패턴 -->
<!-- 예: "@register('name') decorator + @dataclass" 또는 "models/ 아래 새 파일 → factory에 등록" -->

## Data Layout

```
data/
├── public/              # 공개 데이터셋 (MVTecAD, ImageNet 등)
│   └── {dataset_name}/
│       ├── train/
│       └── test/
└── proprietary/         # 기업 제공 데이터 (git 미추적!)
    ├── README.md        # 데이터 출처, 사용 조건, 라이선스 기록
    ├── raw/             # 원본 데이터
    └── processed/       # 전처리 완료 데이터
```

**주의**: 기업 제공 데이터는 `.gitignore`에 반드시 포함. 외부 유출 금지. 경로 하드코딩 금지 — 반드시 config에서 지정.

## Dependencies

<!-- 런타임 의존성 -->
<!-- 예: torch, torchvision, timm, omegaconf, wandb, numpy, pandas, scikit-learn, scipy, matplotlib, pillow, opencv-python-headless -->

## Config Parameter Tags

Config 주석에 사용하는 태그:
- `[TUNE]` = 자주 튜닝하는 하이퍼파라미터 (lr, batch_size, augmentation 등)
- `[ARCH]` = 아키텍처 선택 (backbone, loss function 등)
- `[DEPRECATED]` = 호환성 유지용 (미사용)

---

## Context Engineering

산학과제에서 Claude의 행동을 결정하는 문맥 조합:
- **CLAUDE.md** — 프로젝트 원칙, 마일스톤, 워크플로우 규칙
- **contexts/** — 세션 모드별 행동 지침
- **templates/** — 납품물·거버넌스 템플릿
- **hooks/** — 자동 실행 품질 관리

### Cowork File Structure
```
project/
├── plan.md          # 실험/구현 계획 + 마일스톤 연결
├── handoff.md       # 인수인계 상태
├── outputs/         # 산출물 (보고서, 데모, 모델 등)
└── decision-log.md  # 기술/납품 결정 기록
```

---

## Agents

프로젝트에서 활용 가능한 전문 에이전트. `agents/` 디렉토리에 정의.

| 에이전트 | 모델 | 용도 | 활성화 시점 |
|---------|------|------|-----------|
| planner | opus | 실험/구현 계획 수립, 마일스톤 연결 | 3단계+ 작업, 방법론 설계 |
| builder | sonnet | plan.md 기반 구현, 변경 기록 | planner 계획 확정 후 |
| reviewer | sonnet | 결과물 검증, 판별 | builder 작업 완료 후 |
| code-reviewer | sonnet | 코드 품질/보안 리뷰 | 코드 변경 후 |

에이전트 호출: Subagent Strategy에 따라 서브에이전트로 실행하거나 참조 문서로 활용.

### Planner / Builder / Reviewer 프로토콜
1. **planner** → `plan.md` 작성 (실험 설계 + 납품 마일스톤 연결)
2. **builder** → `plan.md` 기준 구현, `implementation-notes.md` 기록
3. **reviewer** → `review-findings.md`에 납품 기준 대비 검증
4. **human** → `decision-log.md`에 최종 판단

## Codex 교차검증 (보조 에이전트) ★

- **Claude Code = 메인 에이전트**: 이해·계획·구현·검증 주도.
- **Codex = 보조 에이전트**: 다른 모델·다른 추론 경로의 *독립적 제2의 눈*. Claude가 놓친 **버그·엣지케이스·보안**을 잡고 **설계·접근 대안**을 제시.

**제어 모델 (Human in the Loop)**: Codex는 자동 실행하지 않는다. Claude가 "제2의 눈이 필요하다" 판단 시 **사용자에게 먼저 제안 → 승인 후** `/cross-check`로 호출한다.

**제안 시점**: 비자명한 로직 작성/대규모 변경 후, 커밋·PR·납품 직전, 보안·기업 데이터 처리·수치 안정성 영역, ML/DL의 데이터 누수·재현성·지표 해석 등 결과 신뢰성이 걸린 지점.

**교차검증 루프**: ① 범위 지정·제안 → ② 승인 시 Codex **read-only** 실행(읽고 비평만) → ③ **Claude가 각 finding을 직접 검증**(✅동의/⚠️부분/❌오탐) → ④ 동의 항목만 Claude가 수정, 설계 대안은 trade-off 정리 후 사용자 판단 → ⑤ 확정 버그는 `tasks/lessons.md` 승격 후보.

> 대규모 병렬 자율 구현은 `/orchestrate`(Codex worker)의 영역으로 교차검증과 구분한다.

## Context Modes

세션 중 작업 모드 전환. `contexts/` 디렉토리의 모드 파일 참조.

| 모드 | 파일 | 포커스 |
|------|------|--------|
| dev | `contexts/dev.md` | 구현 집중 — 코드 먼저, 설명 후 |
| research | `contexts/research.md` | 탐색 집중 — 이해 먼저, 코드 후 |
| review | `contexts/review.md` | 리뷰 집중 — 품질, 보안, 유지보수성 |
| cowork | `contexts/cowork.md` | 파일 기반 협업 — plan.md/handoff.md/outputs/ |
| autoresearch | `contexts/autoresearch.md` | 자율 실험 루프 — program.md 기반 무한 반복 |

활성화: "이 세션은 [모드] 모드로 진행합니다" 또는 해당 파일 참조 요청.

### AutoResearch 연동

`/autoresearch`로 납품 전 빠른 탐색 실험을 자율 실행할 수 있습니다.
유망한 결과는 6단계 프로세스로 검증 후 납품물에 반영합니다.

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
- 납품 일정이 빠듯할 때는 plan mode로 범위(scope)를 명확히 한 뒤 착수

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
- 납품물은 데모/리포트 실행까지 확인 후 완료 처리

### 5. Demand Elegance (Balanced)
- 비자명한 변경에는 "더 우아한 방법이 있지 않은가?" 자문
- 단순·명백한 수정에는 생략 — 과잉 설계 금지
- 납품 데드라인 고려: 우아함보다 납품 기한이 우선일 수 있음

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
- 실험 시작 전 `report.md`에 1~3단계(문제분석/가설/설정)를 **먼저 작성** 후 실행
- 실험 완료 후 4~6단계(결과/분석/피드백)를 기록
- 가설 검증 결과가 반복 활용 가능하면 `analysis/{주제}/_lessons.md`로 승격
- 후속 실험은 `## 관련 노트`에서 선행 실험 report.md를 링크하여 연쇄 추적
- **납품 마일스톤과 연결**: 각 실험이 어떤 납품물에 기여하는지 report.md에 명시

**실험 디렉토리 구조:**
```
skill_graph/experiments/YYYY-MM-DD_실험명/
├── report.md            # 6단계 프로세스 전체 기록
├── config_diff.yaml     # baseline 대비 변경된 config
└── logs/                # 실험 로그 (stdout, wandb export 등)
```

## Update Notes

실험, 분석, 버그픽스, 아이디어 등 유의미한 작업 시 반드시 `skill_graph/` 아래에 `.md` 파일로 기록한다.

```
skill_graph/
├── experiments/              # 실험 기록 (6단계)
│   ├── _TEMPLATE.md
│   └── YYYY-MM-DD_실험명/
│       ├── report.md
│       ├── config_diff.yaml
│       └── logs/
├── analysis/                 # 분석 + 검증된 패턴
│   └── 주제명/
│       ├── YYYY-MM-DD_설명.md
│       └── _lessons.md       # tasks/lessons.md에서 승격된 검증 패턴
├── bugfix/                   # 버그 수정 기록
├── ideas/                    # 연구 아이디어
├── deliverables/             # 📦 납품물 관련 기록
│   ├── _TEMPLATE.md
│   └── YYYY-MM-DD_마일스톤명.md
└── meetings/                 # 📋 회의록
    ├── _TEMPLATE.md
    └── YYYY-MM-DD_참석자_주제.md
```

**스킬 그래프:**
- 노트 간 `## 관련 노트`로 상대 경로 링크
- 실험 → 분석 → 아이디어 → 후속 실험 흐름 추적
- 납품물/회의록에서 관련 실험 노트 역링크
- 반복되는 패턴이나 검증된 기법은 `analysis/{주제}/_lessons.md`로 승격

## Deliverable Rules (납품물 관리)

- 모든 납품물 관련 의사결정/변경사항은 `skill_graph/deliverables/`에 기록
- 납품 보고서 작성 시 `skill_graph/experiments/`의 결과를 참조·인용
- 기업 미팅 후 `skill_graph/meetings/`에 회의록 작성 (액션아이템 포함)
- **모델 납품 시 체크리스트**: 추론 코드, 가중치 파일, 환경 설정, 입출력 스펙 문서

---

## Core Principles

- **Simplicity First**: 모든 변경은 가능한 한 단순하게. 최소한의 코드에만 영향을 줄 것
- **No Laziness**: 근본 원인을 찾아라. 임시방편 금지. 시니어 개발자 기준을 적용
- **Minimal Impact**: 변경은 필요한 것만. 불필요한 버그 유입 방지
- **모듈화 필수**: 새롭게 추가하는 모든 모듈/기능은 config에서 `enable: true/false`로 on/off 가능하게 구현. 과거 실험을 config만으로 정확히 재현할 수 있어야 한다.
- **Reproducibility**: seed 고정, config 기록, 환경 명시 (requirements.txt 또는 pyproject.toml)
- **Ablation-friendly**: 각 컴포넌트를 독립적으로 on/off 가능하게 설계
- **기업 데이터 보안**: proprietary 데이터 경로는 `.gitignore`에 포함, 하드코딩 금지
- **Demo-ready**: 주요 기능은 `demo/`에서 단독 실행 가능하게 유지
- **모델 경량화 고려**: 기업 배포 환경의 제약 (GPU 유무, 지연시간, 메모리) 인지

## Important Conventions

<!-- 프로젝트 고유 규약 -->
<!-- 예: import 방식, 텐서 형식 (B,C,H,W), 평가 프로토콜 등 -->
-
