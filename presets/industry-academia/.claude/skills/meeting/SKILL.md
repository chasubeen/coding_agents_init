---
name: meeting
description: 회의록 자동 생성 — 참석자, 안건, Action Items 관리
allowed-tools:
  - Read
  - Write
  - Glob
---

# /meeting

**사용법**: `/meeting [<meeting-title> | list | (빈 인자)]`

최근 회의록:

```
!find skill_graph/meetings -name '*.md' ! -name '_TEMPLATE.md' 2>/dev/null | sort -r | head -5!
```

## 동작

### 인자 없음 또는 `list` → 회의록 목록
- `skill_graph/meetings/` 내 회의록 목록 출력
- 미완료 Action Items가 있는 회의록 하이라이트

### `<meeting-title>` → 회의록 생성
1. `skill_graph/meetings/_TEMPLATE.md` 기반으로 새 회의록 생성:
   - 경로: `skill_graph/meetings/YYYY-MM-DD_<meeting-title>.md`
   - 날짜 자동 치환
2. 사용자에게 다음 정보 요청:
   - 참석자
   - 안건
3. 회의 내용을 구조화하여 기록:
   - 논의 내용
   - 결정 사항
   - **Action Items** (담당자, 내용, 기한, 상태)
4. Action Items를 `tasks/todo.md`에도 반영 (사용자 승인 시)

## 규칙

- 회의록은 **결정 사항**과 **Action Items** 중심으로 간결하게
- Action Items에는 반드시 담당자와 기한 지정
- 이전 회의의 미완료 Action Items가 있으면 상단에 리마인드
- 납품물 관련 결정은 `skill_graph/deliverables/` 해당 노트에도 반영
