#!/bin/bash
#
# init.sh — 프로젝트 부트스트랩 (Harness Engineering 최소 필수 팩)
# 참고: https://walkinglabs.github.io/learn-harness-engineering/ko/
#
# "초기화는 별도의 단계여야 한다." 매 세션 시작 시 또는 새 환경에서 이 스크립트를 돌려
# 저장소가 (1) 실행 가능 (2) 검증 가능 한 기준선(baseline)에 있는지 먼저 확인한다.
# 검증이 실패하면 다른 작업을 하기 전에 기준선부터 고친다.
#
# ─── 프로젝트에 맞게 아래 3개 변수를 편집하세요 ───
INSTALL_CMD="echo '(편집) 예: uv sync / pip install -r requirements.txt / npm install'"
VERIFY_CMD="echo '(편집) 예: pytest -q / npm test / make check'"
START_CMD="echo '(편집) 예: python main.py / npm run dev'"
# ──────────────────────────────────────────────────

set -uo pipefail

echo "════════════════════════════════════════"
echo " Project Bootstrap (init.sh)"
echo "════════════════════════════════════════"

# 1. 위치 확인
echo "[1/3] Repository root: $(pwd)"

# 2. 의존성 설치
echo "[2/3] Installing dependencies..."
echo "  \$ $INSTALL_CMD"
eval "$INSTALL_CMD"

# 3. 검증 (기준선 확인)
echo "[3/3] Verifying baseline..."
echo "  \$ $VERIFY_CMD"
if eval "$VERIFY_CMD"; then
    echo ""
    echo "✅ Baseline OK. 시작 명령:"
    echo "  \$ $START_CMD"
else
    echo ""
    echo "❌ Baseline FAILED. 다른 작업 전에 검증부터 통과시키세요."
    echo "   (claude-progress.md의 'Current blocker'에 기록할 것)"
    exit 1
fi
