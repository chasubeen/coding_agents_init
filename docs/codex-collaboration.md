# Claude + Codex 협업 설계 (Codex Collaboration)

이 템플릿의 시그니처 하네스 요소. **Claude Code(메인)** 와 **Codex(보조)** 가 어떻게 분업하는지 정리한다.

## 왜 보조 에이전트인가

같은 작업을 한 모델에게만 맡기면, 그 모델의 **사각지대(blind spot)** 가 그대로 결과에 남는다.
Codex는 Claude와 **다른 모델·다른 학습 분포·다른 추론 경로**를 갖기 때문에, Claude가 "맞다"고 확신한 곳에서 다른 문제를 본다.
이건 사람 코드리뷰에서 *제2의 리뷰어*를 두는 것과 같은 원리다 — 중복이 아니라 **독립적인 증거의 추가**.

> 핵심: 교차검증은 *판단을 외주 주는 것*이 아니다. **더 많은 증거를 모아 Claude가 더 나은 판단을 하도록** 돕는 것이다.

## 역할 분담

| | Claude Code (메인) | Codex (보조) |
|--|--------------------|--------------|
| 위치 | 사용자가 직접 대화하는 주 인터페이스 | Claude가 CLI로 호출하는 하위 프로세스 |
| 주 임무 | 이해·계획·구현·검증·최종 판단 | ① 교차검증(리뷰) ② 병렬 구현(orchestrate) |
| 기본 권한 | 전체 | 교차검증은 **read-only** (읽고 비평만) |
| 결정권 | **있음** (Codex 의견을 채택/기각) | 없음 (의견 제시만) |

## 두 가지 협업 모드

### 모드 1 — 교차검증 리뷰어 (`/cross-check`) · 기본

Claude가 작업 중 "제2의 눈이 필요하다"고 판단 → **사용자에게 제안** → 승인 시 Codex를 read-only로 호출.

```
[Claude 작업] → [Claude: "Codex 교차검증 받을까요?"] → [사용자 승인]
   → [Codex read-only 리뷰] → [Claude가 각 finding 검증] → [동의 항목만 수정]
```

집중 축:
- **A. 버그 헌팅** — correctness, 엣지케이스, 보안, (ML/DL) 데이터 누수·split 오염·재현성·지표 해석·shape/dtype/device·NaN/inf
- **B. 설계 대안** — 더 나은 알고리즘·추상화·trade-off 제시

판정 규율: Codex 출력은 **결론이 아니라 입력**이다. Claude가 각 항목을 실제 코드로 검증해 ✅동의 / ⚠️부분동의 / ❌오탐으로 판정한 뒤에만 반영한다. (Codex도 틀린다 — 오탐을 거르는 것도 교차검증의 일부)

### 모드 2 — 병렬 워커 (`/orchestrate`) · 고급

3개 이상 독립 파일에 걸친 대규모 작업을, 여러 Codex 인스턴스에 분배해 격리된 git worktree에서 동시에 구현. `orchestrator/` Python 모듈이 세션·실행·머지를 관리. 이때 Codex는 `workspace-write`로 코드를 직접 수정한다.

→ 모드 2는 "속도", 모드 1은 "정확성/관점". 둘을 혼동하지 말 것.

## 제어 모델: Human in the Loop

| 모델 | 설명 | 채택 |
|------|------|------|
| A. 완전 수동 | 사용자가 직접 `/cross-check` 입력 | |
| **B. Claude 제안 → 사용자 승인** | Claude가 시점을 판단해 제안, 승인 시 호출 | **✓ 기본** |
| C. 자동 실행 | 훅이 commit/push 때 무조건 실행 | (비용·흐름 끊김) |

훅(`codex-crosscheck-reminder.sh`)의 역할은 C가 아니라 **B의 알림**이다 — Codex를 직접 돌리지 않고, 비자명한 변경을 커밋/푸시하려는 순간 "지금 교차검증을 제안하라"고 Claude에게 nudge만 준다. 최종 실행은 항상 사용자 승인.

## 전제 조건

- Codex CLI 설치 + 로그인 (`codex --version`으로 확인)
- `.codex/config.toml`의 `crosscheck`(read-only) / `worker`(workspace-write) 프로필 참조
- Codex 미설치 시 `/cross-check`는 안내 후 중단 — Claude 자체 검토로 대체 가능

## 관련 파일

- `.claude/skills/cross-check/SKILL.md` — `/cross-check` 스킬 정의
- `.claude/skills/orchestrate/SKILL.md` — `/orchestrate` 스킬 정의
- `hooks/codex-crosscheck-reminder.sh` — 교차검증 제안 nudge 훅
- `.codex/config.toml` — Codex CLI 프로필 참조 템플릿
- `AGENTS.md` — Codex 관점의 운영 지침
- `orchestrator/` — 병렬 멀티에이전트 모듈
