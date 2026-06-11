# Dev Skill Graph Schema

개발 프리셋은 공통 schema를 따르되 아래 해석을 우선합니다.

| note_type | 설명 |
|-----------|------|
| `feature` | 신규 기능 구현 |
| `bugfix` | 버그 수정 기록 |
| `refactor` | 구조 개선 |
| `devops` | CI/CD, infra, build 변경 |
| `decision` | ADR, 기술 선택 |

## 권장 relations

- `feature.depends_on -> decision`
- `feature.blocked_by -> bugfix`
- `bugfix.derived_from -> feature`
- `refactor.supersedes -> feature | decision`
- `decision.related_to -> feature | refactor`
