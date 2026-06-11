# Skill Graph Index

> `skill_graph/`의 탐색 진입점.
> 본문은 wiki로 읽고, 관계 의미는 `schema.md` 기준 typed metadata로 해석합니다.
> 새 문서 추가 시 이 파일과 `log.md`를 함께 갱신합니다.

---

## 운영 레이어

- `README.md` — raw/wiki/schema/log 운영 방식
- `schema.md` — frontmatter 필드와 relation 타입 정의
- `log.md` — ingest / query / lint / promote 이력

---

## 관계 그래프

```
<!-- ASCII 다이어그램으로 키워드 간 관계를 시각화 -->
<!-- 예시:
  ┌──────────┐      ┌────────────┐
  │ keyword1 │◀────▶│  keyword2  │
  └─────┬────┘      └─────┬──────┘
        │                 │
   ┌────▼────┐     ┌─────▼──────┐
   │ keyword3│     │  keyword4  │
   └─────────┘     └────────────┘
-->
```

---

## 문서 카탈로그

| 문서 ID | 문서 | note_type | 상태 | 핵심 키워드 |
|---------|------|-----------|------|-------------|
| <!-- `exp-20260407-baseline` | [문서 제목](experiments/YYYY-MM-DD_name.md) | experiment | planned | `kw1` `kw2` --> |

---

## relation registry

| relation | 의미 | 예시 |
|----------|------|------|
| `related_to` | 주제적으로 연결됨 | 아이디어 ↔ 버그 분석 |
| `depends_on` | 선행 지식/작업 필요 | 후속 실험 → baseline |
| `supersedes` | 대체/승격함 | 검증 패턴 → 임시 교훈 |
| `derived_from` | 원천 문서/실험에서 파생 | 분석 → 실험 |
| `evidence_for` | 주장을 지지함 | 결과 → 분석 결론 |
| `blocked_by` | 해결 전 진행 불가 | 기능 → 버그픽스 |
| `tested_by` | 가설/아이디어가 실험으로 검증됨 | 아이디어 → 실험 |
| `inspired_by` | 선행 문서/사건에서 착안함 | 아이디어 → 논문 |

---

## 문서 → 키워드 역매핑

### experiments/

| 문서 | 상태 | 키워드 |
|------|------|--------|
<!-- | [제목](experiments/YYYY-MM-DD_name.md) | 🟢 | `kw1` `kw2` | -->

### bugfix/
_(아직 없음)_

---

## 문서 간 연결 (관련 노트)

```
<!-- 문서 간 선행/후속 관계를 흐름도로 표현 -->
<!-- 예시:
category/YYYY-MM-DD_first.md
        │
        ▼ (선행)
category/YYYY-MM-DD_second.md
-->
```

---

## 타임라인

| 날짜 | 문서 | 요약 |
|------|------|------|
<!-- | YYYY-MM-DD | [제목](path) | 한 줄 요약 | -->

---

## lint 체크리스트

- orphan note가 없는가?
- `schema.md`에 없는 relation을 사용하지 않았는가?
- `tasks/lessons.md`에서 승격된 패턴이 `analysis/`에 반영되었는가?
- 최신 변경이 `log.md`에 기록되었는가?
