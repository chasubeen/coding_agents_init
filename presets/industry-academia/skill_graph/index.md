# Skill Graph Index

> 산학 위키의 탐색 진입점.
> 문서 본문은 wiki, 관계 의미는 `schema.md`의 typed relation으로 해석합니다.
> 새 문서 추가 시 이 파일과 `log.md`를 함께 갱신합니다.

---

## 운영 레이어

- `README.md` — 산학 위키 운영 방식
- `schema.md` — meeting / deliverable / experiment 관계 규약
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
| <!-- `del-20260407-midterm-report` | [문서 제목](deliverables/YYYY-MM-DD_name.md) | deliverable | done | `report` `milestone` --> |

---

## 문서 → 키워드 역매핑

### experiments/

| 문서 | 상태 | 키워드 |
|------|------|--------|
<!-- | [제목](experiments/YYYY-MM-DD_name.md) | 🟢 | `kw1` `kw2` | -->

### deliverables/

| 문서 | 상태 | 키워드 |
|------|------|--------|
<!-- | [제목](deliverables/YYYY-MM-DD_name.md) | 🟢 | `kw1` `kw2` | -->

### meetings/

| 문서 | 상태 | 키워드 |
|------|------|--------|
<!-- | [제목](meetings/YYYY-MM-DD_name.md) | 🟢 | `kw1` `kw2` | -->

### bugfix/
_(아직 없음)_

---

## relation registry

| relation | 의미 |
|----------|------|
| `depends_on` | 납품물/실험/회의 간 선행 필요 |
| `derived_from` | 회의나 실험 결과에서 파생 |
| `evidence_for` | 실험이 납품 주장 지원 |
| `blocked_by` | 승인/데이터/버그로 차단 |
| `related_to` | 주제 연결 |

---

## 타임라인

| 날짜 | 문서 | 요약 |
|------|------|------|
<!-- | YYYY-MM-DD | [문서 제목](path) | 한 줄 요약 | -->
