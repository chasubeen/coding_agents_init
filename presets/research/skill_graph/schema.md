# Research Skill Graph Schema

연구 프리셋은 공통 schema를 따르되 아래 관계 해석을 우선합니다.

| note_type | 설명 |
|-----------|------|
| `idea` | 연구 아이디어 |
| `paper` | 선행연구/베이스라인 요약 |
| `experiment` | 실행된 검증 |
| `analysis` | 검증된 패턴, failure analysis |

## 권장 relations

- `idea.related_to -> paper`
- `idea.tested_by -> experiment`
- `experiment.evidence_for -> analysis | idea`
- `analysis.derived_from -> experiment`
- `idea.inspired_by -> paper | analysis`

## 규칙

- 연구 프리셋은 base schema의 relation vocabulary만 사용합니다.
- `inspires`처럼 방향이 모호한 동사는 추가하지 않고, note 기준으로 읽히는 `inspired_by`를 사용합니다.
