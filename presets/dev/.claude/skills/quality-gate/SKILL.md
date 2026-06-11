---
name: quality-gate
description: 포맷, 린트, 타입 체크 통합 품질 게이트 — 수동 실행 또는 PR 전 검증
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# /quality-gate

**사용법**: `/quality-gate [path|.] [--fix] [--strict]`

## 인자

- `[path|.]` — 대상 경로 (기본: 현재 디렉토리)
- `--fix` — 자동 포맷/수정 허용
- `--strict` — 경고도 실패로 처리

## 파이프라인

### 1. 언어/도구 감지
대상 경로에서 프로젝트 유형 감지:
- `package.json` → Node.js/TypeScript
- `pyproject.toml` / `setup.py` → Python
- `go.mod` → Go
- `Cargo.toml` → Rust

### 2. 포맷터 검사
| 도구 | 감지 조건 | 실행 |
|------|----------|------|
| Biome | `biome.json` 존재 | `npx biome check [--apply]` |
| Prettier | `.prettierrc` 존재 | `npx prettier --check [--write]` |
| Black | Python 프로젝트 | `black --check [--diff]` |
| gofmt | Go 프로젝트 | `gofmt -l` |

### 3. 린트/타입 검사
| 도구 | 감지 조건 | 실행 |
|------|----------|------|
| ESLint | `.eslintrc*` 또는 `eslint.config*` | `npx eslint [path]` |
| TypeScript | `tsconfig.json` 존재 | `npx tsc --noEmit` |
| Ruff/Flake8 | Python 프로젝트 | `ruff check` / `flake8` |
| mypy | Python 프로젝트 | `mypy [path]` |

### 4. 결과 보고
```
QUALITY GATE: [PASS/FAIL]
=========================
Format:  [OK/X issues]  (Biome/Prettier/Black)
Lint:    [OK/X issues]  (ESLint/Ruff)
Types:   [OK/X errors]  (tsc/mypy)

--fix 사용 시:
  Auto-fixed: X files
  Remaining: Y issues (수동 수정 필요)
```

## 규칙

- `--fix` 없이는 검사만 하고 수정하지 않음
- `--strict` 모드에서는 경고(warning)도 게이트 실패로 처리
- CLAUDE.md의 Commands 섹션에 정의된 명령이 있으면 우선 사용
- 감지되지 않는 도구는 건너뜀 (에러 아님)
- `/verify`와의 차이: quality-gate는 코드 품질에 집중, verify는 빌드+테스트 포함
