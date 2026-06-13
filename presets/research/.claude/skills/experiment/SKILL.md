---
name: experiment
description: 6단계 실험 프로세스 — 가설 설정부터 교훈 승격까지
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash
  - EnterPlanMode
---

# /experiment

**사용법**: `/experiment <experiment-name>`

이전 실험 목록:

```!
find skill_graph/experiments -name '*.md' ! -name '_TEMPLATE.md' 2>/dev/null | sort
```

## 동작

1. `$ARGUMENTS`에서 `<experiment-name>` 파싱
   - 인자 없으면 → 기존 실험 목록 출력 + 각 실험 상태(🔴/🟡/🟢) 요약
2. `skill_graph/experiments/_TEMPLATE.md` 기반으로 실험 노트 생성:
   - 경로: `skill_graph/experiments/YYYY-MM-DD_<experiment-name>.md`
   - 실험 ID 자동 생성: `exp_YYYYMMDD_<짧은코드>`
3. **Phase 1 (1~3단계) 작성 가이드**:
   - 문제 분석 → 가설 설정 → 실험 설정 순서대로 작성 유도
   - 가설에 **정량적 예상값 필수** (예: "mAP 3% 향상 예상")
4. Phase 1 완료 확인 후 실험 실행
5. **Phase 2 (4~6단계) 작성 가이드**:
   - 결과 기록 → 분석 → 피드백/다음 단계

## 규칙

- **Phase 1 완료 전 실험 실행 금지** — 가설 없는 실험은 시간 낭비
- 가설에 반드시 정량적 예상값 포함 (모호한 "개선될 것" 금지)
- 이전 실험의 `## 관련 노트` 확인하여 연결 관계 설정
- 결론은 ✅/❌/⚠️ 중 하나로 명확하게
- 교훈이 반복 검증되면 `/lessons promote`로 승격
