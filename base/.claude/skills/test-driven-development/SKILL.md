---
name: test-driven-development
description: 코드를 작성하기 전에 실패하는 테스트를 먼저 쓰게 한다. 버그 수정은 버그를 재현하는 테스트로 시작한다. Use when 어떤 로직을 구현하거나, 버그를 고치거나, 기존 동작을 바꿀 때, 코드가 작동함을 증명해야 할 때, 버그 리포트가 도착했을 때. 순수 설정·문서·정적 콘텐츠 변경처럼 동작에 영향이 없는 변경에는 쓰지 않는다.
user-invocable: true
argument-hint: "[구현할 기능 또는 재현할 버그 설명]"
---

# Test-Driven Development (테스트 주도 개발)

## 개요

통과하게 만들 코드를 짜기 *전에* 실패하는 테스트를 먼저 쓴다. 버그 수정은, 고치기 전에 버그를 재현하는 테스트를 먼저 쓴다. 테스트는 증거다 — "맞는 것 같다"는 완료가 아니다. 좋은 테스트가 있는 코드베이스는 AI 에이전트의 초능력이고, 테스트 없는 코드베이스는 부채다.

이 프로젝트에서 TDD는 완료의 정의(Definition of Done)와 직결된다 — validation 통과 + 증거 기록 없이 완료를 선언하지 않는다. 검증 실행은 `/verify` 스킬과, 프레임워크별 상세 테스트 패턴은 `harness/references/testing-patterns.md`와 연결된다.

> ML/DL 맥락: 학습/평가 코드의 테스트는 **시드 고정으로 재현성을 보장**하는 것에서 출발한다 — 동일 시드에서 동일 결과가 나오지 않으면 그 어떤 비교 실험도 신뢰할 수 없다.

## 언제 쓰나

- 새 로직·동작을 구현할 때
- 버그를 고칠 때 (Prove-It 패턴)
- 기존 기능을 수정할 때
- 엣지 케이스 처리를 추가할 때
- 기존 동작을 깨뜨릴 수 있는 모든 변경

**언제 쓰지 않나 (When NOT to use):** 순수 설정 변경, 문서 갱신, 동작에 영향이 없는 정적 콘텐츠 변경.

## 핵심 프로세스 — Red-Green-Refactor 사이클

```
    RED                GREEN              REFACTOR
 실패하는 테스트   통과시킬 최소한의      구현을
   작성       ──→     코드 작성     ──→   정리      ──→  (반복)
    │                  │                   │
    ▼                  ▼                   ▼
 테스트 실패        테스트 통과         테스트 여전히 통과
```

### 1단계: RED — 실패하는 테스트 작성

테스트를 먼저 쓴다. 반드시 실패해야 한다. 즉시 통과하는 테스트는 아무것도 증명하지 못한다.

```python
# RED: create_task가 아직 없어서 이 테스트는 실패한다
def test_creates_task_with_title_and_default_status():
    task = task_service.create_task(title="장보기")

    assert task.id is not None
    assert task.title == "장보기"
    assert task.status == "pending"
    assert isinstance(task.created_at, datetime)
```

### 2단계: GREEN — 통과시키기

테스트를 통과시킬 최소한의 코드를 쓴다. 과잉 설계하지 마라:

```python
# GREEN: 최소 구현
def create_task(title: str) -> Task:
    task = Task(
        id=generate_id(),
        title=title,
        status="pending",
        created_at=datetime.now(),
    )
    db.tasks.insert(task)
    return task
```

### 3단계: REFACTOR — 정리

테스트가 초록인 상태에서 동작을 바꾸지 않고 코드를 개선한다:

- 공통 로직 추출
- 네이밍 개선
- 중복 제거
- 필요 시 최적화

리팩터 단계마다 테스트를 실행해 아무것도 깨지지 않았는지 확인한다.

## 패턴

### Prove-It 패턴 (버그 수정)

버그가 보고되면 **고치는 것부터 시작하지 마라.** 버그를 재현하는 테스트를 먼저 써라.

```
버그 리포트 도착
       │
       ▼
  버그를 보여주는 테스트 작성
       │
       ▼
  테스트 실패 (버그 존재 확인)
       │
       ▼
  수정 구현
       │
       ▼
  테스트 통과 (수정이 작동함을 증명)
       │
       ▼
  전체 테스트 스위트 실행 (회귀 없음)
```

이 패턴은 이 프로젝트의 `bugfix` 워크플로(근본 원인 분석 + 노트 + 검증)와 자연스럽게 맞물린다.

```python
# 버그: "작업을 완료해도 completed_at 타임스탬프가 갱신되지 않음"

# 1단계: 재현 테스트 작성 (실패해야 함)
def test_sets_completed_at_when_task_completed():
    task = task_service.create_task(title="테스트")
    completed = task_service.complete_task(task.id)

    assert completed.status == "completed"
    assert isinstance(completed.completed_at, datetime)  # 여기서 실패 → 버그 확인

# 2단계: 버그 수정
def complete_task(task_id: str) -> Task:
    return db.tasks.update(
        task_id,
        status="completed",
        completed_at=datetime.now(),  # 누락되어 있던 부분
    )

# 3단계: 테스트 통과 → 버그 수정, 회귀 방지됨
```

### 테스트 피라미드

테스트 노력을 피라미드에 따라 투자한다 — 대부분은 작고 빠른 테스트, 상위로 갈수록 적게.

```
          ╱╲
         ╱  ╲         E2E 테스트 (~5%)
        ╱    ╲        전체 사용자 흐름 / 엔드투엔드 파이프라인
       ╱──────╲
      ╱        ╲      통합 테스트 (~15%)
     ╱          ╲     컴포넌트 상호작용, API/데이터 경계
    ╱────────────╲
   ╱              ╲   단위 테스트 (~80%)
  ╱                ╲  순수 로직, 격리, 밀리초 단위
 ╱──────────────────╲
```

**Beyonce 규칙:** 마음에 들었다면 테스트를 걸었어야 한다. 인프라 변경·리팩터·마이그레이션이 너의 버그를 잡아줄 책임은 없다 — 너의 테스트가 잡는다. 테스트가 없어서 변경이 코드를 깼다면, 그건 네 탓이다.

### 테스트 크기 (자원 모델)

| 크기 | 제약 | 속도 | 예시 |
|------|------|------|------|
| **Small** | 단일 프로세스, I/O·네트워크·DB 없음 | 밀리초 | 순수 함수, 데이터 변환, 손실/지표 계산 단위 테스트 |
| **Medium** | 멀티 프로세스 OK, localhost만, 외부 서비스 없음 | 초 | 테스트 DB API, 컴포넌트 테스트, 작은 모델 1-step 학습 |
| **Large** | 멀티 머신 OK, 외부 서비스 허용 | 분 | E2E, 성능 벤치마크, 전체 학습 파이프라인 |

작은 테스트가 스위트의 대다수를 차지해야 한다. 빠르고, 신뢰할 수 있고, 실패 시 디버깅이 쉽다.

### 좋은 테스트 작성하기

**상호작용이 아니라 상태를 테스트하라.** 내부적으로 어떤 메서드가 호출됐는지가 아니라, 연산의 *결과*를 단언하라. 호출 순서를 검증하는 테스트는 동작이 같아도 리팩터하면 깨진다.

```python
# 좋음: 함수가 무엇을 하는지(상태 기반) 테스트
def test_returns_tasks_sorted_by_creation_date_newest_first():
    tasks = list_tasks(sort_by="created_at", sort_order="desc")
    assert tasks[0].created_at > tasks[1].created_at

# 나쁨: 함수가 내부적으로 어떻게 동작하는지(상호작용 기반) 테스트
def test_calls_db_query_with_order_by():
    list_tasks(sort_by="created_at", sort_order="desc")
    db.query.assert_called_with(ANY)  # 리팩터하면 깨진다
```

**테스트에서는 DRY보다 DAMP.** 프로덕션 코드에서는 보통 DRY(반복하지 마라)가 옳다. 테스트에서는 **DAMP(서술적이고 의미 있는 표현)** 가 낫다. 테스트는 명세처럼 읽혀야 한다 — 공유 헬퍼를 추적하지 않고도 각 테스트가 완전한 이야기를 들려줘야 한다. 각 테스트를 독립적으로 이해할 수 있게 만든다면 테스트의 중복은 허용된다.

**목(mock)보다 실제 구현을 선호하라.** 일을 해내는 가장 단순한 테스트 더블을 쓴다. 테스트가 실제 코드를 많이 쓸수록 더 많은 확신을 준다.

```
선호 순서 (높음 → 낮음):
1. 실제 구현  → 최고 확신, 실제 버그를 잡는다
2. Fake       → 의존성의 인메모리 버전 (예: 가짜 DB)
3. Stub       → 정해진 데이터 반환, 동작 없음
4. Mock       → 메서드 호출 검증 — 아껴서 사용
```

**목은 다음일 때만:** 실제 구현이 너무 느리거나, 비결정적이거나, 통제할 수 없는 부작용이 있을 때(외부 API, 이메일 발송). 과도한 모킹은 프로덕션이 깨져도 통과하는 테스트를 만든다.

**Arrange-Act-Assert 패턴을 쓰라.**

```python
def test_marks_overdue_tasks_when_deadline_passed():
    # Arrange: 시나리오 준비
    task = create_task(title="테스트", deadline=datetime(2025, 1, 1))

    # Act: 테스트할 동작 수행
    result = check_overdue(task, now=datetime(2025, 1, 2))

    # Assert: 결과 검증
    assert result.is_overdue is True
```

**개념당 하나의 단언, 서술적인 테스트 이름.**

```python
# 좋음: 명세처럼 읽힘
def test_rejects_empty_titles(): ...
def test_trims_whitespace_from_titles(): ...
def test_is_idempotent_when_completing_already_completed_task(): ...

# 나쁨: 모호하고 한 테스트에 다 욱여넣음
def test_works(): ...
```

### ML/DL 테스트 — 시드와 재현성

ML 코드는 비결정성이 기본이다. 테스트는 먼저 결정성을 강제한다:

```python
def test_training_is_reproducible_under_fixed_seed():
    set_seed(42)  # torch, numpy, random 모두 고정
    loss_a = train_one_step(model_factory(), batch)

    set_seed(42)
    loss_b = train_one_step(model_factory(), batch)

    assert abs(loss_a - loss_b) < 1e-6  # 동일 시드 → 동일 결과

def test_no_data_leakage_between_train_and_eval_split():
    train_ids = set(train_ds.ids)
    eval_ids = set(eval_ds.ids)
    assert train_ids.isdisjoint(eval_ids)  # split 오염 차단
```

추가로 점검할 ML 단위 테스트: 텐서 shape/dtype/device, 손실·지표 식의 정확성, NaN/inf 미발생. 상세 패턴은 `harness/references/testing-patterns.md` 참조.

### 테스트 안티패턴

| 안티패턴 | 문제 | 해결 |
|---|---|---|
| 구현 세부 테스트 | 동작이 같아도 리팩터하면 깨짐 | 내부 구조가 아니라 입력·출력을 테스트 |
| Flaky 테스트 (타이밍·순서 의존) | 스위트 신뢰 저하 | 결정적 단언, 테스트 상태 격리 |
| 프레임워크 코드 테스트 | 서드파티 동작 테스트로 시간 낭비 | 네 코드만 테스트 |
| 스냅샷 남용 | 아무도 안 보는 큰 스냅샷, 사소한 변경에 깨짐 | 아껴 쓰고 변경마다 리뷰 |
| 테스트 격리 부재 | 개별 통과, 함께 실행하면 실패 | 각 테스트가 스스로 set up/tear down |
| 모든 것을 모킹 | 테스트는 통과, 프로덕션은 깨짐 | 실제 > fake > stub > mock, 경계에서만 모킹 |

### 복잡한 버그 수정 시 서브에이전트 활용

복잡한 버그는 재현 테스트를 서브에이전트에게 맡긴다 (이 프로젝트의 Subagent Strategy와 일치):

```
메인 에이전트: "이 버그를 재현하는 테스트를 작성할 서브에이전트를 띄운다:
[버그 설명]. 현재 코드에서 실패해야 한다."

서브에이전트: 재현 테스트 작성

메인 에이전트: 테스트가 실패함을 확인 → 수정 구현 → 테스트 통과 확인
```

수정을 모르는 상태로 테스트를 쓰게 하므로 더 견고한 테스트가 나온다.

## Common Rationalizations

| 변명 | 반박 |
|---|---|
| "코드 다 되면 테스트 짤게" | 안 짠다. 사후에 짠 테스트는 동작이 아니라 구현을 테스트한다. |
| "이건 너무 간단해서 테스트할 게 없어" | 간단한 코드는 복잡해진다. 테스트는 기대 동작을 문서화한다. |
| "테스트가 날 느리게 해" | 지금은 느리게 하지만, 나중에 코드를 바꿀 때마다 빠르게 한다. |
| "수동으로 테스트했어" | 수동 테스트는 남지 않는다. 내일의 변경이 그걸 깨도 알 길이 없다. |
| "코드가 자명해" | 테스트가 곧 명세다. 코드가 무엇을 *해야 하는지*를 문서화한다. |
| "이건 프로토타입일 뿐이야" | 프로토타입은 프로덕션이 된다. 첫날부터의 테스트가 '테스트 부채' 위기를 막는다. |
| "확실히 하려고 테스트 한 번 더 돌릴게" | 깨끗한 실행 후, 코드가 그대로면 같은 명령 반복은 아무것도 더하지 않는다. 이후 수정한 다음에만 다시 돌려라. |

## Red Flags

- 대응하는 테스트 없이 코드를 작성함
- 첫 실행에 통과하는 테스트 (생각한 것을 테스트하지 않을 수 있음)
- "모든 테스트 통과"라는데 실제로는 테스트를 돌리지 않음
- 재현 테스트 없는 버그 수정
- 애플리케이션 동작 대신 프레임워크 동작을 테스트함
- 기대 동작을 서술하지 않는 테스트 이름
- 스위트를 통과시키려 테스트를 건너뜀(skip)
- 코드 변경 없이 같은 테스트 명령을 연달아 두 번 실행함
- ML: 시드를 고정하지 않아 재현 불가능한 학습/평가 테스트

## Verification

구현 완료 후 증거 기반으로 확인한다:

- [ ] 모든 새 동작에 대응하는 테스트가 있다
- [ ] 모든 테스트가 통과한다 (`pytest -q` 또는 프로젝트의 테스트 명령 — `/verify`로 실행)
- [ ] 버그 수정에는 수정 전 실패했던 재현 테스트가 포함된다
- [ ] 테스트 이름이 검증하는 동작을 서술한다
- [ ] 건너뛰거나 비활성화한 테스트가 없다
- [ ] 커버리지가 (추적 중이라면) 감소하지 않았다
- [ ] ML 코드: 시드 고정 재현성 테스트와 train/eval split 비누수 검증이 있다

**참고:** 결과에 영향을 줄 수 있는 변경 후에만 테스트 명령을 다시 실행한다. 깨끗한 실행 뒤 코드가 그대로면 같은 명령을 반복하지 마라 — 확신을 더해주지 않는다.
