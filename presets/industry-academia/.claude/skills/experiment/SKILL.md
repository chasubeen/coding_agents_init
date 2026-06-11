---
name: experiment
description: 6단계 실험 프로세스 — 마일스톤/납품물 연결 포함
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

```
!find skill_graph/experiments -name '*.md' ! -name '_TEMPLATE.md' 2>/dev/null | sort!
```

관련 납품물:

```
!find skill_graph/deliverables -name '*.md' ! -name '_TEMPLATE.md' 2>/dev/null | sort!
```

## 동작

1. `$ARGUMENTS`에서 `<experiment-name>` 파싱
   - 인자 없으면 → 기존 실험 목록 + 납품물 연결 상태 출력
2. `skill_graph/experiments/_TEMPLATE.md` 기반으로 실험 노트 생성:
   - 경로: `skill_graph/experiments/YYYY-MM-DD_<experiment-name>.md`
   - 실험 ID 자동 생성: `exp_YYYYMMDD_<짧은코드>`
3. **마일스톤/납품물 연결**:
   - `skill_graph/deliverables/` 내 현재 활성 납품물 확인
   - 해당 실험이 어떤 납품물에 기여하는지 연결 설정
   - 납품물의 `## 포함할 실험 결과` 섹션에 링크 추가
4. **Phase 1 (1~3단계) 작성 가이드**:
   - 문제 분석 → 가설 설정 → 실험 설정 순서대로 작성 유도
   - 가설에 **정량적 예상값 필수**
5. Phase 1 완료 확인 후 실험 실행
6. **Phase 2 (4~6단계) 작성 가이드**:
   - 결과 기록 → 분석 → 피드백/다음 단계

## 규칙

- **Phase 1 완료 전 실험 실행 금지** — 가설 없는 실험은 시간 낭비
- 가설에 반드시 정량적 예상값 포함
- 실험 결과가 납품물에 포함될 경우, 납품물 노트의 `## 포함할 실험 결과`에 즉시 반영
- 마일스톤 기한이 임박한 경우(7일 이내) 경고 메시지 출력
- 교훈이 반복 검증되면 `/lessons promote`로 승격
