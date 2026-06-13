#!/bin/bash
#
# Coding Agents Init — 안전 업데이트 스크립트
#
# 이미 setup.sh로 초기화된 프로젝트에서, 템플릿 "기계 부품"(스킬·references·harness
# 스캐폴딩)만 최신으로 갱신한다. 사용자가 채운 콘텐츠(CLAUDE.md·feature_list·진행로그·
# 인수인계·소스코드)는 절대 건드리지 않는다.
#
# 사용법:
#   bash update.sh [preset] [target_dir]
#   (root 소유 프로젝트면 sudo bash update.sh ...)
#
# preset: base | dev | research | industry-academia  (기본 base)
# target_dir: 갱신할 프로젝트 디렉터리 (기본 .)
#
# 동작 원칙: ALLOWLIST. 아래 "REFRESH" 목록의 경로만 덮어쓴다. 그 외는 손대지 않는다.
#   - REFRESH(덮어씀, 순수 템플릿): .claude/skills, .claude/statusline.sh, .codex/config.toml,
#       harness/{references,contexts,templates,hooks,orchestrator,agents,tools}
#   - PRESERVE(절대 안 건드림): CLAUDE.md, 소스코드, docs, tasks/, skill_graph/,
#       harness/{feature_list.json,claude-progress.md,plan.md,handoff.md,HANDOFF.md,
#                init.sh,MEMORY_TEMPLATE.md,outputs/}
#   - SIDE-BY-SIDE(.new로 보존): AGENTS.md, .claude/settings.local.json
#         → 내용이 다르면 <파일>.new 로 써두고, 사용자가 직접 diff/merge
#   - 덮어쓰기 전 기존 REFRESH 경로를 harness/.update-backup-<ts>.tar.gz 로 백업
#

set -uo pipefail

PRESET="${1:-base}"
TARGET="${2:-.}"
REPO_URL="https://github.com/chasubeen/coding_agents_init.git"
TEMP_DIR="$(mktemp -d)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Coding Agents Init — Safe Update    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# preset 검증
if [[ ! "$PRESET" =~ ^(base|dev|research|industry-academia)$ ]]; then
    echo -e "${RED}Error: Unknown preset '$PRESET'${NC}"
    echo "Available: base, dev, research, industry-academia"
    exit 1
fi

# target 검증
if [ ! -d "$TARGET" ]; then
    echo -e "${RED}Error: target dir not found: $TARGET${NC}"; exit 1
fi
if [ ! -d "$TARGET/.claude" ] && [ ! -d "$TARGET/harness" ]; then
    echo -e "${YELLOW}경고: $TARGET 에 .claude/ 또는 harness/ 가 없습니다.${NC}"
    echo "      이 스크립트는 '업데이트'용입니다. 처음이라면 setup.sh를 쓰세요."
    read -r -p "그래도 계속할까요? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 1
fi

echo -e "${YELLOW}Preset:${NC} $PRESET"
echo -e "${YELLOW}Target:${NC} $(realpath "$TARGET")"
echo ""

# 템플릿 소스 위치 결정 (repo 안에서 실행 / 또는 download)
if [ -d "presets" ] && [ -d "base" ]; then
    SOURCE_DIR="."
else
    echo -e "${BLUE}Downloading latest templates...${NC}"
    git clone --quiet --depth 1 "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null
    SOURCE_DIR="$TEMP_DIR/repo"
fi

mkdir -p "$TARGET/harness" "$TARGET/.claude" "$TARGET/.codex"

# ─── 1. 백업 (덮어쓸 경로 중 존재하는 것만) ───────────────────
echo -e "${GREEN}[1/4]${NC} Backing up paths that will be refreshed..."
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET/harness/.update-backup-$TS.tar.gz"
BK_LIST=()
for p in .claude/skills .claude/statusline.sh .codex/config.toml \
         harness/references harness/contexts harness/templates \
         harness/hooks harness/orchestrator harness/agents harness/tools; do
    [ -e "$TARGET/$p" ] && BK_LIST+=("$p")
done
if [ "${#BK_LIST[@]}" -gt 0 ]; then
    tar -czf "$BACKUP" -C "$TARGET" "${BK_LIST[@]}" 2>/dev/null \
        && echo -e "  ${GREEN}Backup:${NC} harness/.update-backup-$TS.tar.gz (${#BK_LIST[@]} paths)" \
        || echo -e "  ${YELLOW}백업 실패(계속 진행)${NC}"
else
    echo -e "  (백업할 기존 경로 없음 — 신규 설치에 가까움)"
fi

# ─── 2. REFRESH (순수 템플릿 부품 덮어쓰기) ───────────────────
echo -e "${GREEN}[2/4]${NC} Refreshing template machinery (overwrite)..."

# .claude/skills (base + preset overlay) — 병합 덮어쓰기, 사용자 custom 스킬은 보존
mkdir -p "$TARGET/.claude/skills"
cp -r "$SOURCE_DIR/base/.claude/skills/"* "$TARGET/.claude/skills/" 2>/dev/null || true
if [ -d "$SOURCE_DIR/presets/$PRESET/.claude/skills" ]; then
    cp -r "$SOURCE_DIR/presets/$PRESET/.claude/skills/"* "$TARGET/.claude/skills/" 2>/dev/null || true
fi
NSKILL=$(find "$TARGET/.claude/skills" -name SKILL.md | wc -l | tr -d ' ')
echo -e "  ${GREEN}skills:${NC} $NSKILL 개"

# statusline
if [ -f "$SOURCE_DIR/base/.claude/statusline.sh" ]; then
    cp "$SOURCE_DIR/base/.claude/statusline.sh" "$TARGET/.claude/statusline.sh"
    chmod +x "$TARGET/.claude/statusline.sh" 2>/dev/null || true
fi

# .codex/config.toml
[ -f "$SOURCE_DIR/base/.codex/config.toml" ] && cp "$SOURCE_DIR/base/.codex/config.toml" "$TARGET/.codex/config.toml"

# harness 스캐폴딩 (references/contexts/templates/hooks/orchestrator/agents/tools)
for d in references contexts templates hooks orchestrator tools; do
    if [ -d "$SOURCE_DIR/base/$d" ]; then
        rm -rf "$TARGET/harness/$d"
        cp -r "$SOURCE_DIR/base/$d" "$TARGET/harness/$d"
    fi
done
# agents = base + preset overlay
if [ -d "$SOURCE_DIR/base/agents" ]; then
    rm -rf "$TARGET/harness/agents"
    cp -r "$SOURCE_DIR/base/agents" "$TARGET/harness/agents"
    [ -d "$SOURCE_DIR/presets/$PRESET/agents" ] && cp -r "$SOURCE_DIR/presets/$PRESET/agents/"* "$TARGET/harness/agents/" 2>/dev/null || true
fi
chmod +x "$TARGET/harness/hooks/"*.sh 2>/dev/null || true
# orchestrator 패키지 마커
touch "$TARGET/harness/__init__.py"
echo -e "  ${GREEN}harness/:${NC} references, contexts, templates, hooks, orchestrator, agents, tools 갱신"

# ─── 3. SIDE-BY-SIDE (.new) — 사용자 편집 가능 파일 ──────────
echo -e "${GREEN}[3/4]${NC} Writing .new for editable template files (no overwrite)..."
NEW_FILES=()
side_by_side() { # $1=source file, $2=target file
    local src="$1" dst="$2"
    [ -f "$src" ] || return 0
    if [ ! -f "$dst" ]; then
        cp "$src" "$dst"; echo -e "  ${GREEN}생성:${NC} ${dst#$TARGET/}"
    elif ! cmp -s "$src" "$dst"; then
        cp "$src" "$dst.new"; NEW_FILES+=("${dst#$TARGET/}.new"); echo -e "  ${YELLOW}.new:${NC} ${dst#$TARGET/}.new (직접 diff/merge)"
    else
        echo -e "  ${GREEN}동일:${NC} ${dst#$TARGET/} (변경 없음)"
    fi
}
side_by_side "$SOURCE_DIR/base/AGENTS.md" "$TARGET/AGENTS.md"
# settings: preset 전용본이 있으면 그것을, 없으면 base 를 단일 비교 대상으로
SETTINGS_SRC="$SOURCE_DIR/base/.claude/settings.local.json"
[ -f "$SOURCE_DIR/presets/$PRESET/.claude/settings.local.json" ] && SETTINGS_SRC="$SOURCE_DIR/presets/$PRESET/.claude/settings.local.json"
side_by_side "$SETTINGS_SRC" "$TARGET/.claude/settings.local.json"

# ─── 4. 요약 ──────────────────────────────────────────────
echo -e "${GREEN}[4/4]${NC} Done."
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN} Update complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}갱신됨(REFRESH):${NC} .claude/skills, .claude/statusline.sh, .codex/config.toml,"
echo -e "                  harness/{references,contexts,templates,hooks,orchestrator,agents,tools}"
echo -e "${BLUE}보존됨(PRESERVE):${NC} CLAUDE.md, 소스코드, docs/, tasks/, skill_graph/,"
echo -e "                  harness/{feature_list.json,claude-progress.md,plan.md,handoff.md,HANDOFF.md,init.sh,outputs}"
if [ "${#NEW_FILES[@]}" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}직접 머지할 .new 파일:${NC}"
    for f in "${NEW_FILES[@]}"; do echo -e "  - $f   (diff $f ${f%.new})"; done
fi
echo ""
echo -e "롤백이 필요하면: ${BLUE}tar -xzf harness/.update-backup-$TS.tar.gz -C .${NC}"
echo ""
