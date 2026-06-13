# 하네스 고급 원칙 (Harness Principles)

최소 필수 팩(`init.sh`·`claude-progress.md`·`feature_list.json`) 위에 얹는, 신뢰성을 끌어올리는 운영 원칙. 모든 스킬·에이전트가 공유한다.

관련 스킬: /harness, /cross-check, /doubt-driven-development, /verify

## 1. Observability — "관찰되지 않음 ≠ 없음" (not_observed ≠ absent)

미확인 정보를 **조용히 지어내지 않는다.** 보지 못한 것은 "없다"가 아니라 **`unknown`(미관찰)** 이다.

- 검증하지 못한 값·상태·결과는 `unknown` / `not observed`로 **명시적으로 표기**한다. 빈칸을 그럴듯한 추측으로 메우지 않는다.
- 단정에는 **증거**(파일·로그·명령 출력·커밋)를 붙인다. 증거 없으면 "추정" 또는 "미확인"이라고 라벨링한다.
- "되는 것 같다 / 아마 통과할 것이다"는 검증이 아니다. 실행해서 관찰하거나 `unknown`으로 남긴다.
- 적용처: `claude-progress.md`의 verified 상태, `feature_list.json`의 `passing`/`evidence`, `/cross-check`·`/verify` 보고, 디버깅 가설.

> 거짓 확신 1건이 미관찰 표기 10건보다 비싸다. 모르면 모른다고 적는다.

## 2. Stop Conditions — 중단 조건

작업 시작 전, **언제 멈추고 재계획할지**를 명시한다. 막혀도 억지로 밀어붙이지 않기 위한 안전장치.

`spec`/`plan`에 다음을 적는다:
- **성공 기준 (Acceptance)** — 무엇이 참이면 완료인가 (구체적·검증 가능).
- **중단 조건 (Stop)** — 아래 중 하나라도 발생하면 STOP → 사용자에게 보고·재계획:
  - 같은 에러로 2~3회 연속 실패
  - 범위가 계획을 벗어나기 시작함 (scope drift)
  - 되돌리기 어려운 작업(삭제·배포·스키마 변경) 직전인데 승인이 없음
  - 가정이 틀린 것으로 드러남
- **미지수 (Unknowns)** — 시작 시점에 모르는 것. `unknown`으로 명시하고, 해소되면 갱신한다. (원칙 1과 연결)

## 3. Validation Perspectives — 검증 관점 게이트

비자명한 plan은 구현 전에 아래 관점을 점검하고, 점검했다는 사실을 `plan.md`(또는 결정 기록)에 남긴다. (team_validation_mode)

| 관점 | 점검 질문 |
|------|-----------|
| **Spec-Plan 일치** | 계획이 spec의 범위·수용기준과 어긋나지 않는가? |
| **재사용 (Memory/Reuse)** | 기존 코드·노트·교훈(`skill_graph/`·`tasks/lessons.md`)을 재사용했는가, 중복 구현은 아닌가? |
| **제품 적합 (Product fit)** | 사용자/연구 목표에 실제로 부합하는가, 과잉설계는 아닌가? |
| **보안 적합 (Security fit)** | 입력·인증·역직렬화·시크릿 측면 위험은? (`security-and-hardening`, `harness/references/security-checklist.md`) |

- 점검 결과 위험이 보이면 구현 전에 해소하거나 `/cross-check`(Codex)로 교차검증한다.
- 자명한 변경(한 줄 수정·리네이밍)에는 생략한다 — 과잉 프로세스 금지.

## 4. Definition of Done — 완료의 정의

다음을 **모두** 만족할 때만 "완료"다. 의도만으로 완료 선언 금지:

- [ ] validation 명령이 실제로 실행되어 통과 (출력=증거 기록)
- [ ] 범위를 지킴 (scope drift 없음)
- [ ] 재시작/재실행 후에도 유지됨 (재현성)
- [ ] 미확인 항목은 `unknown`으로 정직하게 표기됨 (원칙 1)
- [ ] 저장소만으로 다음 세션이 이어갈 수 있음 (`handoff.md`·`claude-progress.md`)

---

원본 영감: walkinglabs/learn-harness-engineering, Chachamaru127/claude-code-harness (observability·stop conditions·validation perspectives).
