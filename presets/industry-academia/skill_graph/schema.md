# Industry-Academia Skill Graph Schema

산학 프리셋은 공통 schema를 따르되 아래 관계 해석을 우선합니다.

| note_type | 설명 |
|-----------|------|
| `experiment` | 실험 기록 |
| `deliverable` | 납품물 또는 보고서 |
| `meeting` | 회의록 |
| `analysis` | 검증된 패턴, 리스크, 회고 |

## 권장 relations

- `deliverable.depends_on -> experiment | meeting`
- `deliverable.evidence_for -> milestone-claim`
- `meeting.derived_from -> external-request`
- `experiment.related_to -> deliverable`
- `analysis.blocked_by -> approval | data`
