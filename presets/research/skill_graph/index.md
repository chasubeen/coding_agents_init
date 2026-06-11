# Skill Graph Index

> 연구 위키의 탐색 진입점.
> 문서 본문은 wiki, 관계 의미는 `schema.md`의 typed relation으로 해석합니다.
> 새 문서 추가 시 이 파일과 `log.md`를 함께 갱신합니다.

---

## 운영 레이어

- `README.md` — 연구 위키 운영 방식
- `schema.md` — idea / paper / experiment 관계 규약
- `log.md` — append-only 연구 이력

---

## 관계 그래프

```
<!-- typed relation을 기준으로 ASCII 다이어그램을 유지 -->
```

---

## 문서 카탈로그

| 문서 ID | 문서 | note_type | 상태 | 핵심 키워드 |
|---------|------|-----------|------|-------------|
| <!-- `idea-20260407-memory-routing` | [문서 제목](ideas/YYYY-MM-DD_name.md) | idea | screened | `memory` `routing` --> |

---

## 문서 → 키워드 역매핑

### experiments/

| 문서 | 상태 | 키워드 |
|------|------|--------|
<!-- | [제목](experiments/YYYY-MM-DD_name.md) | 🟢 | `kw1` `kw2` | -->

### papers/
| 문서 | 구분 | 키워드 |
|------|------|--------|
<!-- | [논문명](papers/YYYY-MM-DD_name.md) | competitor | `kw1` `kw2` | -->

### ideas/
| 문서 | 상태 | 키워드 |
|------|------|--------|
<!-- | [아이디어명](ideas/YYYY-MM-DD_name.md) | screened | `kw1` `kw2` | -->

### bugfix/
_(아직 없음)_

---

## relation registry

| relation | 의미 |
|----------|------|
| `inspired_by` | 아이디어가 paper/analysis에서 착안됨 |
| `tested_by` | idea가 실험으로 검증됨 |
| `evidence_for` | 실험 결과가 분석/claim를 지지 |
| `supersedes` | 더 강한 실험 또는 분석이 이전 결론 대체 |
| `related_to` | 주제 연결 |

---

## 타임라인

| 날짜 | 문서 | 요약 |
|------|------|------|
<!-- | YYYY-MM-DD | [문서 제목](path) | 한 줄 요약 | -->
