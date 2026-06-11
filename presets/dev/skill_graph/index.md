# Skill Graph Index

> 개발 위키의 탐색 진입점.
> 문서 본문은 wiki, 관계 의미는 `schema.md`의 typed relation으로 해석합니다.
> 새 문서 추가 시 이 파일과 `log.md`를 함께 갱신합니다.

---

## 운영 레이어

- `README.md` — 개발 위키 운영 방식
- `schema.md` — feature / bugfix / decision 관계 규약
- `log.md` — append-only 변경 이력

---

## 관계 그래프

```
<!-- typed relation을 기준으로 ASCII 다이어그램을 유지 -->
```

---

## 문서 카탈로그

| 문서 ID | 문서 | note_type | 상태 | 핵심 키워드 |
|---------|------|-----------|------|-------------|
| <!-- `feat-20260407-session-resume` | [문서 제목](features/YYYY-MM-DD_name.md) | feature | in_progress | `session` `resume` --> |

---

## 문서 → 키워드 역매핑

### features/

| 문서 | Phase | 상태 | 키워드 |
|------|-------|------|--------|
<!-- | [제목](features/YYYY-MM-DD_name.md) | N | 🟢 | `kw1` `kw2` | -->

### decisions/

| 문서 | 상태 | 키워드 |
|------|------|--------|
<!-- | [제목](decisions/YYYY-MM-DD_adr.md) | 승인 | `kw1` `kw2` | -->

### bugfix/
_(아직 없음)_

### refactor/
_(아직 없음)_

### devops/
_(아직 없음)_

---

## relation registry

| relation | 의미 |
|----------|------|
| `depends_on` | 구현/결정 선행 필요 |
| `blocked_by` | 해결 전 진행 불가 |
| `supersedes` | 이전 구현/결정 대체 |
| `derived_from` | 버그/결정/교훈에서 파생 |
| `related_to` | 주제 연결 |

---

## 타임라인

| 날짜 | 문서 | 요약 |
|------|------|------|
<!-- | YYYY-MM-DD | [문서 제목](path) | 한 줄 요약 | -->
