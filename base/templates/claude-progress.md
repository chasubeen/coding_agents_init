# Progress Log

<!--
진행 로그 (Harness Engineering 최소 필수 팩).
모든 세션을 여기에 기록하고, 다음 세션은 이 파일의 "현재 검증된 상태"에서 출발한다.
참고: https://walkinglabs.github.io/learn-harness-engineering/ko/
규칙: 추측 금지 — 실제로 검증한 것만 "verified"로 적는다.
-->

## 현재 검증된 상태 (Current verified state)

- **Repository root**: <프로젝트 절대 경로>
- **Standard startup path**: <실행 명령, 예: python main.py / npm run dev>
- **Standard verification path**: <검증 명령, 예: pytest -q / npm test>
- **Highest priority unfinished feature**: <harness/feature_list.json의 다음 작업 id/제목>
- **Current blocker**: <막혀 있는 항목, 없으면 "none">

---

## 세션 레코드 (Session records)

<!-- 최신 세션이 위로 오도록 append. 세션당 1블록. -->

### [YYYY-MM-DD] 세션 제목

- **Goal**: <이번 세션에서 하려던 것>
- **Completed**: <실제로 끝낸 것 (검증된 것만)>
- **Verification run**: <실행한 테스트/명령과 결과>
- **Evidence recorded**: <증거 위치 — 로그/스크린샷/테스트 출력 경로>
- **Commits**: <커밋 해시/메시지>
- **Known risks**: <이번 변경으로 깨졌을 수 있는 것>
- **Next best action**: <다음 세션이 가장 먼저 할 일>
