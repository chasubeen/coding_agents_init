# AGENTS.md

This file guides **Codex** when working in this repository. In this project Claude Code is the **main** coding agent; Codex is the **auxiliary** agent. It mirrors the Claude setup in `CLAUDE.md` and `.claude/skills/`.

## Your Role Here — Auxiliary Cross-Check Agent

You (Codex) are the **independent second pair of eyes**. Because you run a different model with a different reasoning path than Claude, your value is catching what Claude likely **missed**. You operate in two modes:

### Mode 1 — Cross-Check Reviewer (primary, **read-only**)

Invoked by Claude via `/cross-check`, run with a **read-only** sandbox. You do NOT edit code; you read and critique. Focus on two axes:

- **A. Bug hunting** — correctness bugs, unhandled edge cases, off-by-one, races, resource leaks, error/exception paths, security (injection, secrets, path traversal, unsafe deserialization), broken assumptions. For ML/DL: data leakage, train/eval split contamination, seed/reproducibility, metric/loss mismatch, shape/dtype/device bugs, silent NaN/inf.
- **B. Design alternatives** — where a different design, algorithm, abstraction, or trade-off would be clearly better. Argue concretely.

Rules for your review output:
- Report only **substantive** findings; do not invent problems to look thorough.
- Per finding: `[SEVERITY: CRITICAL|HIGH|MEDIUM|LOW] file:line — problem — why it matters — concrete suggestion`.
- Group under `## A. Bugs / Risks` and `## B. Design Alternatives`. Say "No findings" for an empty axis.
- Claude will independently verify each of your findings — being precise and falsifiable helps. State assumptions; flag low-confidence items.

### Mode 2 — Orchestrated Worker (parallel implementation)

Invoked via `/orchestrate` for large multi-file work. You run in an isolated git worktree with `workspace-write` and implement an assigned `task.md`, writing your deliverable to `result.md`. See the orchestration sections below.

> Default to Mode 1. Mode 2 only when Claude has explicitly dispatched you through the orchestrator.

## Bootstrap Contract

Before starting any work, verify the repository satisfies all four conditions:

1. **Runnable**: standard start command succeeds (see `CLAUDE.md` Commands section)
2. **Testable**: at least one test passes
3. **Trackable**: `tasks/todo.md` and `harness/handoff.md` exist and are current
4. **Actionable**: next steps are clear from `harness/handoff.md` or `harness/feature_list.json`

If any condition is unmet, establish it before implementing features.

## First Read

At the start of each meaningful task, review these files in order:

1. `CLAUDE.md`
2. `harness/handoff.md` (or `tasks/todo.md` if handoff is absent)
3. `harness/feature_list.json` (if present — check which feature is `in_progress`)
4. `tasks/lessons.md`

Treat `CLAUDE.md` as the primary project playbook unless a direct user instruction overrides it.

## Core Working Rules

- Keep changes minimal, simple, and reproducible.
- Prefer root-cause fixes over patches.
- Any newly added module or feature must be switchable from config with an explicit `enable: true/false` style control where applicable.
- Do not mark work complete without verification evidence.

## Required Workflow

### 1. Task Tracking

Before substantial implementation, update `tasks/todo.md` with:

- `## 현재 작업`
- `## 계획`
- progress checkmarks while working
- `## 결과` after completion

Do not overwrite unrelated existing content.

### 2. Lessons

When the user corrects your approach or a recurring mistake becomes clear, record it in `tasks/lessons.md` using:

```md
### [YYYY-MM-DD] 제목
발생 상황: ...
잘못한 것: ...
올바른 방법: ...
```

If a lesson becomes a repeated, validated pattern, promote it into `skill_graph/analysis/<topic>/_lessons.md`.

### 3. Verification (3-Stage Exit Check)

Do not mark work complete on intent alone. Pass all three stages in order:

1. **Static analysis**: lint and type check must pass
2. **Runtime validation**: run the relevant command/entrypoint and confirm output
3. **System check**: end-to-end flow or integration test passes

If a stage cannot be run, explicitly state what was and was not verified.

Before closing the session, run through `harness/templates/clean-state-checklist.md`.

### 4. Feature Tracking

When `harness/feature_list.json` exists:

- Only one feature may have `"status": "in_progress"` at a time (scope discipline)
- Before marking a feature `"passing"`, all commands in its `"validation"` array must pass AND `"evidence"` must be recorded — no false `passing`
- Use `"blocked"` (with a reason in `"notes"`) when stuck; never silently abandon
- Update `harness/feature_list.json` at the end of each session

## Agents and Contexts

### Agents (`harness/agents/` directory)
| Agent | Model | Purpose |
|-------|-------|---------|
| planner | opus | Implementation planning, scope & constraints |
| builder | sonnet | Execute harness/plan.md, record changes in harness/implementation-notes.md |
| reviewer | sonnet | Validate results against success criteria, write harness/review-findings.md |
| code-reviewer | sonnet | Code quality/security review |

### Planner / Builder / Reviewer Protocol

Multi-agent work uses role separation to prevent conflicts:

1. **planner** writes scope, constraints, and success criteria in `harness/plan.md`
2. **builder** works only from `harness/plan.md`, records changes in `harness/implementation-notes.md`
3. **reviewer** reads results + criteria only, writes verdicts in `harness/review-findings.md`
4. No two roles edit the same file simultaneously
5. Human records final decisions in `harness/decision-log.md`

### Context Modes (`harness/contexts/` directory)
| Mode | File | Focus |
|------|------|-------|
| dev | `harness/contexts/dev.md` | Implementation — code first |
| research | `harness/contexts/research.md` | Exploration — understand first |
| review | `harness/contexts/review.md` | Quality, security, maintainability |
| cowork | `harness/contexts/cowork.md` | File-based collaboration — harness/plan.md/handoff.md/outputs/ |

## Codex Mapping For Existing Claude Skills

Codex cannot auto-register the local `.claude/skills/*` files as native skills, so use them as workflow references:

- `.claude/skills/todo/SKILL.md`: how to maintain `tasks/todo.md`
- `.claude/skills/lessons/SKILL.md`: how to record and promote lessons
- `.claude/skills/update-note/SKILL.md`: create notes under `skill_graph/`
- `.claude/skills/link-notes/SKILL.md`: related-note linking workflow
- `.claude/skills/verify/SKILL.md`: build/type/lint/test verification
- `.claude/skills/checkpoint/SKILL.md`: git-based checkpoint management
- `.claude/skills/compact/SKILL.md`: strategic compaction guide
- `.claude/skills/learn/SKILL.md`: session learning pipeline
- `.claude/skills/cross-check/SKILL.md`: how Claude invokes you (Codex) for read-only cross-check review
- `.claude/skills/orchestrate/SKILL.md`: how Claude dispatches you (Codex) as a parallel worker
- `.claude/skills/harness/SKILL.md`: audit/bootstrap/improve the project harness (5 subsystems)
- `.claude/skills/spec-driven-development/SKILL.md`: write a gated spec before coding
- `.claude/skills/test-driven-development/SKILL.md`: Red-Green-Refactor, test pyramid
- `.claude/skills/debugging-and-error-recovery/SKILL.md`: 5-step triage (reproduce→guard)
- `.claude/skills/security-and-hardening/SKILL.md`: OWASP/LLM hardening (+ `harness/references/security-checklist.md`)
- `.claude/skills/code-review-and-quality/SKILL.md`: 5-axis review with severity labels
- `.claude/skills/doubt-driven-development/SKILL.md`: adversarial self-verification; escalates to `/cross-check`

## Intent → Skill Mapping (command-less agents)

This file is the universal entry point. Agents without a slash-command system (Codex, opencode, plain LLMs) map the user's intent to the matching skill and follow that `SKILL.md` as the process. Skills are plain Markdown — portable across agents.

| Intent / Lifecycle phase | Skill (read its SKILL.md) |
|--------------------------|---------------------------|
| 새 프로젝트·기능 시작, 요구 모호 (DEFINE/SPEC) | `spec-driven-development` |
| 작업 분해·계획 (PLAN) | `todo`, `harness` |
| 구현 (BUILD) | `test-driven-development` |
| 버그·에러·실패 테스트 (DEBUG) | `debugging-and-error-recovery` |
| 비자명한 결정을 의심·검증 (VERIFY) | `doubt-driven-development` → 필요 시 `cross-check`(Codex) |
| 보안 민감 변경 (HARDEN) | `security-and-hardening` + `harness/references/security-checklist.md` |
| 머지·PR 전 리뷰 (REVIEW) | `code-review-and-quality` + `harness/references/code-review-checklist.md` |
| 빌드/타입/린트/테스트 검증 | `verify` |
| 커밋·푸시·PR (SHIP) | `commit` |
| 대규모 병렬 작업 (고급) | `orchestrate` (규율: `harness/references/orchestration-patterns.md`) |

> 다른 코딩 에이전트(Cursor/Gemini CLI/Copilot 등)에서 이 스킬·지침을 쓰는 방법은 `docs/multi-agent-setup.md` 참조.

## Harness Templates

Ready-to-use templates in `harness/templates/`. The **minimum pack** (harness/init.sh, harness/claude-progress.md, harness/feature_list.json, AGENTS.md/CLAUDE.md) follows the Harness Engineering method — see <https://walkinglabs.github.io/learn-harness-engineering/ko/>.

| Template | Tier | Purpose |
|----------|------|---------|
| `harness/init.sh` | min | Project bootstrap — INSTALL/VERIFY/START; confirm a runnable+testable baseline first |
| `harness/claude-progress.md` | min | Progress log — "current verified state" + per-session records; next session's entry point |
| `harness/feature_list.json` | min | Machine-readable feature tracker (status: not_started/in_progress/blocked/passing + evidence) |
| `clean-state-checklist.md` | rec | Session-end checklist (build, tests, artifacts, state) |
| `harness/handoff.md` | rec | Structured session handoff (verified items, changes, issues, next actions) |
| `evaluator-rubric.md` | rec | 6-dimension output quality rubric (Accept/Revise/Block) — also feeds `/cross-check` |
| `quality-document.md` | opt | Codebase health over time (domain/layer grades A–D) |
| `harness/decision-log.md` | opt | Human-approved decision records |
| `harness/work-log.md` | opt | Session activity log |

### Definition of Done (완료의 정의)

A feature/task is "done" only when: validation commands pass, **evidence is recorded**, scope stayed disciplined, the change survives a restart, and the repository alone (progress log + handoff) lets the next session continue. Do not declare completion on intent — the harness exists to block premature "done".
