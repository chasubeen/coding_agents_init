---
name: update-note
description: skill_graph/ 템플릿 기반으로 새 노트를 생성합니다
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash
---

# /update-note

**사용법**: `/update-note <category> <short-title>`

사용 가능한 카테고리와 템플릿:

```
!find skill_graph -name '_TEMPLATE.md' -o -name '.gitkeep' | grep -v .gitkeep | sort!
```

## 동작

1. 기본 실행 경로:

   ```bash
   python tools/skill_graph_tool.py create <category> "<short-title>" --link
   ```

2. 유틸리티가 수행하는 일:
   - 해당 카테고리의 `_TEMPLATE.md`와 `skill_graph/schema.md` 읽기
   - `skill_graph/<category>/YYYY-MM-DD_<short-title>.md` 생성
   - frontmatter의 `id`, `title`, `note_type`, `status`, `keywords`, `relations`, `last_verified` 채우기
   - `skill_graph/index.md` 문서 카탈로그 갱신
   - `skill_graph/log.md`에 ingest 로그 추가
   - `--link`가 있으면 새 노트 기준으로 related link 보강

## sync

노트를 수동 수정한 뒤 카탈로그와 링크를 다시 맞추려면 아래 명령을 사용합니다.

```bash
python tools/skill_graph_tool.py sync
python tools/skill_graph_tool.py sync skill_graph/features/YYYY-MM-DD_name.md
```

## 규칙

- 파일명에 공백 대신 하이픈(`-`) 사용
- 템플릿의 플레이스홀더(`[...]`, `YYYY-MM-DD`)를 실제 값으로 치환
- 새 노트는 frontmatter를 유지하고 `relations` 키를 비워 두더라도 남겨둘 것
- `--link` 사용 시 `## 관련 노트`와 `relations.related_to`를 함께 갱신
- 이미 같은 이름의 파일이 있으면 경고 후 사용자에게 확인
- 본문 링크만 추가하지 말고 대응되는 frontmatter relation도 함께 갱신
