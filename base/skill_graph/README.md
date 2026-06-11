# Skill Graph Wiki

`skill_graph/`는 단순 메모 폴더가 아니라 **LLM이 유지하는 persistent wiki**입니다.

## 운영 모델

1. **Raw sources**
   - 코드 변경, 실험 로그, 사용자 피드백, 회의록, 외부 문서
   - 원문은 source of truth로 취급하고 직접 수정하지 않습니다.
2. **Wiki pages**
   - 사람이 읽는 markdown 본문입니다.
   - 각 노트는 배경, 판단, 결과, 관련 노트를 설명합니다.
3. **Typed graph schema**
   - 노트 상단 frontmatter에서 관계를 구조화합니다.
   - 의미는 `schema.md`를 기준으로 해석합니다.

## 핵심 파일

- `index.md` — 전체 문서 카탈로그와 탐색 진입점
- `schema.md` — frontmatter 필드와 relation 타입 정의
- `log.md` — ingest / query / lint / promote 이력을 남기는 append-only 로그

## 운영 루프

- **ingest**: 새 사건/실험/결정을 노트로 만들고 관련 페이지를 갱신
- **query**: 기존 wiki를 읽어 답을 만들고, 가치가 있으면 새 노트로 write-back
- **lint**: orphan note, stale claim, broken relation, missing promotion을 점검

## 작성 원칙

- 본문은 사람 친화적으로 씁니다.
- 관계 의미는 텍스트 링크만으로 두지 말고 frontmatter에 typed relation으로 남깁니다.
- 새 노트를 만들면 `index.md`와 `log.md`를 함께 갱신합니다.
- 반복 검증된 교훈은 `analysis/.../_lessons.md`로 승격합니다.
- 프리셋별 schema는 공통 relation vocabulary를 재사용하고, 의미를 더 구체화하는 방식으로만 확장합니다.
