# Industry-Academia Skill Graph Wiki

산학 프리셋의 `skill_graph/`는 실험, 납품물, 회의록을 **공유 위키 + typed graph**로 관리합니다.

## 문서 역할

- `experiments/` — 검증 결과와 재현 정보
- `deliverables/` — 마일스톤별 납품물 추적
- `meetings/` — 의사결정, 요구사항, 액션 아이템
- `analysis/` — 반복 검증된 패턴과 리스크

## 운영 규칙

- 회의에서 결정된 액션은 `derived_from`으로 납품물/실험에 연결합니다.
- 납품물에 포함된 결과는 `evidence_for`로 실험과 연결합니다.
- 일정이나 승인 이슈는 `blocked_by`로 명시합니다.
- 새 문서 작성 후 `index.md`와 `log.md`를 갱신합니다.
