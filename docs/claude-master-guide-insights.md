# Claude Master Guide - 핵심 인사이트 정리

> 원문: "Claude Code & Cowork Master Guide" (321p)
> 정리일: 2026-03-23

## 문서 개요

Claude Code와 Cowork를 실무에서 효과적으로 활용하기 위한 종합 가이드.
단순 기능 설명이 아니라 **설계 철학, 운영 원칙, 직무별 플레이북, 실전 상황별 대응법**까지 포함.

---

## 1. 핵심 설계 철학

### Context Engineering > Prompt Engineering
- 프롬프트는 "지금 이렇게 말할지"의 문제, **Context는 "무엇을 같이 읽힐지"**의 문제
- CLAUDE.md, rules, hooks, templates, context 파일들이 합쳐져서 모델의 행동을 결정
- **Context Sandwich**: 프롬프트 맨 앞에는 글로벌 규칙, 가운데는 작업 문맥, 뒤에는 다시 제약조건

### Harness Engineering
- 모델이 동작하는 **실행 환경 자체를 설계**하는 일
- settings.json, hooks, approval gates, sandbox 등이 harness의 구성요소
- "프롬프트가 아니라 환경으로 제어하라"

### Cowork = 파일 기반 작업면
- Claude 세션의 맥락을 **파일로 관리**하는 패러다임
- `plan.md`, `handoff.md`, `outputs/` 폴더가 핵심 구조
- "같은 단위 하나 추가한 것"이 아니라 관리와 산출물을 한 호흡으로 묶는 작업면

---

## 2. 아키텍처 핵심 개념

| 개념 | 설명 |
|------|------|
| **Skill** | 작업을 하는 법 (slash command) |
| **Plugin** | 그 일을 돕는 설치되는 상자 (skills, commands, agents, hooks, MCP LSP 묶음) |
| **MCP** | 외부 도구 연결 규격 |
| **Connector** | 사용자가 바로 자리 잡는 연결 표면 |
| **Scope** | `managed`, `user`, `project`, `local` — 규칙이 어디서 적용되는지 |
| **Channel** | 외부 이벤트를 감지해 새 세션으로 연결하는 통로 |
| **Scheduled Task** | 시간 기반으로 자동 실행 |

### Skill vs Plugin 구분
- Skill = "할 줄 아는 법" / Plugin = "그 법이 설치되는 상자"
- 같은 브랜드 이름이지만 역할이 다름

### 추가 용어 구분
- **MCP vs Connector**: MCP는 연결 규격, Connector는 사용자가 바로 자리 잡는 연결 표면
- **Prompt Engineering vs Context Engineering**: Prompt는 지금 이렇게 말할지, Context는 무엇을 같이 읽힐지
- **Context Engineering vs Harness Engineering**: Context는 무엇을 넣을지 골라 읽히기, Harness는 어떤 규칙과 환경에서 읽히게 할지
- **Remote Control vs Claude Code on the web**: Remote Control은 이미 돌고 있는 세션 유지받기, on the web은 원격 VM에서 새 작업 취급

---

## 3. 거버넌스 & 보안

### 거버넌스는 가장 늦게 오면 안 됨
- 작은 팀도 최소 거버넌스 세트가 필요:
  - `CLAUDE.md`, `settings.json`, `outputs/` 폴더, `work-log.md`, `approval-log.md`
- **고위험 작업은 prompt가 아니라 정책으로 막아라** (hooks, sandbox, approval gate)

### 고위험 작업 등급표

| 등급 | 예시 |
|------|------|
| 낮음 | 파일 읽기, 내부 초안 작성, 테스트 추가 |
| 중간 | 고객용 초안 작성, 주기 보고서 자동 생성, 코드 리팩터링 |
| 높음 | 프로덕션 배포, 고객 발송, 요금 강제, 권한 변경, 민감 데이터 조회 |

### 최소 권한 문서 예시

```markdown
# AI Tool Access Policy

## Allowed by default
- Read, Edit, Write inside approved workspaces
- lint, test, build commands
- approved plugins from managed marketplace

## Requires human approval
- deployment
- customer-facing email send
- scheduled tasks with external side effects
- database writes

## Blocked
- reading `.env*`
- destructive shell commands
- unapproved MCP servers
- editing outside approved repositories
```

### 감사 가능성 (Auditability) 확보
- 최소 흔적 세트:
  1. `source/` — 원본 자료 또는 원본 링크
  2. `outputs/` — Claude가 만든 초안과 수정본
  3. `work-log.md` — 무엇을 언제 실행했는지
  4. `approval-log.md` — 누가 언제 승인했는지
  5. `handoff.md` — 남은 하찮다 다음 단계

### 고위험 작업 등급별 승인 방식
- 낮음: 자동 실행 가능
- 중간: 사람 검토 후 실행
- 높음: 사람 승인 없이는 실행 금지

### 도입 우선순위
1. 1주차: `.env` 와 파괴적 명령 차단, 배포와 발송분 무조건 승인
2. 2주차: 공용 plugin / skill만 허용, 프로젝트급 CLAUDE.md rules 적용
3. 3주차: 비용 모니터링, 승인 로그와 handoff 로그 정착

---

## 4. 직무별 플레이북

### 4.1 창업가 / 1인 사업가
- **최소 파일**: `about-me.md`, `current-projects.md`, `investor-tone.md`
- 첫 프롬프트 패턴: brief + 3가지 변화 중 핵심만 정리
- 핵심: 시장 해석과 우선순위 결정은 사람 몫

### 4.2 제품 관리자 PM
- **최소 파일**: `product-principles.md`, `prd-template.md`, `meeting-notes-template.md`
- open questions를 분리하고 PRD에 정보 평가와 결정 분석까지 포함
- 핵심: 범위 확장과 이해관계 조정

### 4.3 마케팅 / 콘텐츠
- **최소 파일**: `brand-voice.md`, `anti-ai-writing-style.md`, `audience-notes.md`
- "브랜드 보이스 파일을 먼저 세팅하면 Claude가 매번 초안을 일관되게 만듦"
- 핵심: 최종 시각 방향과 브랜드 톤

### 4.4 세일즈 / 고객 성공
- **최소 파일**: `icp.md`, `tone-guidelines.md`, `account-brief-template.md`, `followup-email-template.md`
- CRM 연동, follow-up skill, Cowork plugin customization
- 핵심: 대외 발송과 약속은 반구 확정

### 4.5 디자인 / 브랜딩
- **최소 파일**: `brand-rules.md`, `design-review-rules.md`, `ui-review-checklist.md`
- `component-glossary.md`, `state-checklist.md` 같은 파일이 design drift 방지
- 핵심: 최종 시각 방향과 브랜드 승인

### 4.6 엔지니어링
- **핵심 스택**: CLAUDE.md > 주력 언어 LSP > code-review > test/lint hook
- `plan.md`와 `handoff.md` 필수
- acceptance criteria를 파일로 남기고 변경의 변소 항목 확인
- "코드를 대신 쓰는 도구"가 아니라 "변경을 관리하는 흐름을 돕는 도구"
- 핵심: 핵심 구조 변경과 배포 판단

### 4.7 법무 / 컴플라이언스
- **최소 파일**: `risk-bucket.md`, `must-escalate.md`, `contract-review-template.md`
- 핵심: 최종 법적 판단과 외부 문안 확정

### 4.8 재무 / 분석
- **최소 파일**: `metric-glossary.md`, `report-template.md`, `query-guardrails.md`, `review-before-send.md`
- xlsx, pptx, Excel/PowerPoint add-in 활용
- 핵심: 원본 숫자 검증과 공식 보고 승인

### 4.9 백오피스 / 운영
- **최소 파일**: `accounting-rules.md`, `exceptions.md`, `must-review.md`
- scheduled task와 low-confidence 감지가 핵심
- 핵심: 공식 입력, 발송, 삭제, 결산

### 4.10 연구 / 학습
- **최소 파일**: `paper-queue.md`, `claim-table.md`, `disagreement-table.md`, `reproduction-plan.md`
- 논문의 핵심 주장, 실험 조건, 평가 기준, 한계를 표로 정리
- 핵심: 주장 해석과 재현 결과 판단

### 4.11 팀 운영자 / 에이전시 대표
- 멀티 클라이언트 구조, naming convention, plugin 배포 관리
- `shared-rules.md`, `naming-convention.md`
- 핵심: 고객별 승인 경계와 공통 규칙

---

## 5. 비용/도구 분류 매트릭스

| 등급 | 도구 유형 |
|------|--------|
| **초등 (무료/최소)** | 주력 언어 LSP 1개, code-review, brand-guidelines |
| **초중 (소액)** | webapp-testing, docx/pptx/xlsx, Cowork plugin 1개 |
| **초중~중** | 잘 안 쓰는 MCP 여러 개 감시 필요, 실험용 plugin 여러 개 동시 실행 |

### 추천 조합 (처음 2주)
- **개인 개발자**: typescript-lsp 또는 주력 언어 LSP + code-review + hookify
- **프론트엔드 팀**: frontend-design + webapp-testing + code-simplifier
- **비개발 운영팀**: brand-guidelines + docx + Cowork plugin 1개
- **리서치/분석팀**: pdf + xlsx + 검색 개별 MCP 1개

### 역할별 "딱 하나만" 먼저 고른다면
- 비개발 운영팀: docx 또는 Cowork plugin 1개
- 전사/브랜드 팀: brand-guidelines
- 프론트엔드 팀: frontend-design
- 개발팀: code-review 또는 주력 언어 LSP 1개
- 리서치/분석팀: pdf 또는 검색 개별 MCP 1개

---

## 6. 실전 상황별 가이드 (13장)

| 상황 | 핵심 대응 |
|------|--------|
| 월요일 아침 브리프 | `brief.md` + `working-rules.md` + `template` 3파일로 시작 |
| 회의록 정리 | `raw-notes.md` → 감정/논쟁 분리 → `meeting-notes-template.md` |
| PM PRD 작성 | `research-brief.md` + `open-questions.md` → PRD |
| 마케터 콘텐츠 | `brand-voice.md` + `anti-ai-writing-style.md` → 에디토리얼 순환 체계 |
| 주니어 개발자 | CLAUDE.md + plan.md 먼저, 좋은 방향으로 배울 때 틀리지 않게 하는 프레임 |
| 팀장 AI 도입 | scope별 규칙 (managed, user, project, local) + plugin marketplace |
| 운영 담당 반복 업무 | 선별 자동화 + approval gate |
| 교육자 | `glossary.md`, `lesson-template.md`, `quiz-template.md` |
| 시트→발표 변환 | metric-glossary + deck-template + review-rules |
| 원격 이어받기 | `plan.md` + `handoff.md` + `outputs/` 3파일 필수 |
| 멀티 에이전트 충돌 | planner/builder/reviewer 역할 분리 + `decision-log.md` |
| 비용 폭증 | 공유 파일 200줄 제한, 강한 패턴 규칙, glossary 도입 |
| 디자인-실제 괴리 | `component-glossary.md` + `state-checklist.md` + `design-review-rules.md` |
| 회의 메모 → 자료 변환 | `transcript.md` → `notes.md` → `outputs/` 구조 |
| "앞으로 다 AI로 하지" | 구조와 역할 분리가 먼저, 사람이 빠지지 않는 지점 식별 |

---

## 7. 멀티 에이전트 프로토콜

### planner / builder / reviewer 역할 분리
- **planner**: 제약, 할 일, 바지 않을 입출력 → `plan.md`에 적는다
- **builder**: `plan.md`만 기준으로 작업하고 변경 내용을 `implementation-notes.md`에 남김
- **reviewer**: 결과물 + 검증 기준만 읽고 `review-findings.md`에 판별만 적는다
- **human**: `decision-log.md`에 최종 판단한 남긴다

### 최소 충돌 규약
```
1. planner는 `plan.md`에 변위, 현재 기준, 제약 범위를 잡아 적는다.
2. builder는 `plan.md`만 기준으로 작업하고 변경 내용을 `implementation-notes.md`에 남긴다.
3. reviewer는 결과물 + 검증 기준만 읽고 `review-findings.md`에 판별만 적는다.
세 역할이 같은 파일을 동시에 편집하지는 않는다.
마지막 판단은 내가 `decision-log.md`에 남긴다.
```

---

## 8. 설계 철학을 운영 원칙으로 번역하면

1. **좋 정보와 또는 어떤식 사용을 내린다** — 책임 가능한 사람이 직접 판단하는 구조
2. **고위험 작업은 프롬프트가 아니라 정책으로 막는다** — settings, hook, approval gate로 막기
3. **긴 작업은 반드시 상태 파일을 남긴다** — plan.md, decision-log.md, handoff.md
4. **현재 역할은 사람이 아니라 멥을 위해 설명으로 정의한다** — skill로 정의
5. **잘하는 사람의 감각을 될 전환에 비해 제약 줄이리고 지식을 로그로 넘겨야 한다**
6. **모든 자동화에는 멈추는 기준이 있어야 한다** — stop rule
7. **에이전트 팀은 순서가 아니라 프로토콜로 설계한다** — planner/builder/reviewer 분리

---

## 9. 앞으로 주목할 방향

- Markdown 기반으로 바뀌면 변화 추적, 슬라이드 변환 등 가능성 확장
- 2026년 Q2, Q3 변화 추세: Cowork UI Customize, plugin marketplace, Claude Code channels, Remote control
- 엔터프라이즈의 조직 규모와 파일 구조에 따라 다르게 제시할 수 있음
- **결국 응용자는 설계 철학으로 남아야 한다** — 도구가 바뀌어도 원칙은 유지

---

## 10. 용어집 빠른 참조 (14장 발췌)

| 용어 | 설명 |
|------|------|
| Context Engineering | Claude가 읽고 추적하는 문맥 구조를 설계하는 일 |
| Harness Engineering | 모델이 동작하는 실행 환경을 설계하는 일 |
| Context Sandwich | 글로벌 규칙 → 작업 문맥 → 제약조건 순서 구조 |
| Context Window | 모델이 한 번에 처리 가능한 전체 입력 범위 |
| Cowork | 파일 기반 작업면 |
| Skill | 작업을 하는 법 |
| Plugin | 설치되는 역할 패키지 |
| Scope | managed, user, project, local |
| Channel | 외부 이벤트 통로 |
| Scheduled Task | 시간 기반 자동 실행 |
| Approval Gate | 다음 단계 진입 전 승인 필요 |
| Guardrail | 위험 행동 방지 보호장치 |
| Sandbox | 격리 실행 환경 |
| Handoff.md | 인수인계 상태 파일 |
| Decision Log | 무엇을 왜 그렇게 결정했는지 기록 |
| Claim Table | 논문 핵심 주장 정리표 |
| Reproduction Plan | 재현 계획서 |
| Token Budget | 토큰 비용 예산 |
| Persistent Thread | Anthropic의 지속 세션 |
| Remote Control | 원격 세션 이어받기 |
| Design Drift | 디자인 파일과 실제 구현 사이 괴리 |
| Bidirectional Loop | 양방향 수정-반영 순환 구조 |
