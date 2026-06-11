---
name: link-notes
description: 키워드 기반으로 skill_graph/ 내 노트를 자동 연결합니다
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
  - Bash
---

# /link-notes

**사용법**: `/link-notes [target-file]`

- 인자 없음: `skill_graph/` 전체 스캔 후 모든 노트 간 연결
- 파일 지정: 해당 파일만 대상으로 연결

## 키워드 추출 (우선순위)

1. `> **keywords**:` 라인의 명시적 키워드 (최우선, 쉼표 구분)
2. H1, H2 헤딩에서 추출 (stopword 필터: 의, 및, 이, 를, 에, a, the, is, and, or, for, to, in, of, with)
3. 파일 경로 토큰 (카테고리명 + 파일명 하이픈 분리)

## 매칭 알고리즘

```
keywords_A = explicit(A) ∪ headings(A) ∪ path_tokens(A)
keywords_B = explicit(B) ∪ headings(B) ∪ path_tokens(B)
overlap = keywords_A ∩ keywords_B
if |overlap| >= 2 → 관련 노트로 판정
```

## 링크 형식

```markdown
## 관련 노트
- [features] ../features/2026-03-01_pty-manager.md — PTY 프로세스 관리
- 선행: (기존 수동 링크 보존)
```

## 동작 절차

1. 기본 실행 경로:

   ```bash
   python tools/skill_graph_tool.py link [target-file]
   ```

2. 유틸리티가 수행하는 일:
   - `skill_graph/` 내 `.md` 파일 수집 (`_TEMPLATE.md`, `README.md`, `schema.md`, `index.md`, `log.md` 제외)
   - `skill_graph/schema.md`를 읽어 허용된 relation 타입 확인
   - 키워드 / heading / 경로 토큰 기반 겹침 계산
   - 겹침 >= 2인 쌍에 대해 양방향 `relations.related_to` 보강
   - `## 관련 노트` 섹션의 자동 링크 라인 갱신

## lint

연결 후 정합성 검사는 아래 명령으로 수행합니다.

```bash
python tools/skill_graph_tool.py lint
python tools/skill_graph_tool.py lint skill_graph/deliverables/YYYY-MM-DD_name.md
```

## sync

수동 편집으로 인한 drift를 복구하려면 아래 명령을 사용합니다.

```bash
python tools/skill_graph_tool.py sync
python tools/skill_graph_tool.py sync skill_graph/deliverables/YYYY-MM-DD_name.md
```

## 규칙

- `_TEMPLATE.md`는 스캔에서 제외
- 기존 수동 링크(`선행:`, `후속:` 등)는 절대 삭제하지 않음
- 양방향 필수: A→B 추가 시 B→A도 추가
- 이미 존재하는 링크는 중복 추가하지 않음
- 링크 형식: `- [카테고리] 상대경로 — 노트 제목` (H1에서 추출)
