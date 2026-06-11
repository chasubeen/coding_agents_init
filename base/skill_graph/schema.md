# Skill Graph Schema

## Frontmatter 기본 형식

```yaml
---
id: note-unique-id
title: Human readable title
note_type: experiment | analysis | bugfix | idea | paper | feature | decision | deliverable | meeting
status: planned | in_progress | done | proposed | approved | rejected | archived
keywords:
  - keyword-a
sources:
  - path-or-url
relations:
  related_to:
    - other-note-id
  depends_on:
    - other-note-id
  derived_from:
    - other-note-id
  supersedes:
    - other-note-id
  evidence_for:
    - other-note-id
  blocked_by:
    - other-note-id
  tested_by:
    - other-note-id
  inspired_by:
    - other-note-id
last_verified: YYYY-MM-DD
confidence: low | medium | high
---
```

## Relation semantics

| relation | meaning | allowed use |
|----------|---------|-------------|
| `related_to` | topic-level connection | 언제든 사용 가능 |
| `depends_on` | 선행 작업/지식이 필요 | 후속 구현, 후속 실험 |
| `derived_from` | 다른 노트에서 직접 파생 | 분석, 요약, 리포트 |
| `supersedes` | 이전 노트를 대체 | 승격, 최신 결정 반영 |
| `evidence_for` | 주장/결론을 지지 | 결과, 로그, 측정값 |
| `blocked_by` | 해결 전 진행 불가 | 버그, 승인, 데이터 대기 |
| `tested_by` | 아이디어/가설이 어떤 검증으로 시험되는지 연결 | 연구 아이디어 → 실험 |
| `inspired_by` | 어떤 선행 자료/사건이 이 노트를 촉발했는지 연결 | 아이디어 → 논문, 납품물 → 회의 |

## Rules

- `id`는 저장소 내에서 유일해야 합니다.
- 관계는 가능한 한 **note id** 기준으로 기록합니다.
- 본문의 `## 관련 노트`는 읽기 편의를 위한 뷰이고, 정합성 판단은 frontmatter relation이 우선입니다.
- 프리셋은 relation의 **사용 규약**을 좁힐 수는 있지만, base schema에 없는 새 relation 이름을 임의로 만들지 않습니다.
- 새 relation 타입이 필요하면 먼저 이 파일을 갱신합니다.
