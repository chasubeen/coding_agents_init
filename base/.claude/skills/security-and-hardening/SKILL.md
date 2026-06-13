---
name: security-and-hardening
description: 코드를 취약점에 대비해 강화한다. 사용자 입력·인증·데이터 저장·외부 연동을 다룰 때 사용(Use when). 신뢰할 수 없는 데이터를 받거나, 세션을 관리하거나, 서드파티와 통신하는 기능을 만들 때 사용(Use when). ML/DL 맥락에서는 pickle/torch.load 역직렬화와 데이터 유출까지 포함. 상세 체크리스트는 harness/references/security-checklist.md 참조.
user-invocable: true
argument-hint: "[ (없음) | diff | <파일경로> | <기능/엔드포인트 설명> ]"
---

# 보안과 하드닝

## 개요

보안 우선 개발 실천. 모든 외부 입력을 적대적으로, 모든 시크릿을 신성하게, 모든 권한 검사를 필수로 취급한다. 보안은 단계가 아니라 **제약**이다 — 사용자 데이터·인증·외부 시스템을 건드리는 모든 줄에 걸리는 제약. 구체적인 체크리스트는 `harness/references/security-checklist.md`를 참조하고, 보안 민감 변경은 커밋 전 `/cross-check`(Codex)로 제2의 눈을 받는 것을 권한다.

## 언제 쓰나

- 사용자 입력을 받는 무언가를 만들 때
- 인증/인가를 구현할 때
- 민감 데이터를 저장·전송할 때
- 외부 API/서비스와 연동할 때
- 파일 업로드, 웹훅, 콜백을 추가할 때
- 결제/PII 데이터를 다룰 때
- ML/DL: 모델·체크포인트 역직렬화(pickle/torch.load), 외부 데이터셋 적재, 학습 데이터 유출 경계를 다룰 때

### When NOT to use

- 외부 입력·시크릿·인증·외부 시스템을 전혀 건드리지 않는 순수 내부 계산 로직 (예: 수치 알고리즘 리팩터)
- 이미 신뢰 경계가 명확하고 변경이 그 경계를 넘지 않는 경우 (단, "내부 도구라 괜찮다"는 변명은 금물 — 아래 Rationalizations 참조)

## 핵심 프로세스: 먼저 위협 모델링 (Threat Model First)

위협 모델 없이 붙인 통제는 추측이다. 하드닝 전에 5분만 공격자처럼 생각한다:

1. **신뢰 경계를 그린다.** 신뢰할 수 없는 데이터가 어디서 시스템으로 들어오는가? HTTP 요청, 폼 필드, 파일 업로드, 웹훅, 서드파티 API, 메시지 큐, **LLM 출력**, 그리고 ML 맥락의 **외부 데이터셋/체크포인트**. 모든 경계가 공격면이다.
2. **자산을 명명한다.** 훔치거나 망가뜨릴 가치가 있는 것은? 자격증명, PII, 결제 데이터, 관리자 액션, 학습 데이터·모델 가중치.
3. **각 경계에 STRIDE를 적용한다** — 의식이 아니라 빠른 렌즈:

| 위협 | 질문 | 전형적 완화 |
|---|---|---|
| **S**poofing (위장) | 사용자/서비스를 사칭할 수 있나? | 인증, 서명 검증 |
| **T**ampering (변조) | 전송·저장 중 데이터를 바꿀 수 있나? | 무결성 검사, 파라미터화 쿼리, HTTPS |
| **R**epudiation (부인) | 나중에 행위를 부인할 수 있나? | 보안 이벤트 감사 로깅 |
| **I**nformation disclosure (정보 노출) | 데이터가 새나? | 암호화, 필드 allowlist, 일반화된 에러 |
| **D**enial of service (서비스 거부) | 과부하시킬 수 있나? | 레이트 리밋, 입력 크기 제한, 타임아웃 |
| **E**levation of privilege (권한 상승) | 가져선 안 될 권한을 얻을 수 있나? | 인가 검사, 최소 권한 |

4. **use case 옆에 abuse case를 쓴다.** 각 기능마다 "이걸 어떻게 악용할까?"를 물어 그것을 첫 테스트로 삼는다.

기능의 신뢰 경계를 명명하지 못하면 아직 보안화할 준비가 안 된 것이다. 이것이 OWASP **A04: Insecure Design** — 대부분의 침해는 코드가 아니라 설계에서 시작한다.

## 3단계 경계 시스템

### Always Do (예외 없음)

- 외부 입력을 **시스템 경계에서 모두 검증** (API 라우트, 폼 핸들러)
- DB 쿼리를 **모두 파라미터화** — 사용자 입력을 SQL에 절대 연결하지 않음
- 출력을 **인코딩**해 XSS 방지 (프레임워크 자동 이스케이핑 사용, 우회 금지)
- 외부 통신에 **HTTPS** 사용
- 비밀번호는 **bcrypt/scrypt/argon2로 해싱** (평문 저장 금지)
- **보안 헤더 설정** (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- 세션 쿠키에 **httpOnly, secure, sameSite** 사용
- 릴리스 전 **의존성 감사** 실행 (`pip-audit` / `npm audit` 등)
- **역직렬화는 신뢰된 소스만** — `pickle.load`, `torch.load(weights_only=False)`, `yaml.load`에 외부 파일을 절대 넣지 않음 (ML/DL)

### Ask First (사람 승인 필요)

- 새 인증 흐름 추가 또는 auth 로직 변경
- 새 범주의 민감 데이터(PII, 결제 정보) 저장
- 새 외부 서비스 연동 추가
- CORS 설정 변경
- 파일 업로드 핸들러 추가
- 레이트 리밋/스로틀링 수정
- 상승된 권한/롤 부여
- 외부에서 받은 모델 체크포인트·데이터셋을 신뢰 경계 안으로 들이기 (ML/DL)

### Never Do

- **시크릿을 버전 관리에 커밋하지 않음** (API 키, 비밀번호, 토큰)
- **민감 데이터를 로깅하지 않음** (비밀번호, 토큰, 전체 카드번호)
- **클라이언트 측 검증을 보안 경계로 신뢰하지 않음**
- **보안 헤더를 편의상 끄지 않음**
- **사용자 데이터로 `eval()`/`innerHTML`/`os.system` 사용하지 않음**
- 인증 토큰을 클라이언트 접근 가능 저장소(localStorage)에 두지 않음
- 스택 트레이스/내부 에러 상세를 사용자에게 노출하지 않음
- **신뢰할 수 없는 출처의 pickle/체크포인트를 역직렬화하지 않음** — 임의 코드 실행으로 직결 (ML/DL)

## OWASP Top 10 예방 패턴

예방 패턴 모음이며 순위가 아니다. 2021 순위는 `harness/references/security-checklist.md`의 빠른 참조 표를 본다. 예시는 개념 전달용 — 프로젝트 스택(Python/FastAPI/Node 등)에 맞춰 옮긴다.

### Injection (SQL, NoSQL, OS Command)

```python
# BAD: 문자열 연결로 인한 SQL 인젝션
query = f"SELECT * FROM users WHERE id = '{user_id}'"

# GOOD: 파라미터화 쿼리
cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# GOOD: ORM의 파라미터화 입력
user = session.query(User).filter(User.id == user_id).one_or_none()
```

### Broken Authentication

```python
# 비밀번호 해싱
import bcrypt

hashed = bcrypt.hashpw(plaintext.encode(), bcrypt.gensalt(rounds=12))
is_valid = bcrypt.checkpw(plaintext.encode(), hashed)
# 세션 쿠키: httpOnly + secure + sameSite, 시크릿은 환경변수에서
```

### Cross-Site Scripting (XSS)

```javascript
// BAD: 사용자 입력을 HTML로 렌더링
element.innerHTML = userInput;

// GOOD: 프레임워크 자동 이스케이핑 사용 (React는 기본 처리)
return <div>{userInput}</div>;

// 꼭 HTML을 렌더해야 하면 먼저 sanitize
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);
```

### Broken Access Control

```python
# 인증만이 아니라 인가를 항상 확인
@app.patch("/api/tasks/{task_id}")
def update_task(task_id: str, user=Depends(authenticate)):
    task = task_service.find_by_id(task_id)
    # 인증된 사용자가 이 리소스를 소유하는지 확인
    if task.owner_id != user.id:
        raise HTTPException(403, "Not authorized to modify this task")
    return task_service.update(task_id, ...)
```

### Security Misconfiguration

- 보안 헤더 설정 (Express는 helmet, FastAPI는 미들웨어로 CSP/HSTS 등)
- CSP는 `default-src 'self'`에서 시작해 필요한 출처만 추가
- CORS는 알려진 출처로 제한 — 와일드카드(`*`) 금지

### Sensitive Data Exposure

```python
# 민감 필드를 API 응답에 절대 반환하지 않음
def sanitize_user(user) -> dict:
    public = {k: v for k, v in user.items()
              if k not in {"password_hash", "reset_token"}}
    return public

# 시크릿은 환경변수에서
API_KEY = os.environ.get("STRIPE_API_KEY")
if not API_KEY:
    raise RuntimeError("STRIPE_API_KEY not configured")
```

### Server-Side Request Forgery (SSRF)

서버가 사용자가 영향을 준 URL을 가져올 때마다 — 웹훅, "URL에서 import", 이미지 프록시, 링크 미리보기 — 공격자가 내부 서비스(클라우드 메타데이터, `localhost`, 사설 IP)로 조준할 수 있다.

```python
# GOOD: scheme+host allowlist, 해석된 IP가 하나라도 사설이면 거부, 리다이렉트 금지
import socket, ipaddress

ALLOWED_HOSTS = {"hooks.example.com"}

def assert_safe_url(raw: str) -> str:
    url = urlparse(raw)
    if url.scheme != "https":
        raise ValueError("https only")
    if url.hostname not in ALLOWED_HOSTS:
        raise ValueError("host not allowed")
    for info in socket.getaddrinfo(url.hostname, None):
        ip = ipaddress.ip_address(info[4][0])
        if not ip.is_global:   # loopback/link-local/private/reserved 차단
            raise ValueError("private/reserved IP")
    return raw
```

`is_global` 검사는 loopback, link-local `169.254.169.254`(클라우드 메타데이터, SSRF 1순위 타깃), 사설, unique-local 범위를 IPv4/IPv6 모두에서 막는다.

**주의 — TOCTOU 간극이 남는다.** 검증 후 실제 fetch가 DNS를 다시 해석하면 짧은 TTL로 내부 IP로 rebind될 수 있다. 고위험 표면은 한 번 해석한 IP에 고정 연결하거나 필터링 에이전트를 앞에 둔다.

## 입력 검증 패턴

### 경계에서 스키마 검증

```python
from pydantic import BaseModel, Field

class CreateTask(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    priority: Literal["low", "medium", "high"] = "medium"

# 라우트 핸들러에서 검증 — 실패 시 422
```

### 파일 업로드 안전

```python
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_SIZE = 5 * 1024 * 1024  # 5MB

def validate_upload(file):
    if file.content_type not in ALLOWED_TYPES:
        raise ValidationError("File type not allowed")
    if file.size > MAX_SIZE:
        raise ValidationError("File too large (max 5MB)")
    # 확장자를 믿지 말 것 — 중요하면 magic bytes 확인
```

## 의존성 감사 결과 triage

모든 감사 결과가 즉시 조치 대상은 아니다.

```
감사가 취약점을 보고
├── 심각도: critical / high
│   ├── 취약 코드가 앱에서 도달 가능한가?
│   │   ├── YES → 즉시 수정 (업데이트/패치/교체)
│   │   └── NO (dev 전용, 미사용 경로) → 곧 수정, 블로커는 아님
│   └── 수정본이 있는가?
│       ├── YES → 패치 버전으로 업데이트
│       └── NO → 우회책 검토, 교체 고려, 또는 리뷰 날짜와 함께 allowlist
├── 심각도: moderate → 프로덕션 도달 시 다음 릴리스 / dev 전용이면 백로그
└── 심각도: low → 정기 의존성 업데이트 때 처리
```

연기할 때는 이유와 리뷰 날짜를 문서화한다.

### 공급망 위생 (Supply Chain)

감사는 알려진 CVE를 잡지만 악성·타이포스쿼팅 패키지는 못 잡는다.

- **lockfile을 커밋**하고 CI는 재현 가능 설치(`npm ci`, `pip install -r ... --require-hashes`)를 쓴다.
- **새 의존성은 추가 전에 리뷰** — 유지보수 상태, 다운로드 수, 정말 필요한지. 모든 의존성은 공격면이다 (OWASP **A06**, **LLM03: Supply Chain**).
- 낯선 패키지의 **`postinstall`/setup 스크립트를 경계** — 설치 시 임의 코드 실행.
- **타이포스쿼트 주의** — `cross-env` vs `crossenv`.
- ML/DL: HuggingFace/모델 허브에서 받은 **pickle 직렬화 가중치를 경계** — 가능하면 safetensors나 `weights_only=True`를 쓴다.

## 시크릿 관리

```
.env 파일:
  ├── .env.example  → 커밋 (placeholder 템플릿)
  ├── .env          → 커밋 안 함 (실제 시크릿)
  └── .env.local    → 커밋 안 함 (로컬 오버라이드)

.gitignore 에 포함:
  .env / .env.local / .env.*.local / *.pem / *.key
```

**커밋 전 항상 확인:**

```bash
git diff --cached | grep -iE "password|secret|api_key|token"
```

**시크릿이 한 번이라도 커밋되면 회전(rotate)하라.** 줄을 지우거나 히스토리를 다시 쓰는 것으로는 부족하다 — 원격에 닿는 순간 손상된 것으로 간주한다. 키를 폐기·재발급한 뒤 히스토리에서 제거한다. (우리 `security-scan` 훅이 시크릿 패턴을 비차단 경고하지만, 최종 책임은 사람에게 있다.)

## AI / LLM 기능 보안

앱이 LLM을 호출하면 — 챗봇, 요약기, 에이전트, RAG — 새 공격면을 물려받는다. [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/llm-top-10/)에 매핑한다:

- **모델 출력을 신뢰할 수 없는 입력으로 취급 (LLM05: Improper Output Handling).** LLM 출력을 `eval`/SQL/shell/`innerHTML`/파일 경로에 그대로 넣지 않는다. 원시 사용자 입력처럼 검증·인코딩한다.
- **프롬프트는 탈취될 수 있다고 가정 (LLM01: Prompt Injection).** 컨텍스트 윈도우의 신뢰할 수 없는 텍스트(사용자 메시지, 가져온 웹페이지, PDF)가 지시를 나를 수 있다. 시스템 프롬프트는 보안 경계가 아니다 — 권한은 코드로 강제한다.
- **시크릿·타 사용자 데이터를 프롬프트에서 배제 (LLM02 / LLM07).** 컨텍스트에 든 것은 되돌아 나올 수 있다.
- **도구·에이전트 권한 제약 (LLM06: Excessive Agency).** 도구를 최소로 스코핑하고, 파괴적/되돌릴 수 없는 액션은 확인을 요구하며, 모든 도구 인자를 검증한다.
- **소비 한계 (LLM10: Unbounded Consumption).** 토큰·요청률·루프/재귀 깊이를 제한한다.
- **검색 데이터 격리 (LLM08: Vector and Embedding Weaknesses).** RAG에서 벡터 스토어를 신뢰 경계로 — 테넌트별 임베딩 분리, 색인 전 문서 검증.

```python
# BAD: 모델 출력을 명령이나 마크업으로 신뢰
sql = llm.generate(f"Write SQL for: {user_question}")
db.execute(sql)   # 임의 쿼리 실행

# GOOD: 모델 출력은 데이터 — 방어적으로 파싱 → 검증 → 인코딩
try:
    intent = CommandSchema.model_validate_json(llm.reply_json(user_message))
except ValidationError:
    raise ValidationError("unexpected model output")
run_allowlisted_action(intent.action, intent.params)
```

## ML/DL 전용 보안 메모

- **역직렬화**: 신뢰할 수 없는 `pickle`/`torch.load(weights_only=False)`/`joblib`/`yaml.load(Loader=FullLoader)`는 임의 코드 실행이다. 외부 가중치는 `safetensors` 또는 `torch.load(..., weights_only=True)`로 적재한다. (우리 `security-scan` 훅이 `pickle`/`eval` 패턴을 경고한다.)
- **데이터 유출(leakage)**: 학습/평가 split 오염, 라벨 누수, 전처리 통계를 전체 데이터셋에서 계산하는 것은 보안과 결과 신뢰성 양쪽 문제다. split 경계를 코드 경계처럼 검증한다 (`debugging-and-error-recovery`의 "의심스럽게 좋은 지표" 참조).
- **민감 데이터**: 학습 데이터에 PII가 포함되면 모델이 이를 암기·재현할 수 있다. 데이터 출처와 라이선스를 `skill_graph/`에 기록한다.

## Common Rationalizations

| 변명 | 반박 |
|---|---|
| "내부 도구라 보안은 중요하지 않아" | 내부 도구도 뚫린다. 공격자는 가장 약한 고리를 노린다. |
| "보안은 나중에 추가하자" | 보안 retrofit은 처음 넣는 것보다 10배 어렵다. 지금 넣어라. |
| "아무도 이걸 공격하지 않을 거야" | 자동 스캐너가 찾아낸다. 모호성에 의한 보안은 보안이 아니다. |
| "프레임워크가 알아서 해줘" | 프레임워크는 도구를 줄 뿐 보장하지 않는다. 올바르게 써야 한다. |
| "프로토타입일 뿐인데" | 프로토타입은 프로덕션이 된다. 첫날부터 보안 습관을. |
| "위협 모델링은 오버야" | "어떻게 공격할까?" 5분이 어떤 통제로도 못 막는 설계 결함을 예방한다. |
| "그냥 LLM 출력이고 텍스트일 뿐인데" | 그 "텍스트"가 SQL문, script 태그, shell 명령일 수 있다. |
| "이 pickle은 우리가 만든 거니까 괜찮아" (ML/DL) | 출처를 추적·검증할 수 없으면 신뢰할 수 없다. 가능하면 safetensors로. |

## Red Flags

- 사용자 입력이 DB 쿼리/shell/HTML 렌더링에 직접 전달됨
- 소스나 커밋 히스토리에 시크릿
- 인증/인가 검사 없는 API 엔드포인트
- CORS 미설정 또는 와일드카드(`*`) 출처
- 인증 엔드포인트에 레이트 리밋 없음
- 스택 트레이스/내부 에러가 사용자에게 노출됨
- 알려진 critical 취약점이 있는 의존성
- 서버가 allowlist 없이 사용자 제공 URL을 fetch (SSRF)
- LLM/모델 출력이 쿼리/DOM/shell/`eval`로 전달됨
- 시크릿·PII·전체 시스템 프롬프트가 LLM 컨텍스트에 들어감
- 신뢰할 수 없는 출처의 pickle/torch.load 역직렬화 (ML/DL)
- 전처리 통계가 전체 데이터셋에서 계산됨 — 평가셋 누수 (ML/DL)

## Verification

보안 관련 코드 구현 후 (증거 기반 체크리스트):

- [ ] 의존성 감사에 critical/high 취약점이 없다 (감사 출력 첨부)
- [ ] 소스·git 히스토리에 시크릿이 없다 (`git diff --cached | grep` 통과)
- [ ] 모든 사용자 입력이 시스템 경계에서 검증된다
- [ ] 보호된 모든 엔드포인트에서 인증·인가를 확인한다
- [ ] 응답에 보안 헤더가 존재한다 (DevTools로 확인)
- [ ] 에러 응답이 내부 상세를 노출하지 않는다
- [ ] 인증 엔드포인트에 레이트 리밋이 동작한다
- [ ] 서버 측 URL fetch가 allowlist로 검증된다 (SSRF 차단)
- [ ] LLM/모델 출력이 사용 전 검증·인코딩된다 (AI 기능 있을 시)
- [ ] 외부 pickle/체크포인트를 신뢰하지 않거나 safetensors/`weights_only=True`를 쓴다 (ML/DL)
- [ ] 보안 민감 변경은 커밋 전 `/cross-check`(Codex)로 교차검증되었다
- [ ] 상세 체크리스트(`harness/references/security-checklist.md`)를 통과했다
