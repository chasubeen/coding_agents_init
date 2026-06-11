# Dev Skill Graph Wiki

개발 프리셋의 `skill_graph/`는 기능, 버그, 리팩터링, 결정 문서를 **wiki + typed graph** 방식으로 관리합니다.

## 문서 역할

- `features/` — 기능 구현 내역과 검증 결과
- `bugfix/` — 재현 조건, 근본 원인, 해결 검증
- `refactor/` — before/after 구조 변화
- `devops/` — 빌드/배포/운영 변경
- `decisions/` — ADR과 기술 판단

## 운영 규칙

- 새 문서는 frontmatter에 `id`, `note_type`, `status`, `relations`를 넣습니다.
- 결정이 기능 구현을 낳았으면 `derived_from` 또는 `depends_on`으로 연결합니다.
- 버그가 기능 진행을 막으면 `blocked_by`를 사용합니다.
- 구현이 끝나면 `index.md`, `log.md`를 갱신합니다.
