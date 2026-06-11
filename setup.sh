#!/bin/bash
#
# Coding Agents Init — 프로젝트 초기 설정 스크립트
# Claude Code(메인) + Codex(보조 교차검증) 협업 환경을 한 번에 세팅합니다.
#
# 사용법:
#   curl -sL https://raw.githubusercontent.com/chasubeen/coding_agents_init/main/setup.sh | bash -s -- [preset] [target_dir]
#
#   또는 clone 후:
#   bash setup.sh [preset] [target_dir]
#
# preset:
#   base              — 최소 범용 구조 (기본값)
#   dev               — 소프트웨어 개발 특화 (멀티에이전트 협업, 개발 중심 skill_graph)
#   research          — ML/DL 연구 프로젝트 특화
#   industry-academia — 산학과제 특화 (납품물/회의록 관리 포함)
#
# target_dir:
#   초기화할 대상 디렉토리 (기본값: 현재 디렉토리)
#

set -euo pipefail

PRESET="${1:-base}"
TARGET="${2:-.}"
REPO_URL="https://github.com/chasubeen/coding_agents_init.git"
TEMP_DIR=$(mktemp -d)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Coding Agents Init — Project Setup  ║${NC}"
echo -e "${BLUE}║  Claude Code(메인) + Codex(보조)     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# Validate preset
if [[ ! "$PRESET" =~ ^(base|dev|research|industry-academia)$ ]]; then
    echo -e "${RED}Error: Unknown preset '$PRESET'${NC}"
    echo "Available presets: base, dev, research, industry-academia"
    exit 1
fi

echo -e "${YELLOW}Preset:${NC}  $PRESET"
echo -e "${YELLOW}Target:${NC}  $(realpath "$TARGET")"
echo ""

# 템플릿 소스 위치 결정
# - 이미 clone한 repo 안(base/, presets/ 존재)에서 실행했으면 현재 디렉터리를 그대로 사용
# - curl | bash 처럼 단독 실행이면 임시 디렉터리로 repo를 내려받아 사용
if [ -d "presets" ] && [ -d "base" ]; then
    SOURCE_DIR="."
else
    echo -e "${BLUE}Downloading templates...${NC}"
    git clone --quiet --depth 1 "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null
    SOURCE_DIR="$TEMP_DIR/repo"
fi

# 대상 디렉터리 생성 (없으면)
mkdir -p "$TARGET"

# ─── Copy base files ───────────────────────────────────────

echo -e "${GREEN}[1/7]${NC} Copying base structure..."

# CLAUDE.md — preset 전용 버전이 있으면 그것을, 없으면 base 버전을 사용
if [ -f "$SOURCE_DIR/presets/$PRESET/CLAUDE.md" ]; then
    cp "$SOURCE_DIR/presets/$PRESET/CLAUDE.md" "$TARGET/CLAUDE.md"
else
    cp "$SOURCE_DIR/base/CLAUDE.md" "$TARGET/CLAUDE.md"
fi

# skill_graph/ — 지식 wiki 구조. preset 전용이 있으면 우선
if [ -d "$SOURCE_DIR/presets/$PRESET/skill_graph" ]; then
    cp -r "$SOURCE_DIR/presets/$PRESET/skill_graph" "$TARGET/skill_graph"
else
    cp -r "$SOURCE_DIR/base/skill_graph" "$TARGET/skill_graph"
fi

# .claude/ — slash command + 권한/hook 설정.
# base를 먼저 깔고 preset을 덮어쓴다(overlay). 같은 파일은 preset 값이 우선.
# (단, preset의 settings.local.json은 base 내용을 모두 포함하도록 작성되어 있음)
mkdir -p "$TARGET/.claude"
if [ -d "$SOURCE_DIR/base/.claude" ]; then
    cp -r "$SOURCE_DIR/base/.claude/"* "$TARGET/.claude/" 2>/dev/null || true
fi
if [ -d "$SOURCE_DIR/presets/$PRESET/.claude" ]; then
    cp -r "$SOURCE_DIR/presets/$PRESET/.claude/"* "$TARGET/.claude/" 2>/dev/null || true
fi
# statusLine 스크립트 실행권한 (있으면)
chmod +x "$TARGET/.claude/statusline.sh" 2>/dev/null || true

# hooks/ — 자동 알림/가드 스크립트. 복사 후 실행권한 부여
cp -r "$SOURCE_DIR/base/hooks" "$TARGET/hooks"
chmod +x "$TARGET/hooks/"*.sh 2>/dev/null || true

# orchestrator/ module (multi-agent coordination)
cp -r "$SOURCE_DIR/base/orchestrator" "$TARGET/orchestrator"

# AGENTS.md (Codex agent guidance)
cp "$SOURCE_DIR/base/AGENTS.md" "$TARGET/AGENTS.md"

# .codex/ directory (Codex CLI config reference: crosscheck/worker profiles)
if [ -d "$SOURCE_DIR/base/.codex" ]; then
    cp -r "$SOURCE_DIR/base/.codex" "$TARGET/.codex"
fi

# contexts/ directory (session mode files)
cp -r "$SOURCE_DIR/base/contexts" "$TARGET/contexts"

# templates/ directory (handoff, governance, decision-log, etc.)
cp -r "$SOURCE_DIR/base/templates" "$TARGET/templates"

if [ -d "$SOURCE_DIR/base/tools" ]; then
    cp -r "$SOURCE_DIR/base/tools" "$TARGET/tools"
fi

# agents/ directory (base first, then preset overlay)
cp -r "$SOURCE_DIR/base/agents" "$TARGET/agents"
if [ -d "$SOURCE_DIR/presets/$PRESET/agents" ]; then
    cp -r "$SOURCE_DIR/presets/$PRESET/agents/"* "$TARGET/agents/" 2>/dev/null || true
fi

# .gitignore (if template exists)
if [ -f "$SOURCE_DIR/presets/$PRESET/.gitignore_template" ]; then
    if [ -f "$TARGET/.gitignore" ]; then
        echo -e "${YELLOW}  .gitignore exists, appending template entries...${NC}"
        echo "" >> "$TARGET/.gitignore"
        echo "# === Added by coding_agents_init ===" >> "$TARGET/.gitignore"
        cat "$SOURCE_DIR/presets/$PRESET/.gitignore_template" >> "$TARGET/.gitignore"
    else
        cp "$SOURCE_DIR/presets/$PRESET/.gitignore_template" "$TARGET/.gitignore"
    fi
fi

# ─── MEMORY.md setup ──────────────────────────────────────

echo -e "${GREEN}[2/7]${NC} Preparing MEMORY.md template..."

# 프로젝트별 MEMORY.md 경로 계산.
# Claude Code는 프로젝트 절대경로의 '/'를 '-'로 치환해
# ~/.claude/projects/<dashed-path>/memory/ 아래에 메모리를 둔다.
# 예: /home/user/proj -> ~/.claude/projects/-home-user-proj/memory/
TARGET_ABS=$(realpath "$TARGET")
PROJ_PATH_HASH=$(echo "$TARGET_ABS" | sed 's|/|-|g')
MEMORY_DIR="$HOME/.claude/projects/$PROJ_PATH_HASH/memory"

if [ -f "$SOURCE_DIR/presets/$PRESET/MEMORY_TEMPLATE.md" ]; then
    MEMORY_TEMPLATE="$SOURCE_DIR/presets/$PRESET/MEMORY_TEMPLATE.md"
else
    MEMORY_TEMPLATE="$SOURCE_DIR/base/MEMORY_TEMPLATE.md"
fi

# Copy MEMORY_TEMPLATE.md into the project (for reference)
cp "$MEMORY_TEMPLATE" "$TARGET/MEMORY_TEMPLATE.md"

# Also initialize actual memory location if it doesn't exist
if [ ! -f "$MEMORY_DIR/MEMORY.md" ]; then
    mkdir -p "$MEMORY_DIR"
    cp "$MEMORY_TEMPLATE" "$MEMORY_DIR/MEMORY.md"
    echo -e "  ${GREEN}Created:${NC} $MEMORY_DIR/MEMORY.md"
else
    echo -e "  ${YELLOW}Exists:${NC}  $MEMORY_DIR/MEMORY.md (not overwritten)"
fi

# ─── Preset-specific extras ────────────────────────────────

echo -e "${GREEN}[3/7]${NC} Setting up tasks/ directory..."

# ─── tasks/ setup ─────────────────────────────────────────

mkdir -p "$TARGET/tasks"

# todo.md
if [ ! -f "$TARGET/tasks/todo.md" ]; then
    cat > "$TARGET/tasks/todo.md" << 'EOF'
# Tasks — Todo

<!-- 현재 세션의 작업 계획. 세션마다 새로 작성하거나 갱신. -->
<!-- 형식: - [ ] 할 일 / - [x] 완료 -->

## 현재 작업

-

## 계획

-

## 결과

-

## 관련 노트

-
EOF
    echo -e "  ${GREEN}Created:${NC} tasks/todo.md"
fi

# lessons.md
if [ ! -f "$TARGET/tasks/lessons.md" ]; then
    cat > "$TARGET/tasks/lessons.md" << 'EOF'
# Lessons Learned

<!-- 사용자의 수정·지적으로부터 추출한 교훈을 누적 기록. -->
<!-- 세션 시작 시 반드시 먼저 확인할 것. -->
<!-- 반복 검증된 패턴은 skill_graph/analysis/{주제}/_lessons.md 로 승격. -->

## 규칙 & 패턴

<!-- 형식:
### [날짜] 교훈 제목
발생 상황: ...
잘못한 것: ...
올바른 방법: ...
-->

---

*아직 기록된 교훈이 없습니다. 사용자의 첫 번째 수정/지적 후 채워집니다.*
EOF
    echo -e "  ${GREEN}Created:${NC} tasks/lessons.md"
fi

echo -e "${GREEN}[4/7]${NC} Applying preset-specific settings..."

case "$PRESET" in
    dev)
        echo -e "  ${GREEN}+${NC} Agent Coordination Protocol (multi-agent file locks)"
        echo -e "  ${GREEN}+${NC} Dev-oriented skill_graph (features/bugfix/refactor/devops/decisions)"
        echo -e "  ${GREEN}+${NC} Memory Management with topic files"
        echo -e "  ${GREEN}+${NC} .gitignore for .env, Prisma DB, .locks/"
        # Create .locks directory
        mkdir -p "$TARGET/.locks"
        touch "$TARGET/.locks/.gitkeep"
        ;;
    research)
        echo -e "  ${GREEN}+${NC} 6-stage experiment process template"
        echo -e "  ${GREEN}+${NC} _lessons.md knowledge graph structure"
        echo -e "  ${GREEN}+${NC} Config parameter tags ([TUNE]/[ARCH])"
        ;;
    industry-academia)
        echo -e "  ${GREEN}+${NC} Milestone/timeline tracking"
        echo -e "  ${GREEN}+${NC} Deliverables management (납품물)"
        echo -e "  ${GREEN}+${NC} Meeting notes template (회의록)"
        echo -e "  ${GREEN}+${NC} .gitignore for proprietary data"
        # Create data directories
        mkdir -p "$TARGET/data/public" "$TARGET/data/proprietary"
        echo "# Proprietary data — DO NOT COMMIT" > "$TARGET/data/proprietary/README.md"
        mkdir -p "$TARGET/demo" "$TARGET/reports"
        ;;
esac

# ─── Skills ───────────────────────────────────────────────

echo -e "${GREEN}[5/7]${NC} Setting up Cowork + Harness minimum pack..."

# Cowork file structure (plan.md, handoff.md, outputs/)
if [ ! -f "$TARGET/plan.md" ]; then
    cat > "$TARGET/plan.md" << 'EOF'
# Plan

<!-- 현재 작업 계획. 제약, 할 일, 바지 않을 입출력을 명시. -->
<!-- planner 에이전트가 작성하거나 사람이 직접 작성. -->

## 제약

-

## 할 일

- [ ]

## 성공 기준

-

## 바지 않을 것

-
EOF
    echo -e "  ${GREEN}Created:${NC} plan.md"
fi

if [ ! -f "$TARGET/handoff.md" ]; then
    cp "$SOURCE_DIR/base/templates/handoff.md" "$TARGET/handoff.md"
    echo -e "  ${GREEN}Created:${NC} handoff.md"
fi

# Harness Engineering 최소 필수 팩 (init.sh, claude-progress.md, feature_list.json)
# 참고: https://walkinglabs.github.io/learn-harness-engineering/ko/
if [ ! -f "$TARGET/init.sh" ]; then
    cp "$SOURCE_DIR/base/templates/init.sh" "$TARGET/init.sh"
    chmod +x "$TARGET/init.sh"
    echo -e "  ${GREEN}Created:${NC} init.sh (INSTALL/VERIFY/START 변수를 편집하세요)"
fi
if [ ! -f "$TARGET/claude-progress.md" ]; then
    cp "$SOURCE_DIR/base/templates/claude-progress.md" "$TARGET/claude-progress.md"
    echo -e "  ${GREEN}Created:${NC} claude-progress.md"
fi
if [ ! -f "$TARGET/feature_list.json" ]; then
    cp "$SOURCE_DIR/base/templates/feature_list.json" "$TARGET/feature_list.json"
    echo -e "  ${GREEN}Created:${NC} feature_list.json"
fi

mkdir -p "$TARGET/outputs"
touch "$TARGET/outputs/.gitkeep"

echo -e "${GREEN}[6/7]${NC} Installing Claude Code skills & agents..."

if [ -d "$TARGET/.claude/skills" ]; then
    SKILL_COUNT=$(find "$TARGET/.claude/skills" -name 'SKILL.md' | wc -l)
    echo -e "  ${GREEN}Installed ${SKILL_COUNT} slash commands:${NC}"
    for skill_dir in "$TARGET/.claude/skills"/*/; do
        skill_name=$(basename "$skill_dir")
        echo -e "    ${YELLOW}/${skill_name}${NC}"
    done
else
    echo -e "  ${YELLOW}No skills found for this preset${NC}"
fi

if [ -d "$TARGET/agents" ]; then
    AGENT_COUNT=$(find "$TARGET/agents" -name '*.md' | wc -l)
    echo -e "  ${GREEN}Installed ${AGENT_COUNT} agent definitions:${NC}"
    for agent_file in "$TARGET/agents"/*.md; do
        agent_name=$(basename "$agent_file" .md)
        echo -e "    ${YELLOW}@${agent_name}${NC}"
    done
fi

echo -e "  ${GREEN}Installed 5 context modes:${NC}"
echo -e "    ${YELLOW}dev${NC}, ${YELLOW}research${NC}, ${YELLOW}review${NC}, ${YELLOW}cowork${NC}, ${YELLOW}autoresearch${NC}"

HOOK_COUNT=$(find "$TARGET/hooks" -name '*.sh' 2>/dev/null | wc -l)
echo -e "  ${GREEN}Installed ${HOOK_COUNT} hooks:${NC}"
for hook_file in "$TARGET/hooks"/*.sh; do
    hook_name=$(basename "$hook_file" .sh)
    echo -e "    ${YELLOW}${hook_name}${NC}"
done

# ─── Summary ──────────────────────────────────────────────

echo -e "${GREEN}[7/7]${NC} Done!"
echo ""
echo -e "${BLUE}Created structure:${NC}"
echo ""

# Show tree (basic version)
cd "$TARGET"
if command -v tree &> /dev/null; then
    tree -a -I '.git|__pycache__' --dirsfirst -L 3
else
    find . -not -path './.git/*' -not -name '.git' | head -40 | sort
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN} Setup complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
# Codex CLI 설치 여부 안내 (보조 교차검증 에이전트)
if command -v codex &> /dev/null; then
    echo -e "  ${GREEN}Codex CLI 감지됨:${NC} $(codex --version 2>/dev/null || echo installed) — /cross-check 사용 가능"
else
    echo -e "  ${YELLOW}Codex CLI 미설치:${NC} /cross-check·/orchestrate를 쓰려면 Codex CLI를 설치하세요 (npm i -g @openai/codex 등)"
fi
echo ""

echo -e "Next steps:"
echo -e "  1. ${YELLOW}Edit init.sh${NC} — INSTALL/VERIFY/START 명령 채우고 ${YELLOW}bash init.sh${NC}로 기준선 확인"
echo -e "  2. ${YELLOW}Edit CLAUDE.md${NC} — Fill in project-specific sections"
echo -e "  3. ${YELLOW}Edit MEMORY.md${NC} — at $MEMORY_DIR/MEMORY.md"
echo -e "  4. ${YELLOW}Start Claude Code${NC} in this directory"
echo -e "  5. ${YELLOW}Try slash commands${NC} — /todo, /verify, /cross-check, /learn, /orchestrate"
echo -e "  6. ${YELLOW}Codex 교차검증${NC} — 비자명한 변경 후 Claude가 /cross-check 제안 (승인 시 실행)"
echo -e "  7. ${YELLOW}진행 로그${NC} — 매 세션 claude-progress.md / feature_list.json 갱신"
echo -e "  8. ${YELLOW}Context modes${NC} — 'research 모드로 진행' 또는 contexts/*.md 참조"
echo ""
echo -e "  MEMORY_TEMPLATE.md is included in the project for reference."
echo -e "  The actual persistent memory is at:"
echo -e "  ${BLUE}$MEMORY_DIR/MEMORY.md${NC}"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"
