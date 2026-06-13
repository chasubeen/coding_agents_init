# 테스트 패턴 참조

스택 전반에서 자주 쓰는 테스트 패턴 모음. 구조·네이밍·모킹·통합/E2E를 다루며, ML 재현성 검증 항목을 포함한다.

관련 스킬: test-driven-development, /cross-check, /quality-gate

## 목차

- [테스트 구조 (Arrange-Act-Assert)](#테스트-구조-arrange-act-assert)
- [테스트 네이밍 규칙](#테스트-네이밍-규칙)
- [자주 쓰는 단언(assertion)](#자주-쓰는-단언assertion)
- [모킹 패턴](#모킹-패턴)
- [API / 통합 테스트](#api--통합-테스트)
- [E2E 테스트](#e2e-테스트)
- [ML / 재현성 테스트](#ml--재현성-테스트)
- [테스트 안티패턴](#테스트-안티패턴)

## 테스트 구조 (Arrange-Act-Assert)

```python
def test_creates_task_with_default_pending_status():
    # Arrange: 테스트 데이터와 사전 조건 설정
    payload = {"title": "Test Task", "priority": "high"}

    # Act: 테스트 대상 동작 수행
    result = create_task(payload)

    # Assert: 결과 검증
    assert result.title == "Test Task"
    assert result.priority == "high"
    assert result.status == "pending"
```

## 테스트 네이밍 규칙

```python
# 패턴: test_[대상]_[기대 동작]_[조건]
class TestTaskService:
    def test_create_task_returns_default_pending_status(self): ...
    def test_create_task_raises_validation_error_when_title_empty(self): ...
    def test_create_task_trims_whitespace_from_title(self): ...
    def test_create_task_generates_unique_id_per_task(self): ...
```

## 자주 쓰는 단언(assertion)

```python
# 동등성
assert result == expected           # 값 동등
assert result is expected           # 동일 객체

# 진리값
assert result            # truthy
assert not result        # falsy
assert result is None

# 숫자 / 부동소수점
assert result > 5
assert result <= 10
assert result == pytest.approx(0.3, rel=1e-5)   # 부동소수점 비교

# 문자열
assert re.search(r"pattern", result)
assert "substring" in result

# 컬렉션
assert item in collection
assert len(collection) == 3
assert mapping["key"] == "value"

# 예외
with pytest.raises(ValidationError):
    fn()
with pytest.raises(ValueError, match="specific message"):
    fn()
```

## 모킹 패턴

### Mock 함수

```python
from unittest.mock import MagicMock

mock_fn = MagicMock(return_value=42)
mock_fn.side_effect = lambda x: x * 2

mock_fn.assert_called()
mock_fn.assert_called_with("arg1", "arg2")
assert mock_fn.call_count == 3
```

### 모듈/의존성 패치

```python
from unittest.mock import patch

# 경계(외부 호출)만 패치한다
with patch("myapp.db.query", return_value=[{"id": 1, "title": "Test"}]):
    result = fetch_tasks()
```

### 경계에서만 모킹한다

```
모킹할 것:                      모킹하지 말 것:
├── 데이터베이스 호출           ├── 내부 유틸 함수
├── HTTP 요청                   ├── 비즈니스 로직
├── 파일 시스템 작업            ├── 데이터 변환
├── 외부 API 호출               ├── 검증 함수
└── 시간/날짜 (필요 시)         └── 순수 함수
```

## API / 통합 테스트

```python
# FastAPI + httpx/TestClient 예시
from fastapi.testclient import TestClient
from myapp.app import app

client = TestClient(app)

def test_create_task_returns_201():
    resp = client.post(
        "/api/tasks",
        json={"title": "Test Task"},
        headers={"Authorization": f"Bearer {test_token}"},
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["title"] == "Test Task"
    assert body["status"] == "pending"

def test_create_task_returns_422_for_invalid_input():
    resp = client.post(
        "/api/tasks", json={"title": ""},
        headers={"Authorization": f"Bearer {test_token}"},
    )
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "VALIDATION_ERROR"

def test_create_task_returns_401_without_auth():
    resp = client.post("/api/tasks", json={"title": "Test"})
    assert resp.status_code == 401
```

## E2E 테스트

```python
# Playwright (Python) 예시
from playwright.sync_api import Page, expect

def test_user_can_create_and_complete_task(page: Page):
    # 이동 및 인증
    page.goto("/")
    page.fill('[name="email"]', "test@example.com")
    page.fill('[name="password"]', "testpass123")
    page.click('button:has-text("Log in")')

    # 작업 생성
    page.click('button:has-text("New Task")')
    page.fill('[name="title"]', "Buy groceries")
    page.click('button:has-text("Create")')

    # 결과 확인
    expect(page.locator("text=Buy groceries")).to_be_visible()
```

## ML / 재현성 테스트

ML/DL 연구 코드에서는 결과의 신뢰성을 테스트로 고정한다.

- [ ] **시드 고정 재현성** — 동일 시드로 두 번 학습/추론하면 동일(또는 허용 오차 내) 결과 (`torch.manual_seed`, `np.random.seed`, `random.seed`)
- [ ] **데이터 split 무결성** — train/val/test가 서로 겹치지 않음 (인덱스 교집합이 공집합)
- [ ] **결정론적 경로** — 작은 합성 입력으로 forward 출력 shape/값을 `pytest.approx`로 단언
- [ ] 데이터 전처리 파이프라인이 입력→출력 형태/범위를 보존하는지 단위 테스트

```python
def test_train_val_test_splits_are_disjoint():
    train, val, test = make_splits(dataset, seed=42)
    assert set(train.indices) & set(val.indices) == set()
    assert set(train.indices) & set(test.indices) == set()
    assert set(val.indices) & set(test.indices) == set()

def test_forward_is_deterministic_under_fixed_seed():
    torch.manual_seed(0)
    out_a = model(sample_batch)
    torch.manual_seed(0)
    out_b = model(sample_batch)
    assert torch.allclose(out_a, out_b)
```

## 테스트 안티패턴

| 안티패턴 | 문제 | 더 나은 방법 |
|---|---|---|
| 구현 세부사항 테스트 | 리팩터링하면 깨짐 | 입력/출력을 테스트 |
| 모든 것을 스냅샷 | 아무도 diff를 안 봄 | 구체적 값을 단언 |
| 공유 가변 상태 | 테스트끼리 오염 | 테스트마다 setup/teardown |
| 서드파티 코드 테스트 | 내 버그가 아님 | 경계를 모킹 |
| CI 통과용 테스트 스킵 | 실제 버그 은폐 | 고치거나 삭제 |
| 영구 `skip` 처리 | 죽은 코드 | 제거하거나 수정 |
| 지나치게 광범위한 단언 | 회귀를 못 잡음 | 구체적으로 단언 |
| 비결정적 테스트 (시드 미고정) | 간헐적 실패(flaky) | 시드 고정, 외부 난수 제거 |

---

원본 참고: addyosmani/agent-skills (`references/testing-patterns.md`)
