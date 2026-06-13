# 보안 체크리스트

웹/백엔드/ML 코드의 보안을 빠르게 점검하기 위한 참조 체크리스트. 위협 모델링부터 OWASP Top 10, LLM 보안까지 다룬다.

관련 스킬: /cross-check, security-and-hardening, security-review

## 목차

- [위협 모델링 (여기서 시작)](#위협-모델링-여기서-시작)
- [커밋 전 점검](#커밋-전-점검)
- [인증 (Authentication)](#인증-authentication)
- [인가 (Authorization)](#인가-authorization)
- [입력 검증](#입력-검증)
- [보안 헤더](#보안-헤더)
- [CORS 설정](#cors-설정)
- [데이터 보호](#데이터-보호)
- [의존성 보안](#의존성-보안)
- [ML / 데이터 보안](#ml--데이터-보안)
- [AI / LLM 보안](#ai--llm-보안)
- [에러 처리](#에러-처리)
- [OWASP Top 10 빠른 참조](#owasp-top-10-빠른-참조)
- [OWASP LLM Top 10 빠른 참조](#owasp-llm-top-10-빠른-참조)

## 위협 모델링 (여기서 시작)

통제 수단을 꺼내기 전에, 5분만 공격자처럼 생각한다.

- [ ] 신뢰 경계(trust boundary)를 그렸다 — 요청, 업로드, 웹훅, 외부 API, LLM 출력
- [ ] 자산을 명시했다 — 자격증명, PII, 결제 데이터, 관리자 작업, 자금 이동, **학습 데이터셋·모델 가중치**
- [ ] 경계마다 STRIDE를 적용했다 — Spoofing(위장), Tampering(변조), Repudiation(부인), Information disclosure(정보 노출), DoS(서비스 거부), Elevation of privilege(권한 상승)
- [ ] 유스케이스 옆에 오용 사례(abuse case)를 적었다 — "이걸 어떻게 악용할 수 있지?"

## 커밋 전 점검

- [ ] 코드에 시크릿이 없다 (`git diff --cached | grep -i "password\|secret\|api_key\|token"`)
- [ ] `.gitignore`가 커버한다: `.env`, `.env.local`, `*.pem`, `*.key`, **`*.pth`/`*.ckpt`(가중치), 데이터셋 경로**
- [ ] `.env.example`는 플레이스홀더 값만 사용한다 (실제 시크릿 금지)

## 인증 (Authentication)

- [ ] 비밀번호는 bcrypt(≥12 rounds), scrypt, argon2로 해싱
- [ ] 세션 쿠키: `httpOnly`, `secure`, `sameSite: 'lax'`
- [ ] 세션 만료 설정 (합리적인 max-age)
- [ ] 로그인 엔드포인트 레이트 리밋 (15분당 ≤10회)
- [ ] 비밀번호 재설정 토큰: 시간 제한(≤1시간), 1회용
- [ ] 반복 실패 후 계정 잠금 (선택, 알림 포함)
- [ ] 민감 작업에 MFA 지원 (선택, 권장)

## 인가 (Authorization)

- [ ] 보호된 모든 엔드포인트가 인증을 확인한다
- [ ] 모든 리소스 접근이 소유권/역할을 확인한다 (IDOR 방지)
- [ ] 관리자 엔드포인트는 admin 역할을 검증한다
- [ ] API 키는 최소 권한으로 범위가 한정된다
- [ ] JWT 토큰을 검증한다 (서명, 만료, issuer)

## 입력 검증

- [ ] 모든 사용자 입력을 시스템 경계(API 라우트, 폼 핸들러)에서 검증한다
- [ ] 검증은 거부 목록(denylist)이 아니라 허용 목록(allowlist) 기반이다
- [ ] 문자열 길이를 제한한다 (min/max)
- [ ] 숫자 범위를 검증한다
- [ ] 이메일·URL·날짜 형식을 적절한 라이브러리로 검증한다
- [ ] 파일 업로드: 타입 제한, 크기 제한, 내용 검증
- [ ] SQL 쿼리는 파라미터화한다 (문자열 결합 금지)
- [ ] HTML 출력을 인코딩한다 (프레임워크 자동 이스케이프 활용)
- [ ] 리다이렉트 전 URL을 검증한다 (open redirect 방지)
- [ ] 서버 측 URL 페치는 allowlist로 제한하고 사설/예약 IP를 차단한다 (SSRF 방지)

## 보안 헤더

```
Content-Security-Policy: default-src 'self'; script-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0  (비활성화, CSP에 의존)
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## CORS 설정

```python
# 제한적 설정 (권장) — FastAPI 예시
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com", "https://app.yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Content-Type", "Authorization"],
)

# 운영 환경에서 절대 금지:
# allow_origins=["*"]  # 모든 origin 허용
```

## 데이터 보호

- [ ] 민감 필드를 API 응답에서 제외한다 (`password_hash`, `reset_token` 등)
- [ ] 민감 데이터를 로깅하지 않는다 (비밀번호, 토큰, 전체 카드번호)
- [ ] PII는 저장 시 암호화한다 (규제 요구 시)
- [ ] 외부 통신은 모두 HTTPS
- [ ] DB 백업을 암호화한다

## 의존성 보안

```bash
# 취약점 감사 (Python)
pip-audit

# 또는 uv 환경
uv pip list --outdated

# 잠금 파일 기반 재현 가능한 설치
pip install -r requirements.txt   # 또는 uv sync
```

**공급망 위생** (감사 도구가 악성 패키지를 다 잡지는 못한다):
- [ ] 잠금 파일을 커밋하고, CI는 잠금 파일 기반으로 설치한다 (임의 최신 버전 설치 금지)
- [ ] 새 의존성을 검토한다 (유지보수 상태, 다운로드 수, `setup.py`/`postinstall` 스크립트)
- [ ] 타이포스쿼팅 주의 (`numpy` vs `nunpy`, `requests` vs `request`)

## ML / 데이터 보안

Python ML/DL 연구 코드에서 특히 주의할 항목:

- [ ] **신뢰할 수 없는 역직렬화 금지** — `pickle.load`, `torch.load`(기본값), `joblib.load`는 임의 코드 실행이 가능하다. 출처 불명 체크포인트/`.pkl`을 절대 그대로 로드하지 않는다
- [ ] `torch.load`는 `weights_only=True`(PyTorch 2.x)로, 가중치만 로드한다
- [ ] 외부에서 받은 모델/데이터셋은 의존성처럼 출처와 무결성(체크섬)을 검증한다
- [ ] **데이터 유출(data leakage) 방지** — 학습 데이터에 PII·자격증명이 섞여 들어가지 않는지, 로그/아티팩트로 데이터셋이 새지 않는지 확인한다
- [ ] 모델 가중치·데이터셋 경로를 시크릿처럼 취급하고 저장소에 커밋하지 않는다
- [ ] `eval`/`exec`로 동적 설정을 실행하지 않는다 (YAML/JSON 설정 파서 사용)

## 에러 처리

```python
# 운영: 일반적인 에러, 내부 정보 노출 없음
return JSONResponse(
    status_code=500,
    content={"error": {"code": "INTERNAL_ERROR", "message": "Something went wrong"}},
)

# 운영 환경에서 절대 금지:
# content={"error": str(exc), "traceback": traceback.format_exc()}  # 내부 노출
# content={"query": exc.sql}  # DB 세부정보 노출
```

## OWASP Top 10 빠른 참조

| # | 취약점 | 예방 |
|---|---|---|
| 1 | 접근 통제 실패 | 모든 엔드포인트 인증 확인, 소유권 검증 |
| 2 | 암호화 실패 | HTTPS, 강한 해싱, 코드 내 시크릿 금지 |
| 3 | 인젝션 | 파라미터화 쿼리, 입력 검증 |
| 4 | 안전하지 않은 설계 | 위협 모델링, 스펙 기반 개발 |
| 5 | 보안 설정 오류 | 보안 헤더, 최소 권한, 의존성 감사 |
| 6 | 취약한 컴포넌트 | 의존성 감사, 최신 유지, 최소화 |
| 7 | 인증 실패 | 강한 비밀번호, 레이트 리밋, 세션 관리 |
| 8 | 데이터 무결성 실패 | 업데이트/의존성 검증, 서명된 아티팩트 |
| 9 | 로깅 실패 | 보안 이벤트 로깅, 시크릿 로깅 금지 |
| 10 | SSRF | URL 검증/allowlist, 아웃바운드 요청 제한 |

## OWASP LLM Top 10 빠른 참조

LLM 기능(챗봇, 요약기, 에이전트, RAG)이 있는 앱용. [OWASP GenAI Security Project](https://genai.owasp.org/llm-top-10/) 참조.

| ID | 위험 | 예방 |
|---|---|---|
| LLM01 | 프롬프트 인젝션 | 시스템 프롬프트를 경계로 신뢰하지 말 것 — 권한은 코드에서 강제 |
| LLM02 | 민감 정보 노출 | 시크릿/PII를 프롬프트에 넣지 않기, 출력 필터링 |
| LLM03 | 공급망 | 모델·데이터셋·플러그인을 의존성처럼 검증 |
| LLM04 | 데이터·모델 오염 | 신뢰 가능한 출처 사용, 무결성 검증, 파인튜닝·RAG 데이터 검수 |
| LLM05 | 부적절한 출력 처리 | 모델 출력을 신뢰 불가로 취급, 검증·파라미터화·인코딩 |
| LLM06 | 과도한 자율성 | 도구 권한 범위 한정, 파괴적 작업은 확인 요구 |
| LLM07 | 시스템 프롬프트 유출 | 시스템 프롬프트는 유출될 수 있다고 가정, 시크릿 넣지 않기 |
| LLM08 | 벡터·임베딩 취약점 | 테넌트별 RAG 임베딩 분리, 색인 전 문서 검증 |
| LLM09 | 잘못된 정보 | 인용으로 근거 제시, 핵심 주장 검증, 사람 개입 유지 |
| LLM10 | 무제한 소비 | 토큰·요청률·루프/재귀 깊이 상한 설정 |

---

원본 참고: addyosmani/agent-skills (`references/security-checklist.md`)
