---
name: deliverable
description: 납품물 추적 — 마일스톤 기한 관리 + 실험 결과 연결
allowed-tools:
  - Read
  - Write
  - Glob
---

# /deliverable

**사용법**: `/deliverable [<deliverable-name> | status | (빈 인자)]`

현재 납품물 목록:

```
!find skill_graph/deliverables -name '*.md' ! -name '_TEMPLATE.md' 2>/dev/null | sort!
```

## 동작

### 인자 없음 또는 `status` → 납품물 현황
- 전체 납품물 목록 + 상태(🔴/🟡/🟢/✅) 출력
- **기한 경고**: 7일 이내 마감 납품물 하이라이트
- 각 납품물에 연결된 실험 결과 수 표시

### `<deliverable-name>` → 납품물 노트 생성
1. `skill_graph/deliverables/_TEMPLATE.md` 기반으로 새 노트 생성:
   - 경로: `skill_graph/deliverables/YYYY-MM-DD_<deliverable-name>.md`
2. 사용자에게 다음 정보 요청:
   - 해당 마일스톤
   - 기한
   - 납품 요구사항
3. 기존 실험 결과 중 포함할 항목 선택 유도:
   - `skill_graph/experiments/` 내 완료된 실험 목록 제시
4. 작성 계획(보고서 목차 등) 초안 생성

## 규칙

- 기한은 반드시 명시 — 기한 없는 납품물은 생성 불가
- 마일스톤 기한 7일 전부터 매 세션 시작 시 경고
- 포함할 실험 결과는 **완료(🟢)** 상태인 것만 선택
- 납품 후 기업/교수 피드백은 `## 피드백 (납품 후)` 섹션에 기록
- 피드백에서 발견한 교훈은 `/lessons add`로 즉시 기록
